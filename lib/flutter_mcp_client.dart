library flutter_mcp_client;

// Client implementation
export 'src/client/flutter_mcp_client.dart';
export 'src/client/flutter_mcp_client_config.dart';
export 'src/client/flutter_mcp_client_manager.dart';
export 'src/client/flutter_mcp_connection_manager.dart';

// Transport implementation
export 'src/transport/flutter_mcp_transport_factory.dart';

// Widgets
export 'src/widgets/flutter_mcp_tools_widget.dart';
export 'src/widgets/flutter_mcp_status_widget.dart';

// Re-export MCP client core types for convenience
export 'package:mcp_client/mcp_client.dart' show
Tool,
Resource,
ResourceTemplate,
ResourceContentInfo,
CallToolResult,
ReadResourceResult,
PromptArgument,
Prompt,
GetPromptResult,
Message,
Content,
TextContent,
ImageContent,
ResourceContent,
ModelHint,
ModelPreferences,
CreateMessageRequest,
CreateMessageResult,
Root,
McpLogLevel,
McpError,
ClientCapabilities;