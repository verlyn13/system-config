# ProjectHealthSummary


## Properties

Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**project_id** | **string** |  | [default to undefined]
**overall** | **string** |  | [default to undefined]
**counts** | [**ProjectHealthSummaryCounts**](ProjectHealthSummaryCounts.md) |  | [default to undefined]
**observers** | [**{ [key: string]: ProjectHealthSummaryObserversValue; }**](ProjectHealthSummaryObserversValue.md) |  | [default to undefined]
**slo** | [**ProjectHealthSummarySlo**](ProjectHealthSummarySlo.md) |  | [default to undefined]

## Example

```typescript
import { ProjectHealthSummary } from './api';

const instance: ProjectHealthSummary = {
    project_id,
    overall,
    counts,
    observers,
    slo,
};
```

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)
