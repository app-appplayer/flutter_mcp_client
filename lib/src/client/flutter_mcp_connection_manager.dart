import 'dart:async';
import 'dart:math' as math;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_mcp_common/flutter_mcp_common.dart';

import 'flutter_mcp_client.dart';

/// Reconnection policy type
enum ReconnectPolicy {
  /// No automatic reconnection
  none,
  
  /// Linear backoff (fixed interval)
  linear,
  
  /// Exponential backoff
  exponential
}

/// Manager for MCP client connections
class FlutterMcpConnectionManager {
  /// Client instance to manage
  final FlutterMcpClient client;
  
  /// Whether to auto-reconnect
  final bool autoReconnect;
  
  /// Maximum reconnection attempts
  final int maxReconnectAttempts;
  
  /// Base interval between reconnection attempts
  final Duration reconnectInterval;
  
  /// Current reconnection policy
  ReconnectPolicy _reconnectPolicy = ReconnectPolicy.exponential;
  
  /// Current reconnection attempt count
  int _reconnectAttempt = 0;
  
  /// Timer for reconnection attempts
  Timer? _reconnectTimer;
  
  /// Whether a reconnection attempt is in progress
  bool _isReconnecting = false;
  
  /// Whether background mode is enabled
  bool _backgroundMode = false;
  
  /// Whether the manager is disposed
  bool _isDisposed = false;
  
  /// Subscription to network changes
  StreamSubscription? _networkSubscription;
  
  /// Create a new connection manager
  FlutterMcpConnectionManager({
    required this.client,
    this.autoReconnect = true,
    this.maxReconnectAttempts = 5,
    this.reconnectInterval = const Duration(seconds: 5),
  }) {
    // Listen for connection state changes
    client.connectionStateStream.listen(_handleConnectionStateChange);
    
    // Monitor network connectivity if enabled
    if (autoReconnect) {
      _monitorNetworkConnectivity();
    }
  }
  
  /// Get current reconnection policy
  ReconnectPolicy get reconnectPolicy => _reconnectPolicy;
  
  /// Set reconnection policy
  void setReconnectPolicy(ReconnectPolicy policy) {
    _reconnectPolicy = policy;
  }
  
  /// Handle connection state changes
  void _handleConnectionStateChange(ConnectionState state) {
    if (_isDisposed) return;
    
    switch (state) {
      case ConnectionState.disconnected:
        // Attempt to reconnect if auto-reconnect is enabled and not in background mode
        if (autoReconnect && !_backgroundMode && !_isReconnecting) {
          _scheduleReconnect();
        }
        break;
      
      case ConnectionState.connected:
        // Reset reconnection attempts on successful connection
        _reconnectAttempt = 0;
        _cancelReconnect();
        break;
      
      case ConnectionState.error:
        // Handle error state - possibly attempt reconnection
        if (autoReconnect && !_backgroundMode && !_isReconnecting) {
          _scheduleReconnect();
        }
        break;
      
      case ConnectionState.paused:
        // Cancel reconnection attempts when paused
        _cancelReconnect();
        break;
        
      case ConnectionState.connecting:
        // Nothing specific to do here
        break;
    }
  }
  
  /// Handle network connectivity changes
  void handleNetworkChange(ConnectivityResult result) {
    if (_isDisposed) return;
    
    // If we regain connectivity and client is disconnected, try to reconnect
    if (result != ConnectivityResult.none && 
        client.connectionState != ConnectionState.connected && 
        client.connectionState != ConnectionState.connecting &&
        autoReconnect && 
        !_backgroundMode && 
        !_isReconnecting) {
      
      _scheduleReconnect(immediate: true);
    }
  }
  
  /// Schedule a reconnection attempt
  void _scheduleReconnect({bool immediate = false}) {
    if (_isDisposed || _isReconnecting) return;
    
    // Cancel any existing reconnect timer
    _cancelReconnect();
    
    // Check if we've exceeded the maximum number of attempts
    if (_reconnectAttempt >= maxReconnectAttempts) {
      if (kDebugMode) {
        print('Flutter MCP Connection Manager: Maximum reconnection attempts reached');
      }
      return;
    }
    
    // Increment attempt counter
    _reconnectAttempt++;
    
    // Calculate delay based on policy
    Duration delay;
    
    if (immediate) {
      delay = Duration.zero;
    } else {
      switch (_reconnectPolicy) {
        case ReconnectPolicy.none:
          return; // Don't reconnect
        
        case ReconnectPolicy.linear:
          delay = reconnectInterval;
          break;
        
        case ReconnectPolicy.exponential:
          // Simple exponential backoff: base * 2^(attempt-1) capped at 30 seconds
          final backoffFactor = math.pow(2, _reconnectAttempt - 1).toInt();
          final calculatedDelay = reconnectInterval.inMilliseconds * backoffFactor;
          delay = Duration(milliseconds: calculatedDelay.clamp(0, 30000));
          break;
      }
    }
    
    if (kDebugMode) {
      print('Flutter MCP Connection Manager: Scheduling reconnect in ${delay.inMilliseconds}ms (attempt $_reconnectAttempt)');
    }
    
    _isReconnecting = true;
    
    // Schedule reconnect
    _reconnectTimer = Timer(delay, () async {
      try {
        await _attemptReconnect();
      } finally {
        _isReconnecting = false;
      }
    });
  }
  
  /// Attempt to reconnect to the transport
  Future<void> _attemptReconnect() async {
    if (_isDisposed) return;
    
    if (kDebugMode) {
      print('Flutter MCP Connection Manager: Attempting to reconnect');
    }
    
    try {
      // Check if client still exists and has a transport
      final transport = client.getTransport();
      if (transport == null) {
        if (kDebugMode) {
          print('Flutter MCP Connection Manager: No transport available for reconnection');
        }
        return;
      }
      
      // Attempt to connect
      await client.connect(transport);
      
      if (kDebugMode) {
        print('Flutter MCP Connection Manager: Reconnection successful');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Flutter MCP Connection Manager: Reconnection failed: $e');
      }
      
      // Schedule next reconnect attempt if we haven't reached the maximum
      if (_reconnectAttempt < maxReconnectAttempts) {
        _scheduleReconnect();
      }
    }
  }
  
  /// Cancel any pending reconnection attempt
  void _cancelReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }
  
  /// Set background mode status
  void setBackgroundMode(bool enabled) {
    _backgroundMode = enabled;
    
    if (enabled) {
      // Cancel reconnection attempts when in background
      _cancelReconnect();
    } else {
      // When returning from background, check if we need to reconnect
      if (autoReconnect && 
          client.connectionState != ConnectionState.connected && 
          client.connectionState != ConnectionState.connecting && 
          !_isReconnecting) {
        _scheduleReconnect();
      }
    }
  }
  
  /// Monitor network connectivity changes
  void _monitorNetworkConnectivity() {
    final networkManager = FlutterMcpNetworkManager.instance;
    
    _networkSubscription = networkManager.onConnectivityChanged.listen((result) {
      handleNetworkChange(result);
    });
  }
  
  /// Dispose resources
  void dispose() {
    if (_isDisposed) return;
    
    _isDisposed = true;
    _cancelReconnect();
    _networkSubscription?.cancel();
  }
}
