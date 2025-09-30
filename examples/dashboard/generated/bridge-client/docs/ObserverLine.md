# ObserverLine


## Properties

Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**apiVersion** | **any** |  | [default to undefined]
**run_id** | **string** |  | [default to undefined]
**timestamp** | **string** |  | [default to undefined]
**project_id** | **string** |  | [default to undefined]
**observer** | **string** |  | [default to undefined]
**summary** | **string** |  | [default to undefined]
**metrics** | [**{ [key: string]: ObserverLineMetricsValue; }**](ObserverLineMetricsValue.md) |  | [default to undefined]
**status** | **string** |  | [default to undefined]
**links** | [**ObserverLineLinks**](ObserverLineLinks.md) |  | [optional] [default to undefined]
**audit_id** | **string** |  | [optional] [default to undefined]
**trace_id** | **string** |  | [optional] [default to undefined]
**span_id** | **string** |  | [optional] [default to undefined]

## Example

```typescript
import { ObserverLine } from './api';

const instance: ObserverLine = {
    apiVersion,
    run_id,
    timestamp,
    project_id,
    observer,
    summary,
    metrics,
    status,
    links,
    audit_id,
    trace_id,
    span_id,
};
```

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)
