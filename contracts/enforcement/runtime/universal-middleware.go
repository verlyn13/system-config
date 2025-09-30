package contracts

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"regexp"
	"strings"
	"sync"
	"time"
)

// EnforcementMode defines how strictly contracts are enforced
type EnforcementMode string

const (
	ModeEnforce  EnforcementMode = "enforce"  // Block violations
	ModeMonitor  EnforcementMode = "monitor"  // Log violations only
	ModeDisabled EnforcementMode = "disabled" // No enforcement
)

// UniversalContractEnforcer provides runtime contract enforcement for Go services
type UniversalContractEnforcer struct {
	mode               EnforcementMode
	serviceName        string
	logViolations      bool
	blockOnViolation   bool
	metricsEnabled     bool
	webhookURL         string
	observerMappings   map[string]string
	validObservers     map[string]bool
	sloThresholds      map[string]SLOThreshold
	metrics            *Metrics
	mu                 sync.RWMutex
	violationCallbacks []func(violation Violation)
}

// SLOThreshold defines a service level objective threshold
type SLOThreshold struct {
	Threshold float64
	Type      string // "max" or "min"
}

// Metrics tracks contract enforcement metrics
type Metrics struct {
	TotalRequests     int64
	Violations        int64
	Blocked           int64
	ObserverMappings  int64
	SLOBreaches       int64
	LastViolation     *Violation
	ViolationsByType  map[string]int64
	mu                sync.RWMutex
}

// Violation represents a contract violation
type Violation struct {
	Type      string    `json:"type"`
	Errors    []string  `json:"errors"`
	Service   string    `json:"service"`
	Timestamp time.Time `json:"timestamp"`
	Context   string    `json:"context,omitempty"`
}

// NewUniversalContractEnforcer creates a new contract enforcer
func NewUniversalContractEnforcer(options ...Option) *UniversalContractEnforcer {
	enforcer := &UniversalContractEnforcer{
		mode:             ModeEnforce,
		serviceName:      detectServiceName(),
		logViolations:    true,
		blockOnViolation: true,
		metricsEnabled:   true,
		observerMappings: map[string]string{
			"repo":    "git",
			"deps":    "mise",
			"quality": "", // Blocked
		},
		validObservers: map[string]bool{
			"git":      true,
			"mise":     true,
			"sbom":     true,
			"build":    true,
			"manifest": true,
		},
		metrics: &Metrics{
			ViolationsByType: make(map[string]int64),
		},
		violationCallbacks: []func(Violation){},
	}

	// Apply options
	for _, opt := range options {
		opt(enforcer)
	}

	// Set service-specific SLO thresholds
	enforcer.sloThresholds = getServiceThresholds(enforcer.serviceName)

	// Start metrics reporting
	if enforcer.metricsEnabled {
		go enforcer.startMetricsReporting()
	}

	return enforcer
}

// Option is a configuration option for the enforcer
type Option func(*UniversalContractEnforcer)

// WithMode sets the enforcement mode
func WithMode(mode EnforcementMode) Option {
	return func(e *UniversalContractEnforcer) {
		e.mode = mode
	}
}

// WithServiceName sets the service name
func WithServiceName(name string) Option {
	return func(e *UniversalContractEnforcer) {
		e.serviceName = name
	}
}

// WithWebhook sets the webhook URL for violations
func WithWebhook(url string) Option {
	return func(e *UniversalContractEnforcer) {
		e.webhookURL = url
	}
}

// OnViolation adds a callback for violations
func (e *UniversalContractEnforcer) OnViolation(callback func(Violation)) {
	e.violationCallbacks = append(e.violationCallbacks, callback)
}

