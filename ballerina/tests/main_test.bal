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

import ballerina/test;

configurable string token = "default-token";
configurable boolean islive = false;

ConnectionConfig config = {
    auth: {token}
};

configurable string serviceURL = islive ? "https://api.openai.com/v1" : "http://localhost:9090";

final Client openai = check new Client(config, serviceURL);

configurable map<string> headers = {
    "OpenAI-Beta": "assistants=v2"
};

string assistantId = "asst_abc123";
string threadId = "thread_abc123";

@test:Config {
    groups: ["live_tests", "mock_tests", "assistants"]
}
function testPostAssistant() returns error? {
    CreateAssistantRequest request = {
        model: "gpt-4o",
        name: "Math Tutor",
        description: null,
        instructions: "You are a personal math tutor.",
        tools: [
            {
                'type: "code_interpreter"
            }
        ],
        toolResources: {
            "code_interpreter": {"file_ids": []}
        },
        metadata: {},
        topP: 1.0,
        temperature: 1.0,
        responseFormat: {"type": "text"}
    };

    AssistantObject response = check openai->/assistants.post(request, headers = headers);

    test:assertEquals(response.name, "Math Tutor", "Expected assistant name to be 'Math Tutor'");
    test:assertEquals(response.model, "gpt-4o", "Expected assistant model to be 'gpt-4o'");
    test:assertEquals(response.instructions, "You are a personal math tutor.", "Expected assistant instructions to match");
    test:assertEquals(response.tools.length(), 1, "Expected assistant to have 1 tool");
    test:assertNotEquals(response.id, "", "Expected assistant ID to be generated");
    test:assertNotEquals(response.createdAt, 0, "Expected assistant creation timestamp to be set");
    test:assertNotEquals(response.createdAt, 0, "Expected assistant creation timestamp to be set");

    assistantId = response.id;
}

@test:Config {
    dependsOn: [testPostAssistant],
    groups: ["live_tests", "mock_tests", "assistants"]
}
isolated function testGetAssistants() returns error? {
    ListAssistantsResponse response = check openai->/assistants.get(headers = headers);

    test:assertEquals(response.data.length(), 1, "Expected at least one assistant to be present");
    test:assertEquals(response.data[0].name, "Math Tutor", "Expected assistant name to be 'Math Tutor'");
}

@test:Config {
    dependsOn: [testPostAssistant],
    groups: ["live_tests", "mock_tests", "assistants"]
}
function testGetAssistantById() returns error? {
    AssistantObject response = check openai->/assistants/[assistantId].get(headers = headers);

    test:assertEquals(response.id, assistantId, "Expected assistant ID to match");
    test:assertEquals(response.name, "Math Tutor", "Expected assistant name to be 'Math Tutor'");
    test:assertEquals(response.model, "gpt-4o", "Expected assistant model to be 'gpt-4o'");
    test:assertEquals(response.instructions, "You are a personal math tutor.", "Expected assistant instructions to match");
    test:assertEquals(response.tools.length(), 1, "Expected assistant to have 1 tool");
    test:assertNotEquals(response.createdAt, 0, "Expected assistant creation timestamp to be set");
    test:assertNotEquals(response.createdAt, 0, "Expected assistant creation timestamp to be set");
}

@test:Config {
    dependsOn: [testPostAssistant],
    groups: ["live_tests", "mock_tests", "assistants"]
}
function testPostAssistantById() returns error? {
    ModifyAssistantRequest request = {
        name: "Updated Math Tutor",
        description: "Updated description",
        instructions: "Updated instructions for math tutor.",
        tools: [{"type": "file_search"}],
        toolResources: {},
        metadata: {},
        topP: 1.0,
        temperature: 1.0,
        responseFormat: {"type": "text"},
        model: "gpt-4o"
    };
    AssistantObject response = check openai->/assistants/[assistantId].post(request, headers = headers);

    test:assertEquals(response.id, assistantId, "Expected assistant ID to match");
    test:assertEquals(response.name, "Updated Math Tutor", "Expected assistant name to be 'Updated Math Tutor'");
    test:assertEquals(response.model, "gpt-4o", "Expected assistant model to be 'gpt-4o'");
    test:assertEquals(response.instructions, "Updated instructions for math tutor.", "Expected assistant instructions to match");
    test:assertEquals(response.tools.length(), 1, "Expected assistant to have 1 tool");
    test:assertNotEquals(response.createdAt, 0, "Expected assistant creation timestamp to be set");
    test:assertNotEquals(response.createdAt, 0, "Expected assistant creation timestamp to be set");
    test:assertEquals(response.description, "Updated description", "Expected assistant description to be 'Updated description'");
}

@test:Config {
    groups: ["live_tests", "mock_tests", "assistants"]
}
function testPostThread() returns error? {
    CreateThreadRequest request = {
        messages: [
            {
                role: "user",
                content: "What is the capital of France?"
            }
        ],
        metadata: {
            "assistant_id": assistantId,
            "assistant_name": "Math Tutor"
        }
    };

    ThreadObject response = check openai->/threads.post(request, headers = headers);
    test:assertNotEquals(response.id, "", "Expected thread ID to be generated");
    test:assertNotEquals(response.createdAt, 0, "Expected thread creation timestamp to be set");

    threadId = response.id;
};

