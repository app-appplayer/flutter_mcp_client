import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:mcp_client/mcp_client.dart';
import 'package:flutter_mcp_common/flutter_mcp_common.dart';
import 'package:uuid/uuid.dart';

import 'flutter_mcp_client_config.dart';
import 'flutter_mcp_connection_manager.dart';

/// Connection states for Flutter MCP client
enum ConnectionState {
  /// Client is disconnected
  disconnected,
  
  /// Client is attempting to connect
  connecting,
  
  /// Client is connected
  connected,
  
  /// Client has encountered an error
  error,
  
  /// Client connection is paused (app in background)
  paused
}

/// Main Flutter client for MCP protocol
class FlutterMcpClient with WidgetsBindingObserver {
  /// Unique ID for this client instance
  final String id;
  
  /// Underlying MCP client instance
  final Client _client;
  
  /// Configuration for this client
  final FlutterMcpClientConfig config;
  
  /// Connection manager for handling connectivity
  late final FlutterMcpConnectionManager _connectionManager;
  
  /// Current connection state
  ConnectionState _connectionState = ConnectionState.disconnected;
  
  /// Stream controller for connection state changes
  final _connectionStateController = StreamController<ConnectionState>.broadcast();
  
  /// Stream controller for error events
  final _errorController = StreamController<McpError>.broadcast();
  
  /// Transport instance
  ClientTransport? _transport;

  /// Set the transport to use for connection
  void setTransport(ClientTransport transport) {
    _transport = transport;
  }

  /// Get current transport
  ClientTransport? getTransport() {
    return _transport;
  }

  /// Whether this client has been disposed
  bool _isDisposed = false;
  
  /// Create a new Flutter MCP client
  FlutterMcpClient({
    String? id,
    required String name,
    required String version,
    ClientCapabilities? capabilities,
    FlutterMcpClientConfig? config,
  }) : 
    id = id ?? const Uuid().v4(),
    _client = Client(
      name: name,
      version: version,
      capabilities: capabilities ?? const ClientCapabilities(
        roots: true,
        rootsListChanged: true,
        sampling: true,
      ),
    ),
    config = config ?? FlutterMcpClientConfig(),
    super() {
    
    // Initialize connection manager
    _connectionManager = FlutterMcpConnectionManager(
      client: this,
      autoReconnect: this.config.autoReconnect,
      maxReconnectAttempts: this.config.maxReconnectAttempts,
      reconnectInterval: this.config.reconnectInterval,
    );
    
    // Add lifecycle observer
    WidgetsBinding.instance.addObserver(this);
  }
  
  /// Factory method to create a new client instance
  static Future<FlutterMcpClient> create({
    String? id,
    required String name,
    required String version,
    ClientCapabilities? capabilities,
    FlutterMcpClientConfig? config,
  }) async {
    // Create client instance
    final client = FlutterMcpClient(
      id: id,
      name: name,
      version: version, 
      capabilities: capabilities,
      config: config,
    );
    
    return client;
  }
  
  /// Get the underlying MCP client
  Client get mcpClient => _client;
  
  /// Get current connection state
  ConnectionState get connectionState => _connectionState;
  
  /// Stream of connection state changes
  Stream<ConnectionState> get connectionStateStream => _connectionStateController.stream;
  
  /// Stream of error events
  Stream<McpError> get errorStream => _errorController.stream;
  
  /// Whether the client is currently connected
  bool get isConnected => 
      _connectionState == ConnectionState.connected && 
      _client.isConnected;
  
  /// Get server capabilities
  ServerCapabilities? get serverCapabilities => _client.serverCapabilities;
  
  /// Get server information
  Map<String, dynamic>? get serverInfo => _client.serverInfo;
  
  /// Connect to a transport
  Future<void> connect(ClientTransport transport) async {
    if (_isDisposed) {
      throw StateError('Client has been disposed');
    }
    
    if (_connectionState == ConnectionState.connecting) {
      throw StateError('Already connecting to a transport');
    }
    
    // Store transport for later use
    _transport = transport;
    
    // Update state
    _setConnectionState(ConnectionState.connecting);
    
    try {
      // Connect to transport
      await _client.connect(transport);
      
      // Update state
      _setConnectionState(ConnectionState.connected);
      
      // Set up tool events listener if needed
      if (config.handleToolEvents) {
        _setupToolEventsListener();
      }
      
      // Set up resource events listener if needed
      if (config.handleResourceEvents) {
        _setupResourceEventsListener();
      }
      
    } catch (e) {
      // Update state
      _setConnectionState(ConnectionState.error);
      
      // Add error to error stream
      if (e is McpError) {
        _errorController.add(e);
      } else {
        _errorController.add(McpError(e.toString()));
      }
      
      rethrow;
    }
  }
  
  /// Disconnect from the transport
  Future<void> disconnect() async {
    if (_isDisposed) {
      return;
    }
    
    if (_connectionState == ConnectionState.disconnected) {
      return;
    }
    
    // Clean up listeners
    _cleanupEventListeners();
    
    // Disconnect from transport
    _client.disconnect();
    
    // Update state
    _setConnectionState(ConnectionState.disconnected);
  }
  
  /// List available tools
  Future<List<Tool>> listTools() async {
    _checkConnection();
    return await _client.listTools();
  }
  
  /// Call a tool
  Future<CallToolResult> callTool(String name, Map<String, dynamic> arguments) async {
    _checkConnection();
    return await _client.callTool(name, arguments);
  }
  
  /// List available resources
  Future<List<Resource>> listResources() async {
    _checkConnection();
    return await _client.listResources();
  }
  
  /// Read a resource
  Future<ReadResourceResult> readResource(String uri) async {
    _checkConnection();
    return await _client.readResource(uri);
  }
  