// Middleware returns an HTTP middleware that enforces contracts
func (e *UniversalContractEnforcer) Middleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if e.mode == ModeDisabled {
			next.ServeHTTP(w, r)
			return
		}

		e.metrics.mu.Lock()
		e.metrics.TotalRequests++
		e.metrics.mu.Unlock()

		startTime := time.Now()

		// Wrap response writer to intercept responses
		wrapped := &responseWriter{
			ResponseWriter: w,
			enforcer:       e,
			statusCode:     200,
		}

		// Check request body for observations
		if r.Method == http.MethodPost || r.Method == http.MethodPut || r.Method == http.MethodPatch {
			body, err := io.ReadAll(r.Body)
			if err == nil {
				r.Body = io.NopCloser(bytes.NewReader(body))

				var data map[string]interface{}
				if json.Unmarshal(body, &data) == nil {
					if e.looksLikeObservation(data) {
						if violations := e.validateObservation(data); len(violations) > 0 {
							e.recordViolation("request", violations, r.URL.Path)

							if e.shouldBlock() {
								http.Error(w, fmt.Sprintf("Contract violation: %v", violations), http.StatusBadRequest)
								return
							}
						}
					}
				}
			}
		}

		// Handle SSE streams
		if r.Header.Get("Accept") == "text/event-stream" {
			wrapped = &sseResponseWriter{
				responseWriter: wrapped,
				enforcer:       e,
			}
		}

		next.ServeHTTP(wrapped, r)

		// Check SLO
		duration := time.Since(startTime)
		e.checkResponseSLO(duration, wrapped.statusCode)
	})
}

// responseWriter wraps http.ResponseWriter to intercept responses
type responseWriter struct {
	http.ResponseWriter
	enforcer   *UniversalContractEnforcer
	statusCode int
	written    bool
}

func (w *responseWriter) WriteHeader(code int) {
	w.statusCode = code
	w.ResponseWriter.WriteHeader(code)
}

func (w *responseWriter) Write(data []byte) (int, error) {
	if !w.written {
		w.written = true
		// Validate response body
		var body map[string]interface{}
		if json.Unmarshal(data, &body) == nil {
			if w.enforcer.looksLikeObservation(body) {
				if violations := w.enforcer.validateObservation(body); len(violations) > 0 {
					w.enforcer.recordViolation("response", violations, "")

					if w.enforcer.shouldBlock() {
						// Replace response with error
						errResp, _ := json.Marshal(map[string]interface{}{
							"error":      "Contract violation",
							"violations": violations,
						})
						w.ResponseWriter.WriteHeader(http.StatusBadRequest)
						return w.ResponseWriter.Write(errResp)
					}
				}
			}
		}
	}

	return w.ResponseWriter.Write(data)
}

// sseResponseWriter handles Server-Sent Events
type sseResponseWriter struct {
	*responseWriter
	enforcer *UniversalContractEnforcer
}

func (w *sseResponseWriter) Write(data []byte) (int, error) {
	lines := strings.Split(string(data), "\n")

	for i, line := range lines {
		if strings.HasPrefix(line, "data: ") {
			jsonStr := strings.TrimPrefix(line, "data: ")
			var event map[string]interface{}
			if json.Unmarshal([]byte(jsonStr), &event) == nil {
				if w.enforcer.looksLikeObservation(event) {
					if violations := w.enforcer.validateObservation(event); len(violations) > 0 {
						w.enforcer.recordViolation("sse", violations, "")

						if w.enforcer.shouldBlock() {
							// Replace with error event
							errEvent, _ := json.Marshal(map[string]interface{}{
								"error":      "Contract violation",
								"violations": violations,
							})
							lines[i] = fmt.Sprintf("data: %s", errEvent)
						}
					} else {
						// Update with mapped observer if changed
						if mapped, changed := w.enforcer.mapObserverInPlace(event); changed {
							mappedJSON, _ := json.Marshal(mapped)
							lines[i] = fmt.Sprintf("data: %s", mappedJSON)
						}
					}
				}
			}
		}
	}

	modifiedData := []byte(strings.Join(lines, "\n"))
	return w.ResponseWriter.Write(modifiedData)
}