@test:Config {
    dependsOn: [testPostThread],
    groups: ["live_tests", "mock_tests", "assistants"]
}
function testpostThreadAndRun() returns error? {
    CreateThreadAndRunRequest request = {
        assistantId,
        thread: {
            messages: [
                {
                    role: "user",
                    content: "What is the capital of France?"
                }
            ],
            toolResources: {
                codeInterpreter: {fileIds: []}
            }
        },
        model: "gpt-4o",
        instructions: "You are a personal math tutor.",
        tools: [{'type: "code_interpreter"}],
        toolResources: {},
        metadata: {},
        topP: 1.0,
        temperature: 1.0,
        maxPromptTokens: 256,
        maxCompletionTokens: 128,
        responseFormat: "auto",
        toolChoice: "auto",
        truncationStrategy: {lastMessages: 10, 'type: "auto"},
        parallelToolCalls: false
    };

    RunObject response = check openai->/threads/runs.post(request, headers = headers);

    test:assertNotEquals(response.id, "", "Expected run ID to be generated");
    test:assertNotEquals(response.createdAt, 0, "Expected run creation timestamp to be set");
    test:assertEquals(response.assistantId, assistantId, "Expected run to be associated with the correct assistant ID");
    test:assertEquals(response.status, "queued", "Expected run status to be 'queued'");
    test:assertEquals(response.model, "gpt-4o", "Expected run model to be 'gpt-4o'");
    test:assertEquals(response.instructions, "You are a personal math tutor.", "Expected run instructions to match");
    test:assertEquals(response.tools.length(), 0, "Expected run to have no tools");
    test:assertEquals(response.metadata, {}, "Expected run metadata to be empty");
    test:assertEquals(response.maxPromptTokens, 256, "Expected run max_prompt_tokens to be 256");
    test:assertEquals(response.maxCompletionTokens, 128, "Expected run max_completion_tokens to be 128");
    test:assertEquals(response.responseFormat, "auto", "Expected run response_format to be 'auto'");
}

@test:Config {
    dependsOn: [testPostThread],
    groups: ["live_tests", "mock_tests", "assistants"]
}
function testGetThreadById() returns error? {
    ThreadObject response = check openai->/threads/[threadId].get(headers = headers);
    test:assertEquals(response.id, threadId, "Expected thread ID to match");
    test:assertNotEquals(response.createdAt, 0, "Expected thread creation timestamp to be set");
}

@test:Config {
    groups: ["live_tests", "mock_tests", "audio"]
}
function testPostAudioSpeech() returns error? {
    CreateSpeechRequest request = {
        input: "Hello, how are you?",
        instructions: "You're a good assistant",
        responseFormat: "mp3",
        speed: 1,
        model: "tts-1",
        voice: "anna"
    };

    byte[] response = check openai->/audio/speech.post(request);

    int responseLength = response.length();
    test:assertNotEquals(responseLength, 0, msg = "Expected response length not to be empty");
}

@test:Config {
    groups: ["live_tests", "mock_tests", "chat"]
}
function testPostCompletions() returns error? {
    string model = "davinci";
    CreateCompletionRequest request = {
        model,
        prompt: "Write a short story about a cat and a mouse",
        maxTokens: 256,
        temperature: 0.5,
        topP: 0.5,
        user: "user-1234"
    };

    CreateCompletionResponse response = check openai->/completions.post(request);

    test:assertEquals(response.model, model, "Expected model to be " + model);
    test:assertEquals(response.choices.length(), 1, "Expected one choice in response");
    test:assertNotEquals(response.choices[0].text, "", "Expected non-empty response content");
    test:assertNotEquals(response.usage, "", "Expected usage to be set");
    test:assertNotEquals(response.created, 0, "Expected creation timestamp to be set");
}

@test:Config {
    groups: ["live_tests", "mock_tests", "embeddings"]
}
function testPostEmbeddings() returns error? {
    string model = "text-embedding-3-small";
    CreateEmbeddingRequest request = {
        input: "The quick brown fox jumped over the lazy dog",
        model,
        encodingFormat: "float",
        dimensions: 1,
        user: "user-1234"
    };

    CreateEmbeddingResponse response = check openai->/embeddings.post(request);

    test:assertEquals(response.model, model, "Expected model to be " + model);
    test:assertNotEquals(response.usage, "", "Expected usage to be set");
    test:assertNotEquals(response.data.length(), 0, "Expected data to be set");
}

function testDeleteAssistant() returns error? {
    DeleteAssistantResponse response = check openai->/assistants/[assistantId].delete(headers = headers);

    test:assertEquals(response.deleted, true, "Expected assistant to be deleted successfully");
    test:assertEquals(response.id, assistantId, "Expected deleted assistant ID to match");
}

function testDeleteThread() returns error? {
    DeleteThreadResponse response = check openai->/threads/[threadId].delete(headers = headers);

    test:assertEquals(response.deleted, true, "Expected thread to be deleted successfully");
    test:assertEquals(response.id, threadId, "Expected deleted thread ID to match");
}

@test:AfterSuite {}
function deleteResources() returns error? {
    check testDeleteAssistant();
    check testDeleteThread();
}
