import ballerina/io;
import ballerinax/openai;

configurable string token = ?;
configurable map<string> headers = {
    "OpenAI-Beta": "assistants=v2"
};
public function main() returns error? {
    final openai:Client openaiClient = check new ({
        auth: {token: token}
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