// validateObservation validates an observation against contracts
func (e *UniversalContractEnforcer) validateObservation(obs map[string]interface{}) []string {
	var violations []string

	// Map observer name
	if observer, ok := obs["observer"].(string); ok {
		mapped := e.mapObserver(observer)
		if mapped == "" {
			violations = append(violations, fmt.Sprintf("Observer '%s' is blocked at boundary", observer))
			return violations
		}
		if mapped != observer {
			obs["observer"] = mapped
			e.metrics.mu.Lock()
			e.metrics.ObserverMappings++
			e.metrics.mu.Unlock()
		}
	}

	// Validate apiVersion
	if apiVersion, ok := obs["apiVersion"].(string); ok {
		if apiVersion != "obs.v1" {
			violations = append(violations, fmt.Sprintf("Invalid apiVersion: %s (must be 'obs.v1')", apiVersion))
		}
	} else if e.looksLikeObservation(obs) {
		violations = append(violations, "Missing required field: apiVersion")
	}

	// Validate project_id format
	if projectID, ok := obs["project_id"].(string); ok {
		if !e.validateProjectID(projectID) {
			violations = append(violations, fmt.Sprintf("Invalid project_id format: %s", projectID))
		}
	}

	// Check required fields
	requiredFields := []string{"run_id", "timestamp", "observer", "summary", "metrics", "status"}
	for _, field := range requiredFields {
		if _, ok := obs[field]; !ok {
			violations = append(violations, fmt.Sprintf("Missing required field: %s", field))
		}
	}

	return violations
}

// mapObserver maps internal to external observer names
func (e *UniversalContractEnforcer) mapObserver(observer string) string {
	if mapped, ok := e.observerMappings[observer]; ok {
		return mapped
	}
	if e.validObservers[observer] {
		return observer
	}
	return "" // Block unknown
}

// mapObserverInPlace maps observer in-place and returns if changed
func (e *UniversalContractEnforcer) mapObserverInPlace(obs map[string]interface{}) (map[string]interface{}, bool) {
	if observer, ok := obs["observer"].(string); ok {
		mapped := e.mapObserver(observer)
		if mapped != "" && mapped != observer {
			obs["observer"] = mapped
			return obs, true
		}
	}
	return obs, false
}

// validateProjectID validates project ID format
func (e *UniversalContractEnforcer) validateProjectID(projectID string) bool {
	// Format: service:org/repo (all lowercase)
	matched, _ := regexp.MatchString(`^[a-z-]+:[a-z0-9-]+/[a-z0-9-]+$`, projectID)
	return matched
}

// looksLikeObservation checks if object appears to be an observation
func (e *UniversalContractEnforcer) looksLikeObservation(obj map[string]interface{}) bool {
	if apiVersion, ok := obj["apiVersion"].(string); ok && apiVersion == "obs.v1" {
		return true
	}

	observationFields := []string{"observer", "run_id", "project_id", "metrics"}
	matchCount := 0
	for _, field := range observationFields {
		if _, ok := obj[field]; ok {
			matchCount++
		}
	}
	return matchCount >= 2
}

// shouldBlock returns whether violations should block requests
func (e *UniversalContractEnforcer) shouldBlock() bool {
	return e.mode == ModeEnforce && e.blockOnViolation
}

// recordViolation records a contract violation
func (e *UniversalContractEnforcer) recordViolation(violationType string, errors []string, context string) {
	e.metrics.mu.Lock()
	e.metrics.Violations++
	e.metrics.ViolationsByType[violationType]++
	if e.shouldBlock() {
		e.metrics.Blocked++
	}
	e.metrics.mu.Unlock()

	violation := Violation{
		Type:      violationType,
		Errors:    errors,
		Service:   e.serviceName,
		Timestamp: time.Now(),
		Context:   context,
	}

	e.metrics.mu.Lock()
	e.metrics.LastViolation = &violation
	e.metrics.mu.Unlock()

	if e.logViolations {
		log.Printf("[CONTRACT VIOLATION] %s: %v", violationType, errors)
	}

	// Call callbacks
	for _, callback := range e.violationCallbacks {
		go callback(violation)
	}

	// Send webhook
	if e.webhookURL != "" {
		go e.sendWebhook(violation)
	}
}

