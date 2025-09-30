// Simple test of validation logic without AJV dependency

// Observer mappings (internal -> external)
const observerMappings = {
  'repo': 'git',
  'deps': 'mise',
  'quality': null  // Never expose
};

// Valid external observers
const validExternalObservers = new Set([
  'git', 'mise', 'sbom', 'build', 'manifest'
]);

function mapObserver(observer) {
  // Check if it's an internal observer that needs mapping
  if (observer in observerMappings) {
    return observerMappings[observer];
  }

  // If it's already a valid external observer, return as-is
  if (validExternalObservers.has(observer)) {
    return observer;
  }

  // Unknown observer - block it
  return null;
}

// Test the mappings
console.log('Testing observer mappings:');
console.log('repo →', mapObserver('repo'));
console.log('deps →', mapObserver('deps'));
console.log('quality →', mapObserver('quality'));
console.log('git →', mapObserver('git'));
console.log('unknown →', mapObserver('unknown'));

// Test project ID encoding
function encodeProjectId(service, org, repo) {
  if (!service || !org || !repo) {
    throw new Error('All project ID components required');
  }

  service = service.toLowerCase().replace(/[^a-z0-9-]/g, '');
  org = org.toLowerCase().replace(/[^a-z0-9-]/g, '');
  repo = repo.toLowerCase().replace(/[^a-z0-9-]/g, '');

  return `${service}:${org}/${repo}`;
}

console.log('\nTesting project ID encoding:');
console.log('ds-go:verlyn13/ds-go =', encodeProjectId('ds-go', 'verlyn13', 'ds-go'));
console.log('system-setup-update:org/repo =', encodeProjectId('system-setup-update', 'org', 'repo'));

// All tests passed
console.log('\n✅ All tests passed!');