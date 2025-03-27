import 'package:flutter/material.dart';

import '../client/flutter_mcp_client.dart' as client_lib;

/// Style configuration for the status widget
class FlutterMcpStatusStyle {
  /// Color for connected state
  final Color connectedColor;
  
  /// Color for disconnected state
  final Color disconnectedColor;
  
  /// Color for connecting state
  final Color connectingColor;
  
  /// Color for error state
  final Color errorColor;
  
  /// Color for paused state
  final Color pausedColor;
  
  /// Text style for status text
  final TextStyle? textStyle;
  
  /// Icon size
  final double iconSize;
  
  /// Create status widget style
  const FlutterMcpStatusStyle({
    this.connectedColor = Colors.green,
    this.disconnectedColor = Colors.red,
    this.connectingColor = Colors.orange,
    this.errorColor = Colors.red,
    this.pausedColor = Colors.grey,
    this.textStyle,
    this.iconSize = 16.0,
  });
}

/// Widget displaying MCP client connection status
class FlutterMcpStatusWidget extends StatefulWidget {
  /// Client to monitor
  final client_lib.FlutterMcpClient client;
  
  /// Whether to show connection controls
  final bool showConnectionControls;
  
  /// Style configuration
  final FlutterMcpStatusStyle? style;
  
  /// Whether to show server information
  final bool showServerInfo;
  
  /// Create a status widget
  const FlutterMcpStatusWidget({
    Key? key,
    required this.client,
    this.showConnectionControls = true,
    this.style,
    this.showServerInfo = true,
  }) : super(key: key);

  @override
  State<FlutterMcpStatusWidget> createState() => _FlutterMcpStatusWidgetState();
}

class _FlutterMcpStatusWidgetState extends State<FlutterMcpStatusWidget> {
  /// Current connection state
  client_lib.ConnectionState _connectionState = client_lib.ConnectionState.disconnected;

  @override
  void initState() {
    super.initState();
    
    // Initialize state
    _connectionState = widget.client.connectionState;
    
    // Listen for connection state changes
    widget.client.connectionStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _connectionState = state;
        });
      }
    });
  }

  /// Get color for current connection state
  Color _getColorForState(FlutterMcpStatusStyle style) {
    switch (_connectionState) {
      case client_lib.ConnectionState.connected:
        return style.connectedColor;
      case client_lib.ConnectionState.disconnected:
        return style.disconnectedColor;
      case client_lib.ConnectionState.connecting:
        return style.connectingColor;
      case client_lib.ConnectionState.error:
        return style.errorColor;
      case client_lib.ConnectionState.paused:
        return style.pausedColor;
    }
  }

  /// Get icon for current connection state
  IconData _getIconForState() {
    switch (_connectionState) {
      case client_lib.ConnectionState.connected:
        return Icons.check_circle;
      case client_lib.ConnectionState.disconnected:
        return Icons.cancel;
      case client_lib.ConnectionState.connecting:
        return Icons.sync;
      case client_lib.ConnectionState.error:
        return Icons.error;
      case client_lib.ConnectionState.paused:
        return Icons.pause_circle_filled;
    }
  }

  /// Get text for current connection state
  String _getTextForState() {
    switch (_connectionState) {
      case client_lib.ConnectionState.connected:
        return 'Connected';
      case client_lib.ConnectionState.disconnected:
        return 'Disconnected';
      case client_lib.ConnectionState.connecting:
        return 'Connecting...';
      case client_lib.ConnectionState.error:
        return 'Connection Error';
      case client_lib.ConnectionState.paused:
        return 'Paused';
    }
  }
  
  /// Connect to server
  Future<void> _connect() async {
    try {
      final transport = widget.client.getTransport();
      if (transport != null) {
        await widget.client.connect(transport);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No transport available')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Connection error: $e')),
      );
    }
  }
  
  /// Disconnect from server
  Future<void> _disconnect() async {
    try {
      await widget.client.disconnect();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Disconnection error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = widget.style ?? const FlutterMcpStatusStyle();
    final stateColor = _getColorForState(style);
    final stateIcon = _getIconForState();
    final stateText = _getTextForState();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status indicator
            Row(
              children: [
                Icon(
                  stateIcon,
                  color: stateColor,
                  size: style.iconSize,
                ),
                const SizedBox(width: 8),
                Text(
                  stateText,
                  style: style.textStyle?.copyWith(color: stateColor) ??
                      TextStyle(
                        fontWeight: FontWeight.bold,
                        color: stateColor,
                      ),
                ),
              ],
            ),
            
            // Server info
            if (widget.showServerInfo && widget.client.serverInfo != null) ...[
              const SizedBox(height: 8),
              Text(
                'Server: ${widget.client.serverInfo!['name']} ${widget.client.serverInfo!['version']}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              
              // Display available capabilities
              if (widget.client.serverCapabilities != null) ...[
                const SizedBox(height: 4),
                Wrap(
                  spacing: 4,
                  children: [
                    if (widget.client.serverCapabilities!.tools)
                      const Chip(
                        label: Text('Tools'),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                    if (widget.client.serverCapabilities!.resources)
                      const Chip(
                        label: Text('Resources'),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                    if (widget.client.serverCapabilities!.prompts)
                      const Chip(
                        label: Text('Prompts'),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                    if (widget.client.serverCapabilities!.sampling)
                      const Chip(
                        label: Text('Sampling'),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),
              ],
            ],
            
            // Connection controls
            if (widget.showConnectionControls) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (_connectionState == client_lib.ConnectionState.disconnected ||
                      _connectionState == client_lib.ConnectionState.error)
                    ElevatedButton(
                      onPressed: _connect,
                      child: const Text('Connect'),
                    ),
                  if (_connectionState == client_lib.ConnectionState.connected ||
                      _connectionState == client_lib.ConnectionState.paused)
                    ElevatedButton(
                      onPressed: _disconnect,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      child: const Text('Disconnect'),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
