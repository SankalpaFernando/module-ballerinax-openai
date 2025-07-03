## Personal Finance Assistant

This use case demonstrates how the OpenAI Assistants v2 API can be utilized to create an interactive personal finance assistant.
The assistant helps users manage budgets, calculate savings, and provide personalized financial advice by processing user input dynamically.

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

- Ask for your monthly income and expenses.
- Send them to the OpenAI assistant.
- Return a detailed budget analysis and personalized advice.
