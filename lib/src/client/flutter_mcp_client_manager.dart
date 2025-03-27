import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_mcp_common/flutter_mcp_common.dart';

import 'flutter_mcp_client.dart';

/// Manager for multiple MCP client instances
class FlutterMcpClientManager {
  static final FlutterMcpClientManager _instance = FlutterMcpClientManager._();
  
  /// Get singleton instance
  static FlutterMcpClientManager get instance => _instance;
  
  /// Map of client instances by ID
  final _clients = <String, _ClientEntry>{};
  
  /// Whether the manager has been disposed
  bool _isDisposed = false;
  
  /// Stream controller for client registration events
  final _clientRegistrationController = StreamController<String>.broadcast();
  
  /// Private constructor
  FlutterMcpClientManager._();
  
  /// Stream of client registration events
  Stream<String> get onClientRegistered => _clientRegistrationController.stream;
  
  /// Register a client with the manager
  Future<void> registerClient(
    String id,
    FlutterMcpClient client, {
    int priority = 0,
  }) async {
    if (_isDisposed) {
      throw StateError('Manager has been disposed');
    }
    
    if (_clients.containsKey(id)) {
      throw ArgumentError('Client with ID "$id" is already registered');
    }
    
    // Store client with priority
    _clients[id] = _ClientEntry(client, priority);
    
    // Notify listeners
    _clientRegistrationController.add(id);

    if (kDebugMode) {
      debugPrint('Flutter MCP Client Manager: Registered client with ID "$id"');
    }
  }
  
  /// Unregister a client from the manager
  Future<void> unregisterClient(String id) async {
    if (_isDisposed) {
      return;
    }
    
    final client = _clients.remove(id);
    
    if (client != null && kDebugMode) {
      debugPrint('Flutter MCP Client Manager: Unregistered client with ID "$id"');
    }
  }
  
  /// Get a client by ID
  FlutterMcpClient? getClient(String id) {
    if (_isDisposed) {
      return null;
    }
    
    final entry = _clients[id];
    return entry?.client;
  }
  
  /// Get all registered clients
  List<FlutterMcpClient> getAllClients() {
    if (_isDisposed) {
      return [];
    }
    
    return _clients.values.map((entry) => entry.client).toList();
  }
  
  /// Get clients sorted by priority (highest first)
  List<FlutterMcpClient> getClientsByPriority() {
    if (_isDisposed) {
      return [];
    }
    
    final sortedEntries = _clients.values.toList()
      ..sort((a, b) => b.priority.compareTo(a.priority));
    
    return sortedEntries.map((entry) => entry.client).toList();
  }
  
  /// Get the highest priority client
  FlutterMcpClient? getHighestPriorityClient() {
    if (_isDisposed || _clients.isEmpty) {
      return null;
    }
    
    final sortedEntries = _clients.values.toList()
      ..sort((a, b) => b.priority.compareTo(a.priority));
    
    return sortedEntries.first.client;
  }
  
  /// Get clients filtered by connection state
  List<FlutterMcpClient> getClientsByState(ConnectionState state) {
    if (_isDisposed) {
      return [];
    }
    
    return _clients.values
        .where((entry) => entry.client.connectionState == state)
        .map((entry) => entry.client)
        .toList();
  }
  
  /// Get all connected clients
  List<FlutterMcpClient> getConnectedClients() {
    return getClientsByState(ConnectionState.connected);
  }
  
  /// Connect all registered clients
  Future<void> connectAll() async {
    if (_isDisposed) {
      return;
    }
    
    final clients = getAllClients();
    
    for (final client in clients) {
      if (client.connectionState == ConnectionState.disconnected) {
        try {
          // Only try to connect if client has a transport
          final transport = client.getTransport();
          if (transport != null) {
            await client.connect(transport);
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('Flutter MCP Client Manager: Failed to connect client: $e');
          }
          // Continue with other clients even if one fails
        }
      }
    }
  }
  
  /// Disconnect all registered clients
  Future<void> disconnectAll() async {
    if (_isDisposed) {
      return;
    }
    
    final clients = getAllClients();
    
    for (final client in clients) {
      try {
        await client.disconnect();
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Flutter MCP Client Manager: Failed to disconnect client: $e');
        }
        // Continue with other clients even if one fails
      }
    }
  }
  
  /// Adjust resource usage for all clients
  void adjustAllResources(AppResourceMode mode) {
    if (_isDisposed) {
      return;
    }
    
    final clients = getAllClients();
    
    for (final client in clients) {
      client.adjustResourceUsage(mode);
    }
  }
  
  /// Dispose all clients and release resources
  void dispose() {
    if (_isDisposed) {
      return;
    }
    
    _isDisposed = true;
    
    // Disconnect and dispose all clients
    final clients = getAllClients();
    
    for (final client in clients) {
      client.dispose();
    }
    
    _clients.clear();
    _clientRegistrationController.close();
  }
}

/// Internal class to store client with priority
class _ClientEntry {
  /// Client instance
  final FlutterMcpClient client;
  
  /// Priority level (higher values = higher priority)
  final int priority;
  
  /// Create client entry
  _ClientEntry(this.client, this.priority);
}
