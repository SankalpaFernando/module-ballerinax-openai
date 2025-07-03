## Marketing Visual Prompt Generator

This use case demonstrates how the OpenAI Assistants v2 API can be used to create an assistant that helps marketing teams generate creative and vivid prompts for visual campaigns.
The assistant interacts with the user, crafts detailed prompts optimized for DALL·E image generation, and finally creates a marketing visual.

## Prerequisites

### 1. Setup OpenAI account & obtain API token

* Sign up at [OpenAI](https://platform.openai.com/).
* Generate an **API key** from your [OpenAI dashboard](https://platform.openai.com/api-keys).

### 2. Configuration

Create a `Config.toml` file in the example's root directory and provide your OpenAI token:

```toml
token = "<Your OpenAI API Token>"
```

## Run the example

Execute the following command to run the example:

```bash
bal run
```

The program will:

- Ask you to describe the marketing visual you want to create (e.g., *a vibrant coffee shop ad*).
- Generate a detailed, vivid prompt optimized for image generation.
- Use the prompt to create an image with DALL·E.
- Print the generated prompt and image URL.
