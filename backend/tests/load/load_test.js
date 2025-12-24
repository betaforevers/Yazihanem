import http from 'k6/http';
import { check, sleep, group } from 'k6';
import { Rate, Trend } from 'k6/metrics';
import { randomString } from 'https://jslib.k6.io/k6-utils/1.2.0/index.js';

// Custom metrics
const errorRate = new Rate('errors');
const contentListDuration = new Trend('content_list_duration');
const contentCreateDuration = new Trend('content_create_duration');

// Test configuration
export const options = {
  stages: [
    { duration: '1m', target: 50 },    // Ramp-up to 50 users
    { duration: '3m', target: 100 },   // Ramp-up to 100 users
    { duration: '2m', target: 100 },   // Stay at 100 users
    { duration: '1m', target: 200 },   // Spike to 200 users
    { duration: '2m', target: 200 },   // Stay at spike
    { duration: '1m', target: 0 },     // Ramp-down
  ],
  thresholds: {
    'http_req_duration': ['p(95)<200', 'p(99)<500'],  // 95% < 200ms, 99% < 500ms
    'http_req_failed': ['rate<0.01'],                 // <1% HTTP errors
    'errors': ['rate<0.05'],                          // <5% business logic errors
    'content_list_duration': ['p(95)<150'],           // Content list < 150ms at p95
    'content_create_duration': ['p(95)<300'],         // Content create < 300ms at p95
  },
};

const BASE_URL = __ENV.BASE_URL || 'http://localhost:3000';

// Setup: Register tenant and get auth token
export function setup() {
  console.log(`Load test starting against: ${BASE_URL}`);

  // Register a test tenant
  const tenantRes = http.post(`${BASE_URL}/api/v1/register`, JSON.stringify({
    tenant_name: `LoadTest_${Date.now()}`,
    domain: `loadtest-${Date.now()}.example.com`,
    owner_email: `admin-${Date.now()}@loadtest.com`,
    owner_password: 'LoadTestPassword123!',
    owner_first_name: 'Load',
    owner_last_name: 'Test'
  }), {
    headers: { 'Content-Type': 'application/json' },
  });

  if (!check(tenantRes, { 'tenant registration successful': (r) => r.status === 201 })) {
    console.error('Failed to register tenant:', tenantRes.body);
    return { token: null };
  }

  const tenantData = JSON.parse(tenantRes.body);
  console.log(`Tenant created: ${tenantData.tenant.name}`);

  // Login to get token
  sleep(1); // Brief pause

  const loginRes = http.post(`${BASE_URL}/api/v1/auth/login`, JSON.stringify({
    email: `admin-${Date.now()}@loadtest.com`,
    password: 'LoadTestPassword123!'
  }), {
    headers: {
      'Content-Type': 'application/json',
      'Host': tenantData.tenant.domain || 'localhost'
    },
  });

  if (!check(loginRes, { 'login successful': (r) => r.status === 200 })) {
    console.error('Failed to login:', loginRes.body);
    return { token: null, domain: null };
  }

  const loginData = JSON.parse(loginRes.body);
  console.log('Login successful, token acquired');

  return {
    token: loginData.access_token,
    domain: tenantData.tenant.domain || 'localhost'
  };
}

// Main test scenario
export default function(data) {
  if (!data.token) {
    console.error('No auth token available, skipping test');
    return;
  }

  const headers = {
    'Authorization': `Bearer ${data.token}`,
    'Content-Type': 'application/json',
    'Host': data.domain
  };

  // Group 1: Content Listing (Most Common Operation)
  group('Content List', () => {
    const startTime = new Date().getTime();
    const res = http.get(`${BASE_URL}/api/v1/content?page=1&page_size=20`, { headers });
    const duration = new Date().getTime() - startTime;

    contentListDuration.add(duration);

    const success = check(res, {
      'content list status 200': (r) => r.status === 200,
      'content list has data': (r) => {
        try {
          const body = JSON.parse(r.body);
          return body.contents !== undefined;
        } catch (e) {
          return false;
        }
      },
      'content list response < 200ms': (r) => r.timings.duration < 200,
    });

    if (!success) {
      errorRate.add(1);
    }
  });

  sleep(1);

  // Group 2: Content Creation
  group('Content Create', () => {
    const contentData = {
      title: `Load Test Content ${randomString(10)}`,
      slug: `load-test-${randomString(10)}-${Date.now()}`,
      body: `This is a load test content created at ${new Date().toISOString()}. ${randomString(100)}`,
      status: 'draft'
    };

    const startTime = new Date().getTime();
    const res = http.post(`${BASE_URL}/api/v1/content`, JSON.stringify(contentData), { headers });
    const duration = new Date().getTime() - startTime;

    contentCreateDuration.add(duration);

    const success = check(res, {
      'content create status 201': (r) => r.status === 201,
      'content create has id': (r) => {
        try {
          const body = JSON.parse(r.body);
          return body.content && body.content.id;
        } catch (e) {
          return false;
        }
      },
      'content create response < 500ms': (r) => r.timings.duration < 500,
    });

    if (!success) {
      errorRate.add(1);
    }
  });

  sleep(2);

  // Group 3: User Profile (Auth Validation)
  group('User Profile', () => {
    const res = http.get(`${BASE_URL}/api/v1/auth/me`, { headers });

    const success = check(res, {
      'profile status 200': (r) => r.status === 200,
      'profile has email': (r) => {
        try {
          const body = JSON.parse(r.body);
          return body.user && body.user.email;
        } catch (e) {
          return false;
        }
      },
    });

    if (!success) {
      errorRate.add(1);
    }
  });

  sleep(1);

  // Group 4: Content Search/Filter
  group('Content Filter', () => {
    const res = http.get(`${BASE_URL}/api/v1/content?status=draft&page=1`, { headers });

    const success = check(res, {
      'filter status 200': (r) => r.status === 200,
    });

    if (!success) {
      errorRate.add(1);
    }
  });

  sleep(3);
}

// Teardown: Cleanup if needed
export function teardown(data) {
  if (data.token) {
    console.log('Load test completed successfully');
  } else {
    console.log('Load test completed with setup errors');
  }
}

// Handle summary to print results
export function handleSummary(data) {
  return {
    'stdout': textSummary(data, { indent: ' ', enableColors: true }),
  };
}

function textSummary(data, options) {
  const indent = options.indent || '';
  const colors = options.enableColors || false;

  let summary = '\n' + indent + '======= LOAD TEST SUMMARY =======\n';
  summary += indent + `Total Requests: ${data.metrics.http_reqs.values.count}\n`;
  summary += indent + `Failed Requests: ${data.metrics.http_req_failed.values.passes || 0}\n`;
  summary += indent + `Request Duration (p95): ${data.metrics.http_req_duration.values['p(95)']}ms\n`;
  summary += indent + `Request Duration (p99): ${data.metrics.http_req_duration.values['p(99)']}ms\n`;
  summary += indent + `Error Rate: ${(data.metrics.errors.values.rate * 100).toFixed(2)}%\n`;
  summary += indent + '================================\n';

  return summary;
}