  /// Subscribe to resource updates
  Future<void> subscribeResource(String uri) async {
    _checkConnection();
    return await _client.subscribeResource(uri);
  }
  
  /// Unsubscribe from resource updates
  Future<void> unsubscribeResource(String uri) async {
    _checkConnection();
    return await _client.unsubscribeResource(uri);
  }
  
  /// List resource templates
  Future<List<ResourceTemplate>> listResourceTemplates() async {
    _checkConnection();
    return await _client.listResourceTemplates();
  }
  
  /// List available prompts
  Future<List<Prompt>> listPrompts() async {
    _checkConnection();
    return await _client.listPrompts();
  }
  
  /// Get a prompt
  Future<GetPromptResult> getPrompt(String name, [Map<String, dynamic>? arguments]) async {
    _checkConnection();
    return await _client.getPrompt(name, arguments);
  }
  
  /// Request model sampling
  Future<CreateMessageResult> createMessage(CreateMessageRequest request) async {
    _checkConnection();
    return await _client.createMessage(request);
  }
  
  /// Add a root
  Future<void> addRoot(Root root) async {
    _checkConnection();
    return await _client.addRoot(root);
  }
  
  /// Remove a root
  Future<void> removeRoot(String uri) async {
    _checkConnection();
    return await _client.removeRoot(uri);
  }
  
  /// List roots
  Future<List<Root>> listRoots() async {
    _checkConnection();
    return await _client.listRoots();
  }
  
  /// Set the logging level
  Future<void> setLoggingLevel(McpLogLevel level) async {
    _checkConnection();
    return await _client.setLoggingLevel(level);
  }
  
  /// Register for notification of tools list changes
  void onToolsListChanged(Function() handler) {
    _client.onToolsListChanged(handler);
  }
  
  /// Register for notification of resources list changes
  void onResourcesListChanged(Function() handler) {
    _client.onResourcesListChanged(handler);
  }
  
  /// Register for notification of prompts list changes
  void onPromptsListChanged(Function() handler) {
    _client.onPromptsListChanged(handler);
  }
  
  /// Register for notification of roots list changes
  void onRootsListChanged(Function() handler) {
    _client.onRootsListChanged(handler);
  }
  
  /// Register for notification of resource updates
  void onResourceUpdated(Function(String) handler) {
    _client.onResourceUpdated(handler);
  }
  
  /// Register for notification of logging events
  void onLogging(Function(McpLogLevel, String, String?, Map<String, dynamic>?) handler) {
    _client.onLogging(handler);
  }
  
  /// Handle lifecycle state changes
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Only handle if client is connected and not disposed
    if (_isDisposed || _connectionState != ConnectionState.connected) {
      return;
    }
    
    switch (state) {
      case AppLifecycleState.resumed:
        // Resume connection if it was paused
        if (_connectionState == ConnectionState.paused) {
          _resumeConnection();
        }
        
        // Adjust resource usage
        adjustResourceUsage(AppResourceMode.full);
        break;
      
      case AppLifecycleState.inactive:
        // Reduce resource usage
        adjustResourceUsage(AppResourceMode.reduced);
        break;
      
      case AppLifecycleState.paused:
        // Pause or maintain connection based on config
        if (config.maintainConnectionInBackground) {
          // Just reduce resource usage
          adjustResourceUsage(AppResourceMode.minimal);
        } else {
          // Pause connection
          _pauseConnection();
        }
        break;
      
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        // Further reduce resource usage or disconnect based on config
        if (config.maintainConnectionInBackground) {
          adjustResourceUsage(AppResourceMode.suspended);
        } else {
          disconnect();
        }
        break;
    }
  }
  
  /// Adjust resource usage based on app state
  void adjustResourceUsage(AppResourceMode mode) {
    // This can be used to optimize resource usage based on app state
    // For now, just log the mode change
    if (kDebugMode) {
      print('MCP Client adjusting resource usage to: $mode');
    }
  }
  
  /// Clean up resources
  void dispose() {
    if (_isDisposed) {
      return;
    }
    
    // Mark as disposed
    _isDisposed = true;
    
    // Disconnect if connected
    if (_connectionState != ConnectionState.disconnected) {
      _client.disconnect();
    }
    
    // Clean up event handlers
    _cleanupEventListeners();
    
    // Remove lifecycle observer
    WidgetsBinding.instance.removeObserver(this);
    
    // Close stream controllers
    _connectionStateController.close();
    _errorController.close();
    
    // Clean up connection manager
    _connectionManager.dispose();
  }
  
  /// Set connection state and notify listeners
  void _setConnectionState(ConnectionState state) {
    if (_connectionState != state) {
      _connectionState = state;
      _connectionStateController.add(state);
    }
  }
  
  /// Check if client is connected
  void _checkConnection() {
    if (_isDisposed) {
      throw StateError('Client has been disposed');
    }
    
    if (!isConnected) {
      throw StateError('Client is not connected');
    }
  }
  
  /// Set up tool events listener
  void _setupToolEventsListener() {
    // For future implementation
  }
  
  /// Set up resource events listener
  void _setupResourceEventsListener() {
    // For future implementation
  }
  
  /// Clean up event listeners
  void _cleanupEventListeners() {
    // For future implementation
  }
  
  /// Pause connection (when app goes to background)
  void _pauseConnection() {
    if (_connectionState == ConnectionState.connected) {
      _setConnectionState(ConnectionState.paused);
    }
  }
  
  /// Resume connection (when app comes to foreground)
  void _resumeConnection() {
    if (_connectionState == ConnectionState.paused) {
      _setConnectionState(ConnectionState.connected);
    }
  }
}
