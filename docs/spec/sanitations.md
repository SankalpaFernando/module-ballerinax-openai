_Author_:  Sankalpa Fernando \
_Created_: 2025-06-17 \
_Updated_: <!-- TODO: Add date --> \
_Edition_: Swan Lake

# Sanitation for OpenAPI specification

This document records the sanitation done on top of the official OpenAPI specification from Ballerina OpenAI Connector. 
The OpenAPI specification is obtained from (TODO: Add source link).
These changes are done in order to improve the overall usability, and as workarounds for some known language limitations.

[//]: # (TODO: Add sanitation details)
1. **Path Parameter Consistency**
    - **Issue** <br>
        `paths./organization/certificates/{certificate_id}`<br>
        Path parameter `certificate_id` is declared in the path but missing from operations `POST` and `DELETE`.

    - **Fix**<br/>
Add the following to each of the affected operations (`post`, `delete`):

    ```yaml
        parameters:
            - name: certificate_id
              in: path
              required: true
              schema:
                type: string
    ```
    

    - **Reason**<br/>
        All operations that use a path parameter must explicitly define it unless the parameter is moved to the shared path-level parameters object.
2. **Invalid or Non-OpenAPI Keywords in Schemas**
    - **Affected Schema**: CompoundFilter 
        - **Issue 1**<br/>
            ```yaml
            $recursiveAnchor: true
            ```

        - **Fix**<br/>
            Remove the line containing `$recursiveAnchor`.
            <br>
        - **Issue 2**<br/>
           ```yaml
            oneOf:
             - ...
             - $recursiveRef: '#/components/schemas/CompoundFilter'
            ```

        - **Fix**<br/>
            Replace `$recursiveRef` with an OpenAPI-compatible $ref or restructure the schema to avoid recursion.
    - **Reason**<br/>
            OpenAPI 3.0 does not support JSON Schema Draft 2019 keywords like `$recursiveAnchor` and `$recursiveRef`.
3. **Duplicate Items in required Arrays**
    - **Schema**: ContainerResource
    - **Issue**<br>
        `required` array has duplicate values: item at index 4 is repeated at index 8.
        ```yaml
        required:
            - ...
            - exampleField
            - ...
            - exampleField
        ```

    - **Fix**<br/>
Remove the duplicate item from the array.

    - **Reason**<br/>
`required` arrays must contain unique field names.
4. **Empty or Invalid `required` Arrays**
    - **Affected Schemas**: 
        - `CreateContainerFileBody`
        - `ImageGenTool.properties.input_image_mask.required`

        - `MCPTool.properties.allowed_tools.oneOf.1.required`

        - `RankingOptions.required`
    - **Issue**<br>
        `required` array has fewer than 1 item (empty).
        ```yaml
        required:
            - ...
            - exampleField
            - ...
            - exampleField
        ```

    - **Fix**<br/>
        - Add at least one valid field name if it’s required.
        - Or remove the required array if no fields are strictly required.
    - **Reason**<br/>
Empty `required` arrays are invalid in OpenAPI 3.0. At least one property must be listed, or the array should be omitted.
5. **Invalid Schema Properties (`optional`, `unevaluatedProperties`, `propertyNames`)**
    - **Affected Schemas & Properties**: 
        - `CreateTranscriptionResponseJson`
            - **Property**: `logprobs`
            - **Invalid Keyword**: `optional`
        - `FineTuneReinforcementRequestInput`
            - **Property**: `root`
            - **Invalid Keyword**: `unevaluatedProperties`
        - `VectorStoreFileAttributes`
            - **Property**: `root`
            - **Invalid Keyword**: `propertyNames`
    - **Fix**<br/>
    Remove all invalid keywords from affected schema definitions.
    - **Reason**<br/>
These keywords are not supported in OpenAPI 3.0. Their presence leads to schema validation failures.
6. **Invalid Keywords Inside `items` Schema**
    - **Issue** <br>
    Contains `min_items`, `max_items` within `items`, which is not allowed.
    - **Fix**<br/>
Move these constraints (minItems, maxItems) to the parent array definition
        ```yaml
        range:
        type: array
        minItems: 2
        maxItems: 5
        items:
            type: number
        ```
    - **Reason**<br/>
`items` must define the schema of array elements, not constraints.
6. **Invalid `anyOf.type` Values**
    - **Affected Schemas & Properties**
        - **InputImageContent**
            - **Properties**: `image_url`, `file_id`
        - **InputFileContent**
            - **Properties**: `file_id`
        - **FunctionTool**
            - **Properties**: `description`, `parameters`, `strict`
        - **FileSearchTool**
            - **Properties**: `filters`
        - **ApproximateLocation**
            - **Properties**: `country`, `region`, `city`, `timezone`
        - **WebSearchPreviewTool**
            - **Properties**: `user_location`
        - **ComputerCallSafetyCheckParam**
            - **Properties**: `code`, `message`
        - **ComputerCallOutputItemParam**
            - **Properties**: `id`, `acknowledged_safety_checks`, `status`
        - **FunctionCallOutputItemParam**
            - **Properties**: `id`, `status`
        - **ItemReferenceParam**
            - **Properties**: `type`
    
        Each contains a type value that is either null, empty, or not a valid primitive.


    - **Fix**<br/>
Ensure that each `anyOf` uses only allowed OpenAPI primitive types:

        ```yaml
        anyOf:
        - type: string
        - type: object
        ```
        Allowed values:
        - string
        - integer
        - number
        - boolean
        - array
        - object
    - **Reason**<br/>
OpenAPI requires all type values to be one of its predefined primitives.


## OpenAPI cli command

The following command was used to generate the Ballerina client from the OpenAPI specification. The command should be executed from the repository root directory.

```bash
# TODO: Add OpenAPI CLI command used to generate the client
```
Note: The license year is hardcoded to 2024, change if necessary.
