import ballerina/io;
import ballerina/test;

configurable string token = ?;
configurable boolean islive = ?;

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
function testpostAssistant() returns error? {
    CreateAssistantRequest request = {
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
    dependsOn: [testpostAssistant],
    groups: ["live_tests", "mock_tests", "assistants"]
}
isolated function testgetAssistants() returns error? {
    ListAssistantsResponse|error response = openai->/assistants.get(headers = headers);

    if response is error {
        return error("Failed to list assistants: " + response.message());
    }

    test:assertEquals(response.data.length(), 1, "Expected at least one assistant to be present");
    test:assertEquals(response.data[0].name, "Math Tutor", "Expected assistant name to be 'Math Tutor'");
}

@test:Config {
    dependsOn: [testpostAssistant],
    groups: ["live_tests", "mock_tests", "assistants"]
}
function testgetAssistantById() returns error? {
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
    dependsOn: [testpostAssistant],
    groups: ["live_tests", "mock_tests", "assistants"]
}
function testpostAssistantById() returns error? {
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
function testpostThread() returns error? {
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
        },
        toolResources: {
            "code_interpreter": {"file_ids": []}
        }
    };

    ThreadObject response = check openai->/threads.post(request, headers = headers);
    test:assertNotEquals(response.id, "", "Expected thread ID to be generated");
    test:assertNotEquals(response.createdAt, 0, "Expected thread creation timestamp to be set");
    threadId = response.id;
};

@test:Config {
    dependsOn: [testpostThread],
    groups: ["live_tests", "mock_tests", "assistants"]
}
function testpostThreadAndRun() returns error? {
    CreateThreadAndRunRequest request = {
        assistantId: assistantId,
        thread: {
            messages: [
                {
                    role: "user",
                    content: "What is the capital of France?"
                }
            ],
            toolResources: {
                "code_interpreter": {"file_ids": []}
            }
        },
        model: "gpt-4o",
        instructions: "You are a personal math tutor.",
        tools: [{"type": "code_interpreter"}],
        toolResources: {"code_interpreter": {"file_ids": []}},
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
    test:assertEquals(response.tools.length(), 1, "Expected run to have 1 tool");
    test:assertEquals(response.metadata, {}, "Expected run metadata to be empty");
    test:assertEquals(response.maxPromptTokens, 256, "Expected run max_prompt_tokens to be 256");
    test:assertEquals(response.maxCompletionTokens, 128, "Expected run max_completion_tokens to be 128");
    test:assertEquals(response.responseFormat, "auto", "Expected run response_format to be 'auto'");
}

@test:Config {
    dependsOn: [testpostThread],
    groups: ["live_tests", "mock_tests", "assistants"]
}
function testgetThreadById() returns error? {

    ThreadObject response = check openai->/threads/[threadId].get(headers = headers);
    test:assertEquals(response.id, threadId, "Expected thread ID to match");
    test:assertNotEquals(response.createdAt, 0, "Expected thread creation timestamp to be set");

}

function testdeleteAssistant() returns error? {
    DeleteAssistantResponse|error response = openai->/assistants/[assistantId].delete(headers = headers);

    if response is error {
        return error("Failed to delete assistant: " + response.message());
    }

    test:assertEquals(response.deleted, true, "Expected assistant to be deleted successfully");
    test:assertEquals(response.id, assistantId, "Expected deleted assistant ID to match");

}

function testdeleteThread() returns error? {
    DeleteThreadResponse|error response = openai->/threads/[threadId].delete(headers = headers);

    if response is error {
        return error("Failed to delete thread: " + response.message());
    }

    test:assertEquals(response.deleted, true, "Expected thread to be deleted successfully");
    test:assertEquals(response.id, threadId, "Expected deleted thread ID to match");
}

@test:AfterSuite {}
function deleteResources() returns error? {
    check testdeleteAssistant();
    check testdeleteThread();
}

@test:BeforeSuite
function setupResources() returns error? {
    if islive {
        io:println("Running live tests, ensure you have valid credentials and API access.");
    } else {
        io:println("Running mock tests, no actual API calls will be made.");
    }
}
