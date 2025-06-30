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
import ballerina/io;

listener http:Listener httpListener = new (9090);

map<AssistantObject> assistants = {};
map<ThreadObject> threads = {};
map<RunObject> runs = {};
isolated function getCurrentTimestamp() returns int {
    time:Utc utc = time:utcNow();
    return utc[0];
}

http:Service mockService = service object {

    # Retrieve a list of assistants
    #
    # + req - The HTTP request object
    # + return - returns can be any of following types
    # http:Ok (The request has succeeded.)
    # http:BadRequest (The request has invalid or missing OpenAI-Beta header.)
    # error (An error occurred during processing.)
    resource function get assistants(http:Request req) returns ListAssistantsResponse|http:BadRequest|error? {
        string|http:HeaderNotFoundError betaHeader = req.getHeader("OpenAI-Beta");
        if betaHeader is http:HeaderNotFoundError || betaHeader != "assistants=v2" {
            return {
                body: "Missing or invalid OpenAI-Beta header"
            };
        }

        AssistantObject[] assistantList = [];
        lock {
            foreach var assistant in assistants {
                assistantList.push(assistant);
            }
        }
        ListAssistantsResponse responseData = {
            'object: "list",
            data: assistantList,
            firstId: assistantList.length() > 0 ?  assistantList[0].id : "",
            lastId: assistantList.length() > 0 ?  assistantList[assistantList.length() - 1].id : "",
            hasMore: false           
        };
        return responseData;
    }
    
    # Create a new assistant
    #
    # + requestBody - The payload containing assistant creation details
    # + req - The HTTP request object
    # + return - returns can be any of following types
    # http:Ok (The request has succeeded.)
    # http:BadRequest (The request has invalid or missing OpenAI-Beta header.)
    # error (An error occurred during processing.)
    resource function post assistants(@http:Payload CreateAssistantRequest requestBody, http:Request req) returns AssistantObject|http:BadRequest|error? {
        string|http:HeaderNotFoundError betaHeader = req.getHeader("OpenAI-Beta");
        if betaHeader is http:HeaderNotFoundError || betaHeader != "assistants=v2" {
            return {
                body: "Missing or invalid OpenAI-Beta header"
            };
        }

        string assistantId = "asst_" + time:utcNow()[0].toString(); 
        AssistantObject responseData = {
            id: assistantId,
            'object: "assistant",
            createdAt: getCurrentTimestamp(),
            name: requestBody?.name,
            description: requestBody?.description ,
            model:requestBody.model,
            instructions:requestBody?.instructions,
            tools: [{
                'type: "code_interpreter"
            }],
            toolResources: {codeInterpreter: {"file_ids": []}},
            metadata: requestBody?.metadata,
            topP: requestBody.topP ,
            temperature: requestBody.temperature,
            responseFormat:requestBody.responseFormat
        };
        lock {
            assistants[assistantId] = responseData;
        }
        return responseData;
    }

    # Retrieve an assistant by ID
    #
    # + assistantId - The ID of the assistant to retrieve
    # + req - The HTTP request object
    # + return - returns can be any of following types
    # http:Ok (The request has succeeded.)
    # http:BadRequest (The assistant is not found or the OpenAI-Beta header is invalid.)
    # error (An error occurred during processing.)
    resource function get assistants/[string assistantId](http:Request req) returns AssistantObject|http:BadRequest|error? {
        string|http:HeaderNotFoundError betaHeader = req.getHeader("OpenAI-Beta");
        if betaHeader is http:HeaderNotFoundError || betaHeader != "assistants=v2" {
            return {
                body: "Missing or invalid OpenAI-Beta header"
            };
        }

        AssistantObject? assistant;
        lock {
            assistant = assistants[assistantId];
        }
        if assistant is AssistantObject {
            return assistant;  
        }
        return {
            body: "Assistant not found"
        };
    }

    # Update an existing assistant
    #
    # + assistantId - The ID of the assistant to update
    # + requestBody - The payload containing updated assistant details
    # + req - The HTTP request object
    # + return - returns can be any of following types
    # http:Ok (The request has succeeded.)
    # http:BadRequest (The assistant is not found or the OpenAI-Beta header is invalid.)
    # error (An error occurred during processing.)
    resource function post assistants/[string assistantId](@http:Payload CreateAssistantRequest requestBody, http:Request req) returns AssistantObject|http:BadRequest|error? {        
        string|http:HeaderNotFoundError betaHeader = req.getHeader("OpenAI-Beta");
        if betaHeader is http:HeaderNotFoundError || betaHeader != "assistants=v2" {
            return {
                body: "Missing or invalid OpenAI-Beta header"
            };
        }

        AssistantObject? existingAssistant;
        lock {
            existingAssistant = assistants[assistantId];
        }
        if existingAssistant is AssistantObject {
            AssistantObject responseData = {
                id: assistantId,
                'object: "assistant",
                createdAt:  existingAssistant.createdAt,
                name: requestBody?.name,
                description: requestBody?.description,
                model: requestBody?.model,
                instructions: requestBody?.instructions,
                tools: requestBody?.tools,
                toolResources: existingAssistant?.toolResources,
                metadata: existingAssistant.metadata,
                topP: requestBody?.topP,
                temperature: requestBody?.temperature,
                responseFormat: requestBody?.responseFormat
            };
            lock {
                assistants[assistantId] = responseData;
            }
            return responseData;
        }
        return {
            body: "Assistant not found"
        };
    }

    # Delete an assistant
    #
    # + assistantId - The ID of the assistant to delete
    # + req - The HTTP request object
    # + return - returns can be any of following types
    # http:Ok (The request has succeeded.)
    # http:BadRequest (The assistant is not found or the OpenAI-Beta header is invalid.)
    # error (An error occurred during processing.)
    resource function delete assistants/[string assistantId](http:Request req) returns DeleteAssistantResponse|http:BadRequest|error? {
        string|http:HeaderNotFoundError betaHeader = req.getHeader("OpenAI-Beta");
        if betaHeader is http:HeaderNotFoundError || betaHeader != "assistants=v2" {
            return {
                body: "Missing or invalid OpenAI-Beta header"
            };
        }

        AssistantObject? assistant;
        lock{
           assistant = assistants[assistantId]; 
        }
        if assistant is AssistantObject {
            lock {
                _ = assistants.remove(assistantId);
            }
            DeleteAssistantResponse responseData = {
                id: assistantId,
                'object: "assistant.deleted",
                deleted: true
            };
            return responseData;
        }
        return {
            body: "Assistant not found"
        };
    }

    # Create a new thread
    #
    # + requestBody - The payload containing thread creation details
    # + req - The HTTP request object
    # + return - returns can be any of following types
    # http:Ok (The request has succeeded.)
    # http:BadRequest (The request is invalid.)
    # error (An error occurred during processing.)
    resource function post threads(@http:Payload CreateThreadRequest requestBody, http:Request req) returns ThreadObject|http:BadRequest|error? {
        string threadId = "thread_" + time:utcNow()[0].toString();

        ThreadObject responseData = {
            id: threadId,
            'object: "thread",
            createdAt: getCurrentTimestamp(),
            metadata: requestBody?.metadata,
            toolResources: {}
        };
        lock {
            threads[threadId] = responseData;
        }
        return responseData;
    }

    # Retrieve a thread by ID
    #
    # + threadId - The ID of the thread to retrieve
    # + return - returns can be any of following types
    # http:Ok (The request has succeeded.)
    # http:BadRequest (The thread is not found.)
    # error (An error occurred during processing.)
    resource function get threads/[string threadId]() returns ThreadObject|http:BadRequest|error? {
        ThreadObject? thread;
        lock {
            thread = threads[threadId];
        }
        if thread is ThreadObject {
            return thread;
        }
        return {
            body: "Thread not found"
        };
    }

    # Delete a thread
    #
    # + threadId - The ID of the thread to delete
    # + return - returns can be any of following types
    # http:Ok (The request has succeeded.)
    # http:BadRequest (The thread is not found.)
    resource function delete threads/[string threadId]() returns DeleteThreadResponse|http:BadRequest {
        ThreadObject? thread;
        lock {
            thread = threads[threadId];
        }
        if thread is ThreadObject {
            lock {
                _ = threads.remove(threadId);
            }
            DeleteThreadResponse responseData = {
                "id": threadId,
                "object": "thread.deleted",
                "deleted": true
            };
            return responseData;
        }
        return {
            body: "Thread not found"
        };    
    }

    # Create a thread and run
    #
    # + requestBody - The payload containing thread and run creation details
    # + req - The HTTP request object
    # + return - returns can be any of following types
    # http:Ok (The request has succeeded.)
    # http:BadRequest (The request is invalid.)
    # error (An error occurred during processing.)
    resource function post threads/runs(@http:Payload CreateThreadAndRunRequest requestBody, http:Request req) returns RunObject|http:BadRequest|error{
        string runId = "run_" + time:utcNow()[0].toString();
        string threadId = "thread_" + time:utcNow()[0].toString();
        string assistantId = check requestBody.assistantId.ensureType(string);
        ThreadObject threadData = {
            id: threadId,
            'object: "thread",
            createdAt: getCurrentTimestamp(),
            metadata: (requestBody?.metadata ?: {}),
            toolResources: {}
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
            model:  check requestBody?.model.ensureType(string),
            instructions: check requestBody?.instructions.ensureType(string),
            metadata: {},
            topP: check requestBody?.topP.ensureType(decimal),
            temperature: check requestBody.temperature.ensureType(),
            maxPromptTokens: check requestBody?.maxPromptTokens.ensureType(int),
            maxCompletionTokens: check requestBody?.maxCompletionTokens.ensureType(int),
            responseFormat: check requestBody?.responseFormat.ensureType(),
            toolChoice: check requestBody.toolChoice.ensureType(AssistantsApiToolChoiceOption),
            truncationStrategy:check requestBody.truncationStrategy.ensureType(),
            parallelToolCalls:check requestBody?.parallelToolCalls.ensureType(),
            usage: {
                promptTokens: 0,
                completionTokens: 0,
                totalTokens: 0
            },
            cancelledAt: 0,
            completedAt: 0,
            expiresAt: getCurrentTimestamp() + 3600,
            failedAt: 0,
            incompleteDetails:{
                reason: "max_completion_tokens"
            },
            lastError: {
                code:"rate_limit_exceeded",
                message: "Rate limit exceeded. Please try again later."
            },
            requiredAction: {
                submitToolOutputs: {toolCalls: []},
                'type: "submit_tool_outputs"
            },
            startedAt: 0
        };
        lock {
            runs[runId] = responseData;
        }
        return responseData;
    }

    # Generate speech audio
    #
    # + requestBody - The payload containing speech generation details
    # + req - The HTTP request object
    # + return - returns can be any of following types
    # http:Ok (The request has succeeded.)
    # http:BadRequest (The request is invalid.)
    resource function post audio/speech(@http:Payload CreateSpeechRequest requestBody, http:Request req) returns byte[]|http:BadRequest {
        return "mock_mp3_data".toBytes();
    }
    
    # Create a chat completion
    #
    # + requestBody - The payload containing chat completion details
    # + req - The HTTP request object
    # + return - returns can be any of following types
    # http:Ok (The request has succeeded.)
    # http:BadRequest (The request is invalid.)
    # error (An error occurred during processing.)
    resource function post chat/completions(@http:Payload CreateChatCompletionRequest requestBody, http:Request req) returns CreateChatCompletionResponse|http:BadRequest|error? {
            string model = check requestBody.model.ensureType(string);
            string completionId = "chatcmpl_" + time:utcNow()[0].toString();
            io:print("Received request for chat completion with model: ", model, "\n");
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
                            content: "Assistant response",
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

    # Create a text completion
    #
    # + requestBody - The payload containing text completion details
    # + req - The HTTP request object
    # + return - returns can be any of following types
    # http:Ok (The request has succeeded.)
    # http:BadRequest (The request is invalid.)
    # error (An error occurred during processing.)
    resource function post completions(@http:Payload CreateCompletionRequest requestBody, http:Request req) returns CreateCompletionResponse|http:BadRequest|error?    {
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
    
    # Create embeddings
    #
    # + requestBody - The payload containing embedding creation details
    # + req - The HTTP request object
    # + return - returns can be any of following types
    # http:Ok (The request has succeeded.)
    # http:BadRequest (The request is invalid.)
    # error (An error occurred during processing.)
    resource function post embeddings(@http:Payload CreateEmbeddingRequest requestBody,http:Request req) returns CreateEmbeddingResponse|http:BadRequest|error?{
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
            model: requestBody.model,
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
