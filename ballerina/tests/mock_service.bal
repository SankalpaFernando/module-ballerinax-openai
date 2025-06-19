import ballerina/http;
import ballerina/log;
import ballerina/time;

listener http:Listener httpListener = new (9090);

map<json> assistants = {};
map<json> threads = {};
map<json> runs = {};
isolated function getCurrentTimestamp() returns int {
    time:Utc utc = time:utcNow();
    return utc[0];
}

http:Service mockService = service object {

    // GET /assistants - List all assistants
    resource function get assistants(http:Caller caller, http:Request req) returns error? {

        json[] assistantList = [];
        lock {
            foreach var assistant in assistants {
                assistantList.push(assistant);
            }
        }

        json responseData = {
            "object": "list",
            "data": assistantList,
            "first_id": assistantList.length() > 0 ? check assistantList[0].id : null,
            "last_id": assistantList.length() > 0 ? check assistantList[assistantList.length() - 1].id : null,
            "has_more": false
        };

        check caller->respond(responseData);
    }

    // POST /assistants - Create a new assistant
    resource function post assistants(http:Caller caller, http:Request req) returns error? {
        // Verify OpenAI-Beta header
        

        json|error requestBody = req.getJsonPayload();
        if requestBody is error {
            http:Response errorResponse = new;
            errorResponse.statusCode = 400;
            errorResponse.setJsonPayload({"error": "Invalid JSON payload"});
            check caller->respond(errorResponse);
            return;
        }

        string assistantId = "asst_" + time:utcNow()[0].toString();
        json responseData = {
            "id": assistantId,
            "object": "assistant",
            "created_at": getCurrentTimestamp(),
            "name": check requestBody.name ?: "Math Tutor",
            "description": check requestBody.description ?: null,
            "model": check requestBody.model ?: "gpt-4o",
            "instructions": check requestBody.instructions ?: "You are a personal math tutor.",
            "tools": check requestBody.tools ?: [{"type": "code_interpreter"}],
            "tool_resources": check requestBody.tool_resources ?: {"code_interpreter": {"file_ids": []}},
            "metadata": check requestBody.metadata ?: {},
            "top_p": check requestBody.top_p ?: 1.0,
            "temperature": check requestBody.temperature ?: 1.0,
            "response_format": check requestBody.response_format ?: {"type": "text"}
        };

        lock {
            assistants[assistantId] = responseData;
        }

        check caller->respond(responseData);
    }
    resource function get assistants/[string assistantId](http:Caller caller, http:Request req) returns error? {
        // Verify OpenAI-Beta header
       
        json|error assistant;
        lock {
            assistant = assistants[assistantId];
        }

        if assistant is error || assistant is () {
            http:Response errorResponse = new;
            errorResponse.statusCode = 404;
            errorResponse.setJsonPayload({"error": "Assistant not found"});
            check caller->respond(errorResponse);
            return;
        }

        check caller->respond(assistant);
    }
    resource function post assistants/[string assistantId](http:Caller caller, http:Request req) returns error? {        

        json|error requestBody = req.getJsonPayload();
        if requestBody is error {
            http:Response errorResponse = new;
            errorResponse.statusCode = 400;
            errorResponse.setJsonPayload({"error": "Invalid JSON payload"});
            check caller->respond(errorResponse);
            return;
        }

        json|error existingAssistant;
        lock {
            existingAssistant = assistants[assistantId];
        }

        if existingAssistant is error || existingAssistant is () {
            http:Response errorResponse = new;
            errorResponse.statusCode = 404;
            errorResponse.setJsonPayload({"error": "Assistant not found"});
            check caller->respond(errorResponse);
            return;
        }

        json responseData = {
            "id": assistantId,
            "object": "assistant",
            "created_at": check existingAssistant.created_at,
            "name": check requestBody.name ?: check existingAssistant.name,
            "description": check requestBody.description ?: check existingAssistant.description,
            "model": check requestBody.model ?: check existingAssistant.model,
            "instructions": check requestBody.instructions ?: check existingAssistant.instructions,
            "tools": check requestBody.tools ?: check existingAssistant.tools,
            "tool_resources": check requestBody.tool_resources ?: check existingAssistant.tool_resources,
            "metadata": check requestBody.metadata ?: check existingAssistant.metadata,
            "top_p": check requestBody.top_p ?: check existingAssistant.top_p,
            "temperature": check requestBody.temperature ?: check existingAssistant.temperature,
            "response_format": check requestBody.response_format ?: check existingAssistant.response_format
        };

        lock {
            assistants[assistantId] = responseData;
        }

        check caller->respond(responseData);
    }

    // // DELETE /assistants/[assistantId] - Delete an assistant
    resource function delete assistants/[string assistantId](http:Caller caller, http:Request req) returns error? {
        string|http:HeaderNotFoundError betaHeader = req.getHeader("OpenAI-Beta");
        if betaHeader is http:HeaderNotFoundError || betaHeader != "assistants=v2" {
            http:Response errorResponse = new;
            errorResponse.statusCode = 400;
            errorResponse.setJsonPayload({"error": "Missing or invalid OpenAI-Beta header"});
            check caller->respond(errorResponse);
            return;
        }

        json|error assistant;

        lock{
           assistant = assistants[assistantId]; 
        }
        

        if assistant is error || assistant is () {
            http:Response errorResponse = new;
            errorResponse.statusCode = 404;
            errorResponse.setJsonPayload({"error": "Assistant not found"});
            check caller->respond(errorResponse);
            return;
        }

        lock {
            _ = assistants.remove(assistantId);
        }
        json responseData = {
            "id": assistantId,
            "object": "assistant.deleted",
            "deleted": true
        };

        check caller->respond(responseData);
    }

    // In-memory storage for threads and runs


// POST /threads - Create a new thread
resource function post threads(http:Caller caller, http:Request req) returns error? {
    string|http:HeaderNotFoundError betaHeader = req.getHeader("OpenAI-Beta");
    if betaHeader is http:HeaderNotFoundError || betaHeader != "assistants=v2" {
        http:Response errorResponse = new;
        errorResponse.statusCode = 400;
        errorResponse.setJsonPayload({"error": "Missing or invalid OpenAI-Beta header"});
        check caller->respond(errorResponse);
        return;
    }

    json|error requestBody = req.getJsonPayload();
    if requestBody is error {
        http:Response errorResponse = new;
        errorResponse.statusCode = 400;
        errorResponse.setJsonPayload({"error": "Invalid JSON payload"});
        check caller->respond(errorResponse);
        return;
    }

    string threadId = "thread_" + time:utcNow()[0].toString();
    json responseData = {
        "id": threadId,
        "object": "thread",
        "created_at": getCurrentTimestamp(),
        "metadata": check requestBody.metadata ?: {},
        "tool_resources": check requestBody.tool_resources ?: {"code_interpreter": {"file_ids": []}}
    };

    lock {
        threads[threadId] = responseData;
    }

    check caller->respond(responseData);
}

// GET /threads/[threadId] - Retrieve a thread by ID
resource function get threads/[string threadId](http:Caller caller, http:Request req) returns error? {
    string|http:HeaderNotFoundError betaHeader = req.getHeader("OpenAI-Beta");
    if betaHeader is http:HeaderNotFoundError || betaHeader != "assistants=v2" {
        http:Response errorResponse = new;
        errorResponse.statusCode = 400;
        errorResponse.setJsonPayload({"error": "Missing or invalid OpenAI-Beta header"});
        check caller->respond(errorResponse);
        return;
    }

    json|error thread;
    lock {
        thread = threads[threadId];
    }

    if thread is error || thread is () {
        http:Response errorResponse = new;
        errorResponse.statusCode = 404;
        errorResponse.setJsonPayload({"error": "Thread not found"});
        check caller->respond(errorResponse);
        return;
    }

    check caller->respond(thread);
}

// DELETE /threads/[threadId] - Delete a thread
resource function delete threads/[string threadId](http:Caller caller, http:Request req) returns error? {
    string|http:HeaderNotFoundError betaHeader = req.getHeader("OpenAI-Beta");
    if betaHeader is http:HeaderNotFoundError || betaHeader != "assistants=v2" {
        http:Response errorResponse = new;
        errorResponse.statusCode = 400;
        errorResponse.setJsonPayload({"error": "Missing or invalid OpenAI-Beta header"});
        check caller->respond(errorResponse);
        return;
    }

    json|error thread;
    lock {
        thread = threads[threadId];
    }

    if thread is error || thread is () {
        http:Response errorResponse = new;
        errorResponse.statusCode = 404;
        errorResponse.setJsonPayload({"error": "Thread not found"});
        check caller->respond(errorResponse);
        return;
    }

    lock {
        _ = threads.remove(threadId);
    }
    json responseData = {
        "id": threadId,
        "object": "thread.deleted",
        "deleted": true
    };

    check caller->respond(responseData);
}

// POST /threads/runs - Create a thread and run
resource function post threads/runs(http:Caller caller, http:Request req) returns error? {
    string|http:HeaderNotFoundError betaHeader = req.getHeader("OpenAI-Beta");
    if betaHeader is http:HeaderNotFoundError || betaHeader != "assistants=v2" {
        http:Response errorResponse = new;
        errorResponse.statusCode = 400;
        errorResponse.setJsonPayload({"error": "Missing or invalid OpenAI-Beta header"});
        check caller->respond(errorResponse);
        return;
    }

    json|error requestBody = req.getJsonPayload();
    if requestBody is error {
        http:Response errorResponse = new;
        errorResponse.statusCode = 400;
        errorResponse.setJsonPayload({"error": "Invalid JSON payload"});
        check caller->respond(errorResponse);
        return;
    }

    string runId = "run_" + time:utcNow()[0].toString();
    string threadId = "thread_" + time:utcNow()[0].toString();
    string assistantId = check requestBody.assistant_id.ensureType(string);

    // Create a thread for the run
    json threadData = {
        "id": threadId,
        "object": "thread",
        "created_at": getCurrentTimestamp(),
        "metadata": check requestBody.metadata ?: {},
        "tool_resources": check requestBody.thread.tool_resources ?: {"code_interpreter": {"file_ids": []}}
    };

    lock {
        threads[threadId] = threadData;
    }

    json responseData = {
        "id": runId,
        "object": "thread.run",
        "created_at": getCurrentTimestamp(),
        "assistant_id": assistantId,
        "thread_id": threadId,
        "status": "queued",
        "model": check requestBody.model ?: "gpt-4o",
        "instructions": check requestBody.instructions ?: "You are a personal math tutor.",
        "tools": check requestBody.tools ?: [{"type": "code_interpreter"}],
        "tool_resources": check requestBody.tool_resources ?: {"code_interpreter": {"file_ids": []}},
        "metadata": check requestBody.metadata ?: {},
        "top_p": check requestBody.top_p ?: 1.0,
        "temperature": check requestBody.temperature ?: 1.0,
        "max_prompt_tokens": check requestBody.max_prompt_tokens ?: 256,
        "max_completion_tokens": check requestBody.max_completion_tokens ?: 128,
        "response_format": check requestBody.response_format ?: "auto",
        "tool_choice": check requestBody.tool_choice ?: "auto",
        "truncation_strategy": check requestBody.truncation_strategy ?: {"last_messages": 10, "type": "auto"},
        "parallel_tool_calls": check requestBody.parallel_tool_calls ?: false
    };

    lock {
        runs[runId] = responseData;
    }

    check caller->respond(responseData);
}


};

function init() returns error? {
    log:printInfo("Mock service started on port 9090");
    check httpListener.attach(mockService, "/");
}