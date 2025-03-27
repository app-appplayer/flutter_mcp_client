import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:mcp_client/mcp_client.dart';
import 'package:flutter_mcp_common/flutter_mcp_common.dart';

/// Server configuration for MCP transports
class ServerConfig {
  /// Server type
  final ServerType type;
  
  /// Command to execute for stdio transport
  final String? command;
  
  /// Arguments for the command
  final List<String>? arguments;
  
  /// Working directory for the command
  final String? workingDirectory;
  
  /// Environment variables for the command
  final Map<String, String>? environment;
  
  /// URL for SSE transport
  final String? serverUrl;
  
  /// Headers for SSE transport
  final Map<String, String>? headers;
  
  /// Path to WebSocket endpoint
  final String? websocketEndpoint;
  
  /// Create a server configuration for stdio
  ServerConfig.stdio({
    required this.command,
    this.arguments,
    this.workingDirectory,
    this.environment,
  }) : 
    type = ServerType.stdio,
    serverUrl = null,
    headers = null,
    websocketEndpoint = null;
  
  /// Create a server configuration for SSE
  ServerConfig.sse({
    required this.serverUrl,
    this.headers,
  }) : 
    type = ServerType.sse,
    command = null,
    arguments = null,
    workingDirectory = null,
    environment = null,
    websocketEndpoint = null;
  
  /// Create a server configuration for WebSocket
  ServerConfig.websocket({
    required this.serverUrl,
    this.websocketEndpoint,
    this.headers,
  }) : 
    type = ServerType.websocket,
    command = null,
    arguments = null,
    workingDirectory = null,
    environment = null;
}

/// Types of MCP servers
enum ServerType {
  /// Standard I/O based server
  stdio,
  
  /// Server-Sent Events based server
  sse,
  
  /// WebSocket based server
  websocket
}

/// Factory for creating transports optimized for Flutter environment
class FlutterMcpTransportFactory {
  /// Create a stdio transport
  static Future<ClientTransport> createStdioTransport({
    required String command,
    List<String> arguments = const [],
    String? workingDirectory,
    Map<String, String>? environment,
  }) async {
    if (kIsWeb) {
      throw UnsupportedError('STDIO transport is not supported on Web platform');
    }
    
    try {
      return await StdioClientTransport.create(
        command: command,
        arguments: arguments,
        workingDirectory: workingDirectory,
        environment: environment,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Flutter MCP Transport Factory: Failed to create STDIO transport: $e');
      }
      rethrow;
    }
  }
  
  /// Create an SSE transport
  static ClientTransport createSseTransport({
    required String serverUrl,
    Map<String, String>? headers,
    bool persistConnection = true,
  }) {
    try {
      // Initialize SSE transport
      return SseClientTransport(
        serverUrl: serverUrl,
        headers: headers,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Flutter MCP Transport Factory: Failed to create SSE transport: $e');
      }
      rethrow;
    }
  }
  
  /// Create platform-optimized transport based on config
  static Future<ClientTransport> createOptimizedTransport(
    ServerConfig config,
  ) async {
    // Check platform capabilities
    final platform = FlutterMcpPlatform.instance;
    
    switch (config.type) {
      case ServerType.stdio:
        if (platform.isWeb) {
          throw UnsupportedError('STDIO transport is not supported on Web platform');
        }
        
        if (config.command == null) {
          throw ArgumentError('Command is required for STDIO transport');
        }
        
        return createStdioTransport(
          command: config.command!,
          arguments: config.arguments ?? [],
          workingDirectory: config.workingDirectory,
          environment: config.environment,
        );
      
      case ServerType.sse:
        if (config.serverUrl == null) {
          throw ArgumentError('Server URL is required for SSE transport');
        }
        
        return createSseTransport(
          serverUrl: config.serverUrl!,
          headers: config.headers,
        );
      
      case ServerType.websocket:
        throw UnimplementedError('WebSocket transport is not yet implemented');
    }
  }
  
  /// Detect if a server is available at the given URL
  static Future<bool> isServerAvailable(String url, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    if (kIsWeb) {
      // For web, we can't use HttpClient directly
      try {
        // Simple HEAD request using XMLHttpRequest
        // This will be implemented when WebSocket transport is added
        
        // For now, just return true for web
        return true;
      } catch (e) {
        return false;
      }
    } else {
      try {
        final uri = Uri.parse(url);
        final client = HttpClient();
        client.connectionTimeout = timeout;
        
        final request = await client.getUrl(uri);
        final response = await request.close();
        
        await response.drain<void>();
        client.close();
        
        return response.statusCode < 500;
      } catch (e) {
        return false;
      }
    }
  }
  
  /// Detect available local servers
  static Future<List<ServerConfig>> detectLocalServers({
    List<int> ports = const [8080, 3000, 9000],
    Duration timeout = const Duration(milliseconds: 500),
  }) async {
    if (kIsWeb) {
      return []; // Not supported on web
    }
    
    final servers = <ServerConfig>[];
    
    for (final port in ports) {
      final url = 'http://localhost:$port';
      
      try {
        final available = await isServerAvailable(url, timeout: timeout);
        
        if (available) {
          servers.add(ServerConfig.sse(serverUrl: '$url/sse'));
        }
      } catch (e) {
        // Ignore errors and continue checking other ports
      }
    }
    
    return servers;
  }
}
