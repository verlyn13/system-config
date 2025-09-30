# ObsValidateResult1


## Properties

Name | Type | Description | Notes
------------ | ------------- | ------------- | -------------
**ok** | **boolean** |  | [default to undefined]
**telemetry** | [**ObsValidateResult1Telemetry**](ObsValidateResult1Telemetry.md) |  | [optional] [default to undefined]
**registry** | [**ObsValidateResult1Registry**](ObsValidateResult1Registry.md) |  | [default to undefined]
**dirs** | **Array&lt;string&gt;** |  | [default to undefined]
**projects_total** | **number** |  | [default to undefined]
**projects_with_observations** | **number** |  | [default to undefined]
**projects_without_observations** | **number** |  | [default to undefined]

## Example

```typescript
import { ObsValidateResult1 } from './api';

const instance: ObsValidateResult1 = {
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
