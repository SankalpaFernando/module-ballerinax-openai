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
import ballerinax/openai;

configurable string token = ?;
configurable map<string> headers = {
    "OpenAI-Beta": "assistants=v2"
};
public function main() returns error? {
    final openai:Client openaiClient = check new ({
        auth: {token}
    });

    // Create Assistant 
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

    openai:AssistantObject response = check openaiClient->/assistants.post(request,headers=headers);
    
    io:println("New Assistant Created -> ",response,"\n");

    //List the Assistants
    openai:ListAssistantsResponse listResponse = check openaiClient->/assistants(headers=headers);

    io:println("Assistants ->",listResponse,"\n");
}
