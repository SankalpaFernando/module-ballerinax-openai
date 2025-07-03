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

    // Create Personal Finance Assistant
    openai:CreateAssistantRequest request = {
        model: "gpt-4o",
        name: "Personal Finance Assistant",
        description: "A helpful assistant for managing budgets and providing financial advice.",
        instructions: "You are a personal finance assistant. Help users create budgets, track expenses, and provide financial advice. Use the code interpreter to perform calculations like savings, expense ratios, or investment projections.",
        metadata: {},
        topP: 1.0,
        temperature: 0.8,
        responseFormat: {"type": "text"}
    };

    openai:AssistantObject assistantResponse = check openaiClient->/assistants.post(request, headers = headers);
    io:println("Personal Finance Assistant Created -> ID: ", assistantResponse.id, "\n");

    // Get user input for budget
    io:println("Enter your monthly income (in USD): ");
    float income = check float:fromString(io:readln().trim());
    io:println("Enter your monthly expenses (comma-separated, e.g., 500,200,300): ");
    string[] expenseInputs = re `,`.split(io:readln().trim());
    float[] expenses = expenseInputs.map(s => check float:fromString(s.trim()));

    openai:CreateThreadRequest threadRequest = {
        messages: [
            {
                role: "user",
                content: string `My monthly income is $${income}. My expenses are ${expenses.toString()}. Calculate my savings and provide a budget analysis with advice to improve my financial health.`
            }
        ]
    };
    openai:ThreadObject thread = check openaiClient->/threads.post(threadRequest, headers = headers);

    openai:CreateRunRequest runRequest = {
        assistantId: assistantResponse.id,
        instructions: "Provide a detailed budget analysis and financial advice based on the user's input."
    };
    openai:RunObject run = check openaiClient->/threads/[thread.id]/runs.post(runRequest, headers = headers);

    // Poll for run completion
    openai:RunObject runStatus = check openaiClient->/threads/[thread.id]/runs/[run.id](headers = headers);
    while runStatus.status != "completed" {
        // Wait for 1 second before polling again
        runtime:sleep(1);
        runStatus = check openaiClient->/threads/[thread.id]/runs/[run.id](headers = headers);
    }

    io:println("Assistant Status: ", runStatus.status);
}
