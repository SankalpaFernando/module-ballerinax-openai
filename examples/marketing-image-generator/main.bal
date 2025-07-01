// Copyright (c) 2025, WSO2 LLC. (http://www.wso2.com).
//
// WSO2 LLC. licenses this file to you under the Apache License,
// Version 2.0 (the "License"); you may not use this file except
// in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing,
// software distributed under the License is distributed on an
// "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
// KIND, either express or implied.  See the License for the
// specific language governing permissions and limitations
// under the License.

import ballerina/io;
import ballerina/lang.runtime;
import ballerinax/openai;

configurable string token = ?;
configurable map<string> headers = {
    "OpenAI-Beta": "assistants=v2"
};

public function main() returns error? {
    // Initialize OpenAI client
    final openai:Client openaiClient = check new ({
        auth: {
            token
        }
    });

    // Create Marketing Content Assistant
    openai:CreateAssistantRequest assistantRequest = {
        model: "gpt-4o",
        name: "Marketing Content Assistant",
        description: "An assistant that generates creative prompts for marketing visuals.",
        instructions: "You are a marketing content assistant. Generate detailed and vivid prompts for creating marketing visuals based on user input. The prompts should be suitable for image generation with DALL·E.",
        tools: [],
        toolResources: {},
        metadata: {},
        topP: 1.0,
        temperature: 0.9,
        responseFormat: {"type": "text"}
    };

    openai:AssistantObject assistantResponse = check openaiClient->/assistants.post(assistantRequest, headers = headers);
    io:println("Marketing Content Assistant Created -> ID: ", assistantResponse.id, "\n");

    // Get user input for marketing visual description
    io:println("Enter a brief description for your marketing visual (e.g., a vibrant coffee shop ad): ");
    string userDescription = io:readln().trim();

    // Create a thread to generate a creative prompt
    openai:CreateThreadRequest threadRequest = {
        messages: [
            {
                role: "user",
                content: string `Create a detailed and vivid prompt for a marketing visual based on this description: ${userDescription}. The prompt should be optimized for DALL·E image generation.`
            }
        ]
    };
    openai:ThreadObject thread = check openaiClient->/threads.post(threadRequest, headers = headers);

    // Run the assistant on the thread
    openai:CreateRunRequest runRequest = {
        assistantId: assistantResponse.id,
        instructions: "Generate a detailed prompt for a marketing visual suitable for DALL·E."
    };
    openai:RunObject run = check openaiClient->/threads/[thread.id]/runs.post(runRequest, headers = headers);

    // Poll for run completion
    openai:RunObject runStatus = check openaiClient->/threads/[thread.id]/runs/[run.id](headers = headers);
    while runStatus.status != "completed" {
        runtime:sleep(1);
        runStatus = check openaiClient->/threads/[thread.id]/runs/[run.id](headers = headers);
    }

    // Retrieve the generated prompt
    openai:ListMessagesResponse messages = check openaiClient->/threads/[thread.id]/messages(headers = headers);
    openai:MessageObjectContent? artPromptContent = messages.data[0].content[0];
    string? artPrompt = artPromptContent?.text?.value;
    io:println("Generated Marketing Visual Prompt:\n", artPrompt ?: "No prompt received.", "\n");

    // Generate an image using the /images/generations endpoint
    openai:CreateImageRequest imageRequest = {
        prompt: artPrompt ?: userDescription,
        model: "dall-e-3",
        n: 1,
        size: "1024x1024",
        responseFormat: "url"
    };
    openai:ImagesResponse imageResponse = check openaiClient->/images/generations.post(imageRequest, headers = headers);
    io:println("Generated Image URL: ", imageResponse.data, "\n");

    // List all assistants
    openai:ListAssistantsResponse listResponse = check openaiClient->/assistants(headers = headers);
    io:println("Available Assistants -> ", listResponse.data.map(a => a.name).toString(), "\n");
}
