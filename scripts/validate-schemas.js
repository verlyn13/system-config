#!/usr/bin/env node
/**
 * Schema Validation Script
 * Part of Stage 1 Contract Freeze
 * Validates all JSON schemas compile correctly
 */

const fs = require('fs');
const path = require('path');
const Ajv2020 = require('ajv/dist/2020');
const addFormats = require('ajv-formats');

// ANSI color codes for output
const colors = {
  green: '\x1b[32m',
  red: '\x1b[31m',
  yellow: '\x1b[33m',
  reset: '\x1b[0m',
  bold: '\x1b[1m'
};

function log(message, type = 'info') {
  const prefix = {
    success: `${colors.green}✅`,
    error: `${colors.red}❌`,
    warning: `${colors.yellow}⚠️`,
    info: '📋'
  }[type] || '';
  console.log(`${prefix} ${message}${colors.reset}`);
}

async function validateSchemas() {
  log('Schema Validation - Contract v1.1.0', 'info');
  console.log('====================================\n');

  // Initialize Ajv with 2020-12 draft support
  const ajv = new Ajv2020({
    strict: false,
    allErrors: true,
    validateFormats: true
  });

  // Add format validators
  addFormats(ajv);

  const schemaDir = path.join(__dirname, '..', 'schema');

  // Check if schema directory exists
  if (!fs.existsSync(schemaDir)) {
    log(`Schema directory not found: ${schemaDir}`, 'error');
    process.exit(1);
  }

  const schemaFiles = fs.readdirSync(schemaDir)
    .filter(f => f.endsWith('.json'))
    .sort();

  if (schemaFiles.length === 0) {
    log('No schema files found', 'warning');
    return;
  }

  log(`Found ${schemaFiles.length} schema files\n`, 'info');

  const results = {
    valid: [],
    invalid: [],
    warnings: []
  };

  // First pass: Load all schemas for cross-references
  const schemas = new Map();
  for (const file of schemaFiles) {
    try {
      const filePath = path.join(schemaDir, file);
      const content = fs.readFileSync(filePath, 'utf8');
      const schema = JSON.parse(content);

      schemas.set(file, schema);

      // Add to Ajv if it has an $id
      if (schema.$id) {
        try {
          ajv.addSchema(schema, schema.$id);
        } catch (e) {
          // Schema might already be added, ignore
        }
      }
    } catch (e) {
      results.invalid.push({
        file,
        error: `Failed to parse: ${e.message}`
      });
    }
  }

  // Second pass: Validate each schema
  for (const [file, schema] of schemas) {
    try {
      // Check required fields
      const warnings = [];

      if (!schema.$schema) {
        warnings.push('Missing $schema declaration');
      }

      if (!schema.$id) {
        warnings.push('Missing $id field');
      }

      if (!schema.title) {
        warnings.push('Missing title field');
      }

      if (!schema.description) {
        warnings.push('Missing description field');
      }

      // Try to compile the schema
      const validate = ajv.compile(schema);

      // Schema compiled successfully
      results.valid.push(file);

      // Add any warnings
      if (warnings.length > 0) {
        results.warnings.push({ file, warnings });
      }

      // Show success with any warnings
      if (warnings.length > 0) {
        log(`${file} - valid (with warnings)`, 'warning');
        warnings.forEach(w => console.log(`    ${colors.yellow}⚠${colors.reset}  ${w}`));
      } else {
        log(`${file} - valid`, 'success');
      }

    } catch (e) {
      results.invalid.push({
        file,
        error: e.message
      });
      log(`${file} - invalid`, 'error');
      console.log(`    ${colors.red}→${colors.reset} ${e.message}`);
    }
  }

  // Print summary
  console.log('\n====================================');
  console.log(`${colors.bold}Summary:${colors.reset}`);
  console.log(`  Valid:   ${colors.green}${results.valid.length}${colors.reset}`);
  console.log(`  Invalid: ${colors.red}${results.invalid.length}${colors.reset}`);
  console.log(`  Warnings: ${colors.yellow}${results.warnings.length}${colors.reset}`);

  // Check contract version
  console.log('\n====================================');
  console.log(`${colors.bold}Contract Version Check:${colors.reset}`);

  const versionFile = path.join(__dirname, '..', 'contracts', 'VERSION');
  if (fs.existsSync(versionFile)) {
    const version = fs.readFileSync(versionFile, 'utf8').trim();
    log(`Contract version: ${version}`, 'success');

    if (version !== 'v1.1.0') {
      log('Warning: Version mismatch with Stage 1 target (v1.1.0)', 'warning');
    }
  } else {
    log('contracts/VERSION file not found', 'error');
  }

  // Exit with error if any schemas are invalid
  if (results.invalid.length > 0) {
    console.log(`\n${colors.red}${colors.bold}❌ Schema validation failed${colors.reset}`);
    console.log('Fix the invalid schemas before proceeding with Stage 1');
    process.exit(1);
  }

  console.log(`\n${colors.green}${colors.bold}✅ All schemas valid${colors.reset}`);

  if (results.warnings.length > 0) {
    console.log(`${colors.yellow}Consider addressing the warnings for better schema quality${colors.reset}`);
  }

  console.log('\nSchemas are ready for Stage 1 contract freeze');
}

// Run validation
validateSchemas().catch(error => {
  console.error(`\n${colors.red}${colors.bold}Fatal error:${colors.reset}`, error);
  process.exit(1);
});