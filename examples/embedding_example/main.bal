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

public function main() returns error? {
    final openai:Client openaiClient = check new ({
        auth: {token}
    });

    //Create Embedding
    openai:CreateEmbeddingRequest createEmbeddingRequest = {
        input: "This is a sample text.",
        model: "text-embedding-ada-002",
        encodingFormat: "float",
        dimensions: 1,
        user: "user-1234"
    };

    openai:CreateEmbeddingResponse response = check openaiClient->/embeddings.post(createEmbeddingRequest);

    io:println(response); 

}
