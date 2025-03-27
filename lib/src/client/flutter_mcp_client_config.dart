import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Configuration for the Flutter MCP client
class FlutterMcpClientConfig {
  /// Default auto-reconnect setting
  static const bool defaultAutoReconnect = true;
  
  /// Default maximum reconnect attempts
  static const int defaultMaxReconnectAttempts = 5;
  
  /// Default reconnect interval in seconds
  static const int defaultReconnectIntervalSeconds = 5;
  
  /// Default setting for maintaining connection in background
  static const bool defaultMaintainConnectionInBackground = false;
  
  /// Default timeout for operations in seconds
  static const int defaultOperationTimeoutSeconds = 30;
  
  /// Whether to automatically reconnect on disconnection
  final bool autoReconnect;
  
  /// Maximum number of reconnect attempts
  final int maxReconnectAttempts;
  
  /// Interval between reconnect attempts
  final Duration reconnectInterval;
  
  /// Whether to maintain connection when app is in background
  final bool maintainConnectionInBackground;
  
  /// Timeout for operations
  final Duration operationTimeout;
  
  /// Whether to handle tool events automatically
  final bool handleToolEvents;
  
  /// Whether to handle resource events automatically
  final bool handleResourceEvents;
  
  /// Create a new client configuration
  FlutterMcpClientConfig({
    this.autoReconnect = defaultAutoReconnect,
    this.maxReconnectAttempts = defaultMaxReconnectAttempts,
    Duration? reconnectInterval,
    this.maintainConnectionInBackground = defaultMaintainConnectionInBackground,
    Duration? operationTimeout,
    this.handleToolEvents = true,
    this.handleResourceEvents = true,
  }) : 
    reconnectInterval = reconnectInterval ?? const Duration(seconds: defaultReconnectIntervalSeconds),
    operationTimeout = operationTimeout ?? const Duration(seconds: defaultOperationTimeoutSeconds);
  
  /// Create a configuration with default values
  factory FlutterMcpClientConfig.defaults() {
    return FlutterMcpClientConfig();
  }
  
  /// Load configuration from shared preferences
  static Future<FlutterMcpClientConfig> load() async {
    final prefs = await SharedPreferences.getInstance();
    final configJson = prefs.getString('flutter_mcp_client_config');
    
    if (configJson == null) {
      return FlutterMcpClientConfig.defaults();
    }
    
    try {
      final configMap = jsonDecode(configJson) as Map<String, dynamic>;
      return FlutterMcpClientConfig.fromJson(configMap);
    } catch (e) {
      // If config is corrupted, return defaults
      return FlutterMcpClientConfig.defaults();
    }
  }
  
  /// Save configuration to shared preferences
  Future<bool> save() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.setString('flutter_mcp_client_config', jsonEncode(toJson()));
  }
  
  /// Convert configuration to JSON map
  Map<String, dynamic> toJson() {
    return {
      'autoReconnect': autoReconnect,
      'maxReconnectAttempts': maxReconnectAttempts,
      'reconnectIntervalSeconds': reconnectInterval.inSeconds,
      'maintainConnectionInBackground': maintainConnectionInBackground,
      'operationTimeoutSeconds': operationTimeout.inSeconds,
      'handleToolEvents': handleToolEvents,
      'handleResourceEvents': handleResourceEvents,
    };
  }
  
  /// Create configuration from JSON map
  factory FlutterMcpClientConfig.fromJson(Map<String, dynamic> json) {
    return FlutterMcpClientConfig(
      autoReconnect: json['autoReconnect'] ?? defaultAutoReconnect,
      maxReconnectAttempts: json['maxReconnectAttempts'] ?? defaultMaxReconnectAttempts,
      reconnectInterval: Duration(seconds: json['reconnectIntervalSeconds'] ?? defaultReconnectIntervalSeconds),
      maintainConnectionInBackground: json['maintainConnectionInBackground'] ?? defaultMaintainConnectionInBackground,
      operationTimeout: Duration(seconds: json['operationTimeoutSeconds'] ?? defaultOperationTimeoutSeconds),
      handleToolEvents: json['handleToolEvents'] ?? true,
      handleResourceEvents: json['handleResourceEvents'] ?? true,
    );
  }
  
  /// Create a copy of this configuration with specified fields replaced
  FlutterMcpClientConfig copyWith({
    bool? autoReconnect,
    int? maxReconnectAttempts,
    Duration? reconnectInterval,
    bool? maintainConnectionInBackground,
    Duration? operationTimeout,
    bool? handleToolEvents,
    bool? handleResourceEvents,
  }) {
    return FlutterMcpClientConfig(
      autoReconnect: autoReconnect ?? this.autoReconnect,
      maxReconnectAttempts: maxReconnectAttempts ?? this.maxReconnectAttempts,
      reconnectInterval: reconnectInterval ?? this.reconnectInterval,
      maintainConnectionInBackground: maintainConnectionInBackground ?? this.maintainConnectionInBackground,
      operationTimeout: operationTimeout ?? this.operationTimeout,
      handleToolEvents: handleToolEvents ?? this.handleToolEvents,
      handleResourceEvents: handleResourceEvents ?? this.handleResourceEvents,
    );
  }
}
