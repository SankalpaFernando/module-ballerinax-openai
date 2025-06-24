import ballerina/io;
import ballerinax/openai;

configurable string token = ?;

public function main() returns error? {
    final openai:Client openaiClient = check new ({
        auth: {token: token}
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
