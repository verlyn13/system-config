# ProjectIntegration


## Properties

Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**contractVersion** | **string** |  | [default to undefined]
**schemaVersion** | **any** |  | [default to undefined]
**project** | [**ProjectIntegrationProject**](ProjectIntegrationProject.md) |  | [default to undefined]
**observers** | [**{ [key: string]: ProjectIntegrationObserversValue; }**](ProjectIntegrationObserversValue.md) |  | [default to undefined]
**health** | [**ProjectHealthSummary3**](ProjectHealthSummary3.md) |  | [default to undefined]
**services** | [**ProjectIntegrationServices**](ProjectIntegrationServices.md) |  | [default to undefined]
**summary** | [**ProjectIntegrationSummary**](ProjectIntegrationSummary.md) |  | [optional] [default to undefined]
**timestamp** | **string** |  | [default to undefined]
**checkedAt** | **number** |  | [default to undefined]

## Example

```typescript
import { ProjectIntegration } from './api';

const instance: ProjectIntegration = {
    contractVersion,
    schemaVersion,
    project,
    observers,
    health,
    services,
    summary,
    timestamp,
    checkedAt,
};
```

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)
