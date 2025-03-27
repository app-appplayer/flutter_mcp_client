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

// Models
export 'src/models/flutter_mcp_client_models.dart';

// Re-export common classes from flutter_mcp_common
export 'package:flutter_mcp_common/flutter_mcp_common.dart' show
FlutterMcpPlatform,
FlutterMcpLifecycleManager,
FlutterMcpConfig,
FlutterMcpBackgroundService,
FlutterMcpBackgroundIsolate,
FlutterMcpNetworkManager,
NetworkQuality,
FlutterMcpNotificationManager,
FlutterMcpSecureStorage,
AppResourceMode,
Logger;
