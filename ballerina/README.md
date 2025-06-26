## Overview

OpenAI provides a suite of powerful AI models and services for natural language processing, code generation, image understanding, and more.

The `ballerinax/openai` package offers APIs to easily connect and interact with OpenAI's RESTful API endpoints, enabling seamless integration with models such as GPT, Whisper, and DALL·E.


## Setup guide

To use the OpenAI connector, you must have access to the OpenAI API through an OpenAI account and API key.  
If you do not have an OpenAI account, you can sign up for one [here](https://platform.openai.com/signup).


### Step 1: Create/Open an OpenAI Account
- Visit the [OpenAI Platform](https://platform.openai.com/).
- Sign in with your existing credentials, or create a new OpenAI account if you don’t already have one.


### Step 2: Navigate to API Keys
- Once logged in, click on your profile icon in the top-right corner.
- In the dropdown menu, click **"Your Profile"**, then navigate to the **"API Keys"** section from the sidebar. 
- Or directly visit: [https://platform.openai.com/api-keys](https://platform.openai.com/api-keys)


### Step 3: Generate an API Key
- Click the **“+ Create new secret key”** button.
- Provide a name for the key (e.g., "Connector Key") and confirm.
- **Copy the generated API key** and store it securely.  
  ⚠️ You will not be able to view it again later.


## Quickstart
To use the `OpenAI` connector in your Ballerina application, update the `.bal` file as follows:

### Step 1: Import the module

Import the `openai` module.

```ballerina
import ballerinax/openai;
```

### Step 2: Instantiate a new connector

1. Create a `Config.toml` file and, configure the obtained credentials in the above steps as follows:

   ```bash
   token = "<Access Token>"
   ```

2. Create a `openai:ConnectionConfig` with the obtained access token and initialize the connector with it.

   ```ballerina
   configurable string token = ?;

   final openai:Client openai = check new({
      auth: {
         token
      }
   });
   ```

### Step 3: Invoke the connector operation

Now, utilize the available connector operations.

#### Create an Assistant

```ballerina
public function main() returns error? {
   openai:CreateAssistantRequest request = {
        model: "gpt-4o",
        name: "Math Tutor",
        description: null,
        instructions: "You are a personal math tutor.",
        tools: [{"type": "code_interpreter"}],
        toolResources: {"code_interpreter": {"file_ids": []}},
        metadata: {},
        topP: 1.0,
        temperature: 1.0,
        responseFormat: {"type": "text"}
   };

   //Note: This header is required because the Assistants API is currently in beta, and OpenAI requires explicit opt-in.
   configurable map<string> headers = {
    "OpenAI-Beta": "assistants=v2"
   };

   openai:AssistantObject response = check openai->/assistants.post(request, headers = headers);

}
```

### Step 4: Run the Ballerina application

```bash
bal run
```


## Examples

The `Ballerina OpenAI Connector` connector provides practical examples illustrating usage in various scenarios. Explore these [examples](https://github.com/module-ballerinax-openai/tree/main/examples/), covering the following use cases:

