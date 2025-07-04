# Examples

The `ballerinax/openai` connector provides practical examples illustrating usage in various scenarios. Explore these examples, covering use cases like Assistant Creation and Embedding Generation.

1. [**Financial Assistant**](https://github.com/ballerina-platform/module-ballerinax-openai/tree/main/examples/financial-assistant) - Build a Personal Finance Assistant that helps users manage their budget, track expenses, and get financial advice.
2. [**Marketing Image Generator**](https://github.com/ballerina-platform/module-ballerinax-openai/tree/main/examples/marketing-image-generator) - Creates an assistant that takes a user’s description from the console, makes a DALL·E image with it.

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
