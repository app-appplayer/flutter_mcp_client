import 'package:mcp_client/mcp_client.dart' as original;

// Original types for convenience
export 'package:mcp_client/mcp_client.dart' show
ResourceTemplate,
ResourceContentInfo,
ReadResourceResult,
PromptArgument,
Prompt,
GetPromptResult,
Message,
Content,
ImageContent,
ResourceContent,
ModelHint,
ModelPreferences,
CreateMessageRequest,
CreateMessageResult,
Root,
McpLogLevel,
McpError,
ClientCapabilities,
SseClientTransport,
StdioClientTransport;

// 이름을 변경하여 재정의
class ClientTool extends original.Tool {
  ClientTool({
    required super.name,
    required super.description,
    required super.inputSchema,
  });

  // Factory from original
  factory ClientTool.fromOriginal(original.Tool tool) {
    return ClientTool(
      name: tool.name,
      description: tool.description,
      inputSchema: tool.inputSchema,
    );
  }
}

class ClientResource extends original.Resource {
  ClientResource({
    required super.uri,
    required super.name,
    required super.description,
    required super.mimeType,
    super.uriTemplate,
  });

  // Factory from original
  factory ClientResource.fromOriginal(original.Resource resource) {
    return ClientResource(
      uri: resource.uri,
      name: resource.name,
      description: resource.description,
      mimeType: resource.mimeType,
      uriTemplate: resource.uriTemplate,
    );
  }
}

class ClientTextContent extends original.TextContent {
  ClientTextContent({required super.text});

  // Factory from original
  factory ClientTextContent.fromOriginal(original.TextContent content) {
    return ClientTextContent(text: content.text);
  }
}

class ClientCallToolResult extends original.CallToolResult {
  ClientCallToolResult(
      super.content, {
        super.isStreaming,
        super.isError,
      });

  // Factory from original
  factory ClientCallToolResult.fromOriginal(original.CallToolResult result) {
    return ClientCallToolResult(
      result.content,
      isStreaming: result.isStreaming,
      isError: result.isError,
    );
  }
}
