# Examples

The `ballerinax/openai` connector provides practical examples illustrating usage in various scenarios. Explore these examples, covering use cases like Assistant Creation and Embedding Generation.

[//]: # (TODO: Add examples)
1. [Assistant Generation](https://github.com/ballerina-platform/module-ballerinax-twitter/tree/main/examples/DM-mentions) - Build Assistants that can call models and use tools.
2. [Embedding Generation](https://github.com/ballerina-platform/module-ballerinax-twitter/tree/main/examples/DM-mentions) - 
Get a vector representation of a given input that can be easily consumed by machine learning models and algorithms.

## Prerequisites

1. Generate OpenAI credentials to authenticate the connector as described in the [Setup guide](https://central.ballerina.io/ballerinax/openai/latest#setup-guide).

2. For each example, create a `Config.toml` file the related configuration. Here's an example of how your `Config.toml` file should look:

    ```toml
    token = "<Access Token>"
    ```

## Running an example

Execute the following commands to build an example from the source:

* To build an example:

    ```bash
    bal build
    ```

* To run an example:

    ```bash
    bal run
    ```

## Building the examples with the local module

**Warning**: Due to the absence of support for reading local repositories for single Ballerina files, the Bala of the module is manually written to the central repository as a workaround. Consequently, the bash script may modify your local Ballerina repositories.

Execute the following commands to build all the examples against the changes you have made to the module locally:

* To build all the examples:

    ```bash
    ./build.sh build
    ```

* To run all the examples:

    ```bash
    ./build.sh run
    ```
