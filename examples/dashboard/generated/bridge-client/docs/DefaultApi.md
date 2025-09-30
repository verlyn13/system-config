# DefaultApi

All URIs are relative to *http://127.0.0.1:7171*

|Method | HTTP request | Description|
|------------- | ------------- | -------------|
|[**apiDiscoverySchemasGet**](#apidiscoveryschemasget) | **GET** /api/discovery/schemas | List loaded schemas, names, and IDs|
|[**apiDiscoveryServicesGet**](#apidiscoveryservicesget) | **GET** /api/discovery/services | Service discovery (DS/MCP registry)|
|[**apiEventsStreamGet**](#apieventsstreamget) | **GET** /api/events/stream | Server-sent events for ProjectObsCompleted and SLOBreach|
|[**apiHealthGet**](#apihealthget) | **GET** /api/health | Bridge health|
|[**apiProjectsGet**](#apiprojectsget) | **GET** /api/projects | List projects with rollups|
|[**apiProjectsIdHealthGet**](#apiprojectsidhealthget) | **GET** /api/projects/{id}/health | Project rollup health|
|[**apiProjectsIdIntegrationGet**](#apiprojectsidintegrationget) | **GET** /api/projects/{id}/integration | Project integration view (observers, health, services)|
|[**apiProjectsIdManifestGet**](#apiprojectsidmanifestget) | **GET** /api/projects/{id}/manifest | Validate and fetch project manifest|
|[**apiProjectsIdStatusGet**](#apiprojectsidstatusget) | **GET** /api/projects/{id}/status | Project observation lines (NDJSON tail via server)|
|[**apiSchemasNameGet**](#apischemasnameget) | **GET** /api/schemas/{name} | Serve schema by filename|
|[**apiTelemetryInfoGet**](#apitelemetryinfoget) | **GET** /api/telemetry-info | Contract and telemetry info|
|[**apiToolsObsMigratePost**](#apitoolsobsmigratepost) | **POST** /api/tools/obs_migrate | Migrate per-observer files into observations.ndjson|
|[**apiToolsObsValidatePost**](#apitoolsobsvalidatepost) | **POST** /api/tools/obs_validate | Validate observation coverage|
|[**apiToolsProjectObsRunPost**](#apitoolsprojectobsrunpost) | **POST** /api/tools/project_obs_run | Run observer(s)|
|[**wellKnownObsBridgeJsonGet**](#wellknownobsbridgejsonget) | **GET** /.well-known/obs-bridge.json | Well-known descriptor for bridge contracts|

# **apiDiscoverySchemasGet**
> apiDiscoverySchemasGet()


### Example

```typescript
import {
    DefaultApi,
    Configuration
} from './api';

const configuration = new Configuration();
const apiInstance = new DefaultApi(configuration);

const { status, data } = await apiInstance.apiDiscoverySchemasGet();
```

### Parameters
This endpoint does not have any parameters.


### Return type

void (empty response body)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: Not defined


### HTTP response details
| Status code | Description | Response headers |
|-------------|-------------|------------------|
|**200** | OK |  -  |

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **apiDiscoveryServicesGet**
> ServiceDiscovery1 apiDiscoveryServicesGet()


### Example

```typescript
import {
    DefaultApi,
    Configuration
} from './api';

const configuration = new Configuration();
const apiInstance = new DefaultApi(configuration);

const { status, data } = await apiInstance.apiDiscoveryServicesGet();
```

### Parameters
This endpoint does not have any parameters.


### Return type

**ServiceDiscovery1**

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json


### HTTP response details
| Status code | Description | Response headers |
|-------------|-------------|------------------|
|**200** | OK |  -  |

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **apiEventsStreamGet**
> apiEventsStreamGet()


### Example

```typescript
import {
    DefaultApi,
    Configuration
} from './api';

const configuration = new Configuration();
const apiInstance = new DefaultApi(configuration);

const { status, data } = await apiInstance.apiEventsStreamGet();
```

### Parameters
This endpoint does not have any parameters.


### Return type

void (empty response body)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: Not defined


### HTTP response details
| Status code | Description | Response headers |
|-------------|-------------|------------------|
|**200** | event-stream |  -  |

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **apiHealthGet**
> apiHealthGet()


### Example

```typescript
import {
    DefaultApi,
    Configuration
} from './api';

const configuration = new Configuration();
const apiInstance = new DefaultApi(configuration);

const { status, data } = await apiInstance.apiHealthGet();
```

### Parameters
This endpoint does not have any parameters.


### Return type

void (empty response body)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: Not defined


### HTTP response details
| Status code | Description | Response headers |
|-------------|-------------|------------------|
|**200** | OK |  -  |

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **apiProjectsGet**
> apiProjectsGet()


### Example

```typescript
import {
    DefaultApi,
    Configuration
} from './api';

const configuration = new Configuration();
const apiInstance = new DefaultApi(configuration);

const { status, data } = await apiInstance.apiProjectsGet();
```

### Parameters
This endpoint does not have any parameters.


### Return type

void (empty response body)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: Not defined


### HTTP response details
| Status code | Description | Response headers |
|-------------|-------------|------------------|
|**200** | OK |  -  |

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **apiProjectsIdHealthGet**
> ProjectHealthSummary1 apiProjectsIdHealthGet()


### Example

```typescript
import {
    DefaultApi,
    Configuration
} from './api';

const configuration = new Configuration();
const apiInstance = new DefaultApi(configuration);

let id: string; // (default to undefined)

const { status, data } = await apiInstance.apiProjectsIdHealthGet(
    id
);
```

### Parameters

|Name | Type | Description  | Notes|
|------------- | ------------- | ------------- | -------------|
| **id** | [**string**] |  | defaults to undefined|


### Return type

**ProjectHealthSummary1**

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json


### HTTP response details
| Status code | Description | Response headers |
|-------------|-------------|------------------|
|**200** | OK |  -  |

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **apiProjectsIdIntegrationGet**
> ProjectIntegration1 apiProjectsIdIntegrationGet()


### Example

```typescript
import {
    DefaultApi,
    Configuration
} from './api';

const configuration = new Configuration();
const apiInstance = new DefaultApi(configuration);

let id: string; // (default to undefined)

const { status, data } = await apiInstance.apiProjectsIdIntegrationGet(
    id
);
```

### Parameters

|Name | Type | Description  | Notes|
|------------- | ------------- | ------------- | -------------|
| **id** | [**string**] |  | defaults to undefined|


### Return type

**ProjectIntegration1**

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json


### HTTP response details
| Status code | Description | Response headers |
|-------------|-------------|------------------|
|**200** | OK |  -  |
|**404** | Not found |  -  |

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **apiProjectsIdManifestGet**
> ProjectManifestValidationResult1 apiProjectsIdManifestGet()


### Example

```typescript
import {
    DefaultApi,
    Configuration
} from './api';

const configuration = new Configuration();
const apiInstance = new DefaultApi(configuration);

let id: string; // (default to undefined)

const { status, data } = await apiInstance.apiProjectsIdManifestGet(
    id
);
```

### Parameters

|Name | Type | Description  | Notes|
|------------- | ------------- | ------------- | -------------|
| **id** | [**string**] |  | defaults to undefined|


### Return type

**ProjectManifestValidationResult1**

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json


### HTTP response details
| Status code | Description | Response headers |
|-------------|-------------|------------------|
|**200** | OK |  -  |
|**404** | Not found |  -  |

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **apiProjectsIdStatusGet**
> apiProjectsIdStatusGet()


### Example

```typescript
import {
    DefaultApi,
    Configuration
} from './api';

const configuration = new Configuration();
const apiInstance = new DefaultApi(configuration);

let id: string; // (default to undefined)
let limit: number; // (optional) (default to undefined)
let cursor: string; // (optional) (default to undefined)

const { status, data } = await apiInstance.apiProjectsIdStatusGet(
    id,
    limit,
    cursor
);
```

### Parameters

|Name | Type | Description  | Notes|
|------------- | ------------- | ------------- | -------------|
| **id** | [**string**] |  | defaults to undefined|
| **limit** | [**number**] |  | (optional) defaults to undefined|
| **cursor** | [**string**] |  | (optional) defaults to undefined|


### Return type

void (empty response body)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: Not defined


### HTTP response details
| Status code | Description | Response headers |
|-------------|-------------|------------------|
|**200** | OK |  -  |

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **apiSchemasNameGet**
> apiSchemasNameGet()


### Example

```typescript
import {
    DefaultApi,
    Configuration
} from './api';

const configuration = new Configuration();
const apiInstance = new DefaultApi(configuration);

let name: string; // (default to undefined)

const { status, data } = await apiInstance.apiSchemasNameGet(
    name
);
```

### Parameters

|Name | Type | Description  | Notes|
|------------- | ------------- | ------------- | -------------|
| **name** | [**string**] |  | defaults to undefined|


### Return type

void (empty response body)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: Not defined


### HTTP response details
| Status code | Description | Response headers |
|-------------|-------------|------------------|
|**200** | OK |  -  |

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **apiTelemetryInfoGet**
> apiTelemetryInfoGet()


### Example

```typescript
import {
    DefaultApi,
    Configuration
} from './api';

const configuration = new Configuration();
const apiInstance = new DefaultApi(configuration);

const { status, data } = await apiInstance.apiTelemetryInfoGet();
```

### Parameters
This endpoint does not have any parameters.


### Return type

void (empty response body)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: Not defined


### HTTP response details
| Status code | Description | Response headers |
|-------------|-------------|------------------|
|**200** | OK |  -  |

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **apiToolsObsMigratePost**
> ObsMigrateResult1 apiToolsObsMigratePost()


### Example

```typescript
import {
    DefaultApi,
    Configuration,
    ApiToolsObsMigratePostRequest
} from './api';

const configuration = new Configuration();
const apiInstance = new DefaultApi(configuration);

let apiToolsObsMigratePostRequest: ApiToolsObsMigratePostRequest; // (optional)

const { status, data } = await apiInstance.apiToolsObsMigratePost(
    apiToolsObsMigratePostRequest
);
```

### Parameters

|Name | Type | Description  | Notes|
|------------- | ------------- | ------------- | -------------|
| **apiToolsObsMigratePostRequest** | **ApiToolsObsMigratePostRequest**|  | |


### Return type

**ObsMigrateResult1**

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: application/json


### HTTP response details
| Status code | Description | Response headers |
|-------------|-------------|------------------|
|**200** | OK |  -  |

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **apiToolsObsValidatePost**
> ObsValidateResult1 apiToolsObsValidatePost()


### Example

```typescript
import {
    DefaultApi,
    Configuration
} from './api';

const configuration = new Configuration();
const apiInstance = new DefaultApi(configuration);

const { status, data } = await apiInstance.apiToolsObsValidatePost();
```

### Parameters
This endpoint does not have any parameters.


### Return type

**ObsValidateResult1**

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: application/json


### HTTP response details
| Status code | Description | Response headers |
|-------------|-------------|------------------|
|**200** | OK |  -  |

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **apiToolsProjectObsRunPost**
> apiToolsProjectObsRunPost(apiToolsProjectObsRunPostRequest)


### Example

```typescript
import {
    DefaultApi,
    Configuration,
    ApiToolsProjectObsRunPostRequest
} from './api';

const configuration = new Configuration();
const apiInstance = new DefaultApi(configuration);

let apiToolsProjectObsRunPostRequest: ApiToolsProjectObsRunPostRequest; //

const { status, data } = await apiInstance.apiToolsProjectObsRunPost(
    apiToolsProjectObsRunPostRequest
);
```

### Parameters

|Name | Type | Description  | Notes|
|------------- | ------------- | ------------- | -------------|
| **apiToolsProjectObsRunPostRequest** | **ApiToolsProjectObsRunPostRequest**|  | |


### Return type

void (empty response body)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: application/json
 - **Accept**: Not defined


### HTTP response details
| Status code | Description | Response headers |
|-------------|-------------|------------------|
|**200** | OK |  -  |

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

# **wellKnownObsBridgeJsonGet**
> wellKnownObsBridgeJsonGet()


### Example

```typescript
import {
    DefaultApi,
    Configuration
} from './api';

const configuration = new Configuration();
const apiInstance = new DefaultApi(configuration);

const { status, data } = await apiInstance.wellKnownObsBridgeJsonGet();
```

### Parameters
This endpoint does not have any parameters.


### Return type

void (empty response body)

### Authorization

No authorization required

### HTTP request headers

 - **Content-Type**: Not defined
 - **Accept**: Not defined


### HTTP response details
| Status code | Description | Response headers |
|-------------|-------------|------------------|
|**200** | OK |  -  |

[[Back to top]](#) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to Model list]](../README.md#documentation-for-models) [[Back to README]](../README.md)

