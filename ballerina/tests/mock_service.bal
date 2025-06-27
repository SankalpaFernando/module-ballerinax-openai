// Copyright (c) 2024, WSO2 LLC. (http://www.wso2.com).
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

    resource function get assistants(http:Caller caller, http:Request req) returns error? {
        string|http:HeaderNotFoundError betaHeader = req.getHeader("OpenAI-Beta");
        if betaHeader is http:HeaderNotFoundError || betaHeader != "assistants=v2" {
            http:Response errorResponse = new;
            errorResponse.statusCode = 400;
            errorResponse.setJsonPayload({"error": "Missing or invalid OpenAI-Beta header"});
            check caller->respond(errorResponse);
            return;
        }

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

    resource function post assistants(http:Caller caller, http:Request req) returns error? {
        json|error requestBody = req.getJsonPayload();
        if requestBody is error {
            http:Response errorResponse = new;
            errorResponse.statusCode = 400;
            errorResponse.setJsonPayload({"error": "Invalid JSON payload"});
            check caller->respond(errorResponse);
            return;
        }
        string|http:HeaderNotFoundError betaHeader = req.getHeader("OpenAI-Beta");
        if betaHeader is http:HeaderNotFoundError || betaHeader != "assistants=v2" {
            http:Response errorResponse = new;
            errorResponse.statusCode = 400;
            errorResponse.setJsonPayload({"error": "Missing or invalid OpenAI-Beta header"});
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
        string|http:HeaderNotFoundError betaHeader = req.getHeader("OpenAI-Beta");
        if betaHeader is http:HeaderNotFoundError || betaHeader != "assistants=v2" {
            http:Response errorResponse = new;
            errorResponse.statusCode = 400;
            errorResponse.setJsonPayload({"error": "Missing or invalid OpenAI-Beta header"});
            check caller->respond(errorResponse);
            return;
        }

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
        string|http:HeaderNotFoundError betaHeader = req.getHeader("OpenAI-Beta");
        if betaHeader is http:HeaderNotFoundError || betaHeader != "assistants=v2" {
            http:Response errorResponse = new;
            errorResponse.statusCode = 400;
            errorResponse.setJsonPayload({"error": "Missing or invalid OpenAI-Beta header"});
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

    resource function post threads(http:Caller caller, http:Request req) returns error? {
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

    resource function get threads/[string threadId](http:Caller caller, http:Request req) returns error? {
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

    resource function delete threads/[string threadId](http:Caller caller, http:Request req) returns error? {
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

    resource function post threads/runs(http:Caller caller, http:Request req) returns RunObject|http:BadRequest|error?{
        json|error requestBody = req.getJsonPayload();
        if requestBody is error {
            return {
                body:"Failed to Parse JSON"
            };
        }

        string runId = "run_" + time:utcNow()[0].toString();
        string threadId = "thread_" + time:utcNow()[0].toString();
        string assistantId = check requestBody.assistant_id.ensureType(string);
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
        RunObject responseData = {
            id: runId,
            'object: "thread.run",
            createdAt: getCurrentTimestamp(),
            assistantId: assistantId,
            threadId: threadId,
            status: "queued",
            model: check requestBody.model ?: "gpt-4o",
            instructions: check requestBody.instructions ?: "You are a personal math tutor.",
            tools: check requestBody.tools ?: [{"type": "code_interpreter"}],
            toolResources: check requestBody.tool_resources ?: {"code_interpreter": {"file_ids": []}},
            metadata: check requestBody.metadata ?: {},
            topP: check requestBody.top_p ?: 1.0,
            temperature: check requestBody.temperature ?: 1.0,
            maxPromptTokens: check requestBody.max_prompt_tokens ?: 256,
            maxCompletionTokens: check requestBody.max_completion_tokens ?: 128,
            responseFormat: check requestBody.response_format ?: "auto",
            toolChoice: check requestBody.tool_choice ?: "auto",
            truncationStrategy: check requestBody.truncation_strategy ?: {"last_messages": 10, "type": "auto"},
            parallelToolCalls: check requestBody.parallel_tool_calls ?: false,
            usage: {
                promptTokens: 0,
                completionTokens: 0,
                totalTokens: 0,
                completionTokensDetails: {
                    acceptedPredictionTokens: 0,
                    audioTokens: 0,
                    reasoningTokens: 0,
                    rejectedPredictionTokens: 0
                },
                promptTokensDetails: {
                    audioTokens: 0,
                    cachedTokens: 0
                }
            },
            cancelledAt: 0,
            completedAt: 0,
            expiresAt: getCurrentTimestamp() + 3600,
            failedAt: 0,
            incompleteDetails:{
                reason: "max_completion_tokens"
            },
            lastError: "",
            requiredAction: "",
            startedAt: 0,
        };
        lock {
            runs[runId] = responseData;
        }
        return responseData;
    }

    resource function post audio/speech(http:Caller caller, http:Request req) returns byte[]|http:BadRequest {
        json|error requestBody = req.getJsonPayload();
        if requestBody is error {
            return {
                body:"Failed to Parse JSON"
            };
        }

        return "mock_mp3_data".toBytes();
    }

    resource function post chat/completions(http:Caller caller, http:Request req) returns CreateChatCompletionResponse|http:BadRequest|error? {
            json|error requestBody = req.getJsonPayload();
            if requestBody is error {
                return {
                    body:"Failed to Parse JSON"
                };
            }

            string model = check requestBody.model.ensureType(string);
            json[] messages = check requestBody.messages.ensureType();
            string completionId = "chatcmpl_" + time:utcNow()[0].toString();
            string userContent = "";
            foreach json msg in messages {
                if check msg.role == "user" {
                    userContent = check msg.content.ensureType(string);
                    break;
                }
            }
            return {
                id: completionId,
                'object: "chat.completion",
                created: getCurrentTimestamp(),
                model: model,
                choices: [
                    {
                        index: 0,
                        message: {
                            role: "assistant",
                            content: "Assistant response: " + userContent,
                            refusal:"refused"
                        },
                        finishReason: "stop",
                        logprobs: ()
                    }
                ],
                usage: {
                    promptTokens: 10,
                    completionTokens: 10,
                    totalTokens: 20
                }
            };
    }

    resource function post completions(http:Caller caller, http:Request req) returns CreateCompletionResponse|http:BadRequest|error?    {
        json|error requestBody = req.getJsonPayload();
        if requestBody is error {
                return{
                    body:"Failed to Parse JSON"
                };
        }

        string model = check requestBody.model.ensureType(string);
        return {
            id: "1",
            choices:[
                {
                    finishReason: "stop",
                    index: 0,
                    logprobs: {
                        textOffset: [0],
                        tokenLogprobs: [0],
                        tokens: ["string"],
                        topLogprobs: []
                    },
                    text: "string"
                }
            ],
            created: <int>time:monotonicNow(),
            model: model,
            systemFingerprint: "string",
            usage: {
                completionTokens: 0,
                promptTokens: 0,
                totalTokens: 0,
                completionTokensDetails: {
                acceptedPredictionTokens: 0,
                audioTokens: 0,
                reasoningTokens: 0,
                rejectedPredictionTokens: 0
                },
                promptTokensDetails: {
                audioTokens: 0,
                cachedTokens: 0
                }
            },
            'object: "text_completion"
        };
    }

    resource function post embeddings(http:Caller caller,http:Request req) returns CreateEmbeddingResponse|http:BadRequest|error?{
        json|error requestBody = req.getJsonPayload();
        if requestBody is error {
                return{
                    body:"Failed to Parse JSON"
                };
        }

        return {
            data: [
                {
                    index:0,
                    embedding: [
                        0
                    ],
                    "object": "embedding"
                }
            ],
            model:check requestBody.model,
            "object": "list",
            usage: {
                promptTokens:0,
                totalTokens:0
            }
        };
    }

};

function init() returns error? {
    log:printInfo("Mock service started on port 9090");
    check httpListener.attach(mockService, "/");
}