// checkResponseSLO checks response against SLO thresholds
func (e *UniversalContractEnforcer) checkResponseSLO(duration time.Duration, statusCode int) {
	durationMs := float64(duration.Milliseconds())

	// Check response time threshold
	if threshold, ok := e.sloThresholds["response_time_p95"]; ok {
		if threshold.Type == "max" && durationMs > threshold.Threshold {
			e.metrics.mu.Lock()
			e.metrics.SLOBreaches++
			e.metrics.mu.Unlock()

			if e.logViolations {
				log.Printf("[SLO BREACH] response_time_p95: %vms > %vms", durationMs, threshold.Threshold)
			}
		}
	}

	// Check error status
	if statusCode >= 500 {
		// Would need time window tracking for accurate error rate
		if e.logViolations {
			log.Printf("[ERROR] HTTP %d response", statusCode)
		}
	}
}

// sendWebhook sends violation to webhook
func (e *UniversalContractEnforcer) sendWebhook(violation Violation) {
	payload, _ := json.Marshal(map[string]interface{}{
		"event":     "contract_violation",
		"violation": violation,
	})

	resp, err := http.Post(e.webhookURL, "application/json", bytes.NewReader(payload))
	if err != nil {
		log.Printf("Webhook error: %v", err)
		return
	}
	defer resp.Body.Close()

	if resp.StatusCode >= 400 {
		log.Printf("Webhook failed: HTTP %d", resp.StatusCode)
	}
}

// startMetricsReporting periodically reports metrics
func (e *UniversalContractEnforcer) startMetricsReporting() {
	ticker := time.NewTicker(60 * time.Second)
	defer ticker.Stop()

	for range ticker.C {
		report := e.GetMetricsReport()
		if e.logViolations {
			reportJSON, _ := json.MarshalIndent(report, "", "  ")
			log.Printf("[CONTRACT METRICS]\n%s", reportJSON)
		}
	}
}

// GetMetricsReport returns current metrics
func (e *UniversalContractEnforcer) GetMetricsReport() map[string]interface{} {
	e.metrics.mu.RLock()
	defer e.metrics.mu.RUnlock()

	violationRate := float64(0)
	if e.metrics.TotalRequests > 0 {
		violationRate = float64(e.metrics.Violations) / float64(e.metrics.TotalRequests)
	}

	return map[string]interface{}{
		"service":   e.serviceName,
		"timestamp": time.Now().Format(time.RFC3339),
		"mode":      string(e.mode),
		"metrics": map[string]interface{}{
			"totalRequests":     e.metrics.TotalRequests,
			"violations":        e.metrics.Violations,
			"blocked":           e.metrics.Blocked,
			"observerMappings":  e.metrics.ObserverMappings,
			"sloBreaches":       e.metrics.SLOBreaches,
			"violationRate":     fmt.Sprintf("%.4f", violationRate),
			"violationsByType":  e.metrics.ViolationsByType,
			"lastViolation":     e.metrics.LastViolation,
		},
	}
}

// Helper functions

func detectServiceName() string {
	// Try to detect from environment
	if name := os.Getenv("SERVICE_NAME"); name != "" {
		return name
	}

	// Try to detect from executable name
	if len(os.Args) > 0 {
		return strings.TrimSuffix(os.Args[0], ".exe")
	}

	return "unknown-service"
}

func getServiceThresholds(serviceName string) map[string]SLOThreshold {
	thresholds := map[string]map[string]SLOThreshold{
		"ds-go": {
			"response_time_p95": {Threshold: 200, Type: "max"},
			"error_rate":        {Threshold: 0.05, Type: "max"},
			"availability":      {Threshold: 99.9, Type: "min"},
		},
		"devops-mcp": {
			"response_time_p95": {Threshold: 300, Type: "max"},
			"error_rate":        {Threshold: 0.01, Type: "max"},
			"availability":      {Threshold: 99.95, Type: "min"},
		},
		"system-dashboard": {
			"response_time_p95": {Threshold: 750, Type: "max"},
			"error_rate":        {Threshold: 0.2, Type: "max"},
			"availability":      {Threshold: 99.5, Type: "min"},
		},
	}

	if serviceThresholds, ok := thresholds[serviceName]; ok {
		return serviceThresholds
	}

	// Default thresholds
	return map[string]SLOThreshold{
		"response_time_p95": {Threshold: 500, Type: "max"},
		"error_rate":        {Threshold: 0.1, Type: "max"},
		"availability":      {Threshold: 99.0, Type: "min"},
	}
}