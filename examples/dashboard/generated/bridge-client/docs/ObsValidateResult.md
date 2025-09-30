# ObsValidateResult


## Properties

Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**ok** | **boolean** |  | [default to undefined]
**telemetry** | [**ObsValidateResultTelemetry**](ObsValidateResultTelemetry.md) |  | [optional] [default to undefined]
**registry** | [**ObsValidateResultRegistry**](ObsValidateResultRegistry.md) |  | [default to undefined]
**dirs** | **Array&lt;string&gt;** |  | [default to undefined]
**projects_total** | **number** |  | [default to undefined]
**projects_with_observations** | **number** |  | [default to undefined]
**projects_without_observations** | **number** |  | [default to undefined]

## Example

```typescript
import { ObsValidateResult } from './api';

const instance: ObsValidateResult = {
    ok,
    telemetry,
    registry,
    dirs,
    projects_total,
    projects_with_observations,
    projects_without_observations,
};
```

[[Back to Model list]](../README.md#documentation-for-models) [[Back to API list]](../README.md#documentation-for-api-endpoints) [[Back to README]](../README.md)
