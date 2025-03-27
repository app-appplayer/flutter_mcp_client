import 'package:flutter/material.dart';
import 'package:mcp_client/mcp_client.dart';

import '../client/flutter_mcp_client.dart';

/// Widget for displaying and executing MCP tools
class FlutterMcpToolsWidget extends StatefulWidget {
  /// Client to use for tool operations
  final FlutterMcpClient client;
  
  /// Custom theme data for widget styling
  final ThemeData? customTheme;
  
  /// Optional filter for tools
  final bool Function(Tool)? filter;
  
  /// Whether to show tool execution UI
  final bool showExecutionUI;
  
  /// Optional title for the widget
  final String? title;
  
  /// Create a tools widget
  const FlutterMcpToolsWidget({
    Key? key,
    required this.client,
    this.customTheme,
    this.filter,
    this.showExecutionUI = true,
    this.title,
  }) : super(key: key);

  @override
  State<FlutterMcpToolsWidget> createState() => _FlutterMcpToolsWidgetState();
}

class _FlutterMcpToolsWidgetState extends State<FlutterMcpToolsWidget> {
  /// List of available tools
  List<Tool> _tools = [];
  
  /// Currently selected tool
  Tool? _selectedTool;
  
  /// Tool argument values
  final Map<String, dynamic> _toolArguments = {};
  
  /// Whether tool execution is in progress
  bool _isExecuting = false;
  
  /// Tool execution result
  CallToolResult? _result;
  
  /// Tool execution error
  String? _error;
  
  @override
  void initState() {
    super.initState();
    _loadTools();
    
    // Listen for tool list changes
    widget.client.onToolsListChanged(() {
      _loadTools();
    });
  }

  /// Load tools from the server
  Future<void> _loadTools() async {
    if (!widget.client.isConnected) {
      setState(() {
        _tools = [];
        _selectedTool = null;
      });
      return;
    }
    
    try {
      final tools = await widget.client.listTools();
      
      // Apply filter if provided
      final filteredTools = widget.filter != null
          ? tools.where(widget.filter!).toList()
          : tools;
      
      setState(() {
        _tools = filteredTools;
        _selectedTool = null;
        _toolArguments.clear();
      });
    } catch (e) {
      setState(() {
        _tools = [];
        _selectedTool = null;
        _error = e.toString();
      });
    }
  }
  
  /// Select a tool and initialize arguments
  void _selectTool(Tool tool) {
    setState(() {
      _selectedTool = tool;
      _toolArguments.clear();
      _result = null;
      _error = null;
    });
  }
  
  /// Update an argument value
  void _updateArgument(String name, dynamic value) {
    setState(() {
      _toolArguments[name] = value;
    });
  }
  
  /// Execute the selected tool
  Future<void> _executeTool() async {
    if (_selectedTool == null) {
      return;
    }
    
    setState(() {
      _isExecuting = true;
      _result = null;
      _error = null;
    });
    
    try {
      final result = await widget.client.callTool(
        _selectedTool!.name,
        Map.from(_toolArguments),
      );
      
      setState(() {
        _result = result;
        _isExecuting = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isExecuting = false;
      });
    }
  }
  
  /// Build a form field for a schema property
  Widget _buildFieldForProperty(String name, Map<String, dynamic> property) {
    final type = property['type'] as String?;
    final description = property['description'] as String?;
    final isRequired = (_selectedTool?.inputSchema['required'] as List<dynamic>?)?.contains(name) ?? false;
    
    // Handle different property types
    switch (type) {
      case 'string':
        return TextFormField(
          decoration: InputDecoration(
            labelText: '$name${isRequired ? ' *' : ''}',
            helperText: description,
          ),
          onChanged: (value) => _updateArgument(name, value),
        );
      
      case 'number':
      case 'integer':
        return TextFormField(
          decoration: InputDecoration(
            labelText: '$name${isRequired ? ' *' : ''}',
            helperText: description,
          ),
          keyboardType: TextInputType.number,
          onChanged: (value) {
            final num? parsedValue = type == 'integer' 
                ? int.tryParse(value)
                : double.tryParse(value);
            if (parsedValue != null) {
              _updateArgument(name, parsedValue);
            }
          },
        );
      
      case 'boolean':
        return SwitchListTile(
          title: Text('$name${isRequired ? ' *' : ''}'),
          subtitle: description != null ? Text(description) : null,
          value: _toolArguments[name] as bool? ?? false,
          onChanged: (value) => _updateArgument(name, value),
        );
      
      case 'array':
        // TODO: Implement array input
        return ListTile(
          title: Text('$name${isRequired ? ' *' : ''}'),
          subtitle: const Text('Array input not yet supported'),
        );
      
      case 'object':
        // TODO: Implement object input
        return ListTile(
          title: Text('$name${isRequired ? ' *' : ''}'),
          subtitle: const Text('Object input not yet supported'),
        );
      
      default:
        return TextFormField(
          decoration: InputDecoration(
            labelText: '$name${isRequired ? ' *' : ''}',
            helperText: description,
          ),
          onChanged: (value) => _updateArgument(name, value),
        );
    }
  }
  
  /// Build the tool selection UI
  Widget _buildToolSelection() {
    if (_tools.isEmpty) {
      return Center(
        child: _error != null
            ? Text('Error: $_error', style: const TextStyle(color: Colors.red))
            : const Text('No tools available'),
      );
    }
    
    return ListView.builder(
      itemCount: _tools.length,
      itemBuilder: (context, index) {
        final tool = _tools[index];
        return ListTile(
          title: Text(tool.name),
          subtitle: Text(tool.description),
          selected: _selectedTool?.name == tool.name,
          onTap: () => _selectTool(tool),
        );
      },
    );
  }
  
  /// Build the tool execution UI
  Widget _buildToolExecution() {
    if (_selectedTool == null) {
      return const Center(
        child: Text('Select a tool to execute'),
      );
    }
    
    final properties = _selectedTool!.inputSchema['properties'] as Map<String, dynamic>?;
    
    if (properties == null || properties.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Tool does not require any parameters'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isExecuting ? null : _executeTool,
              child: _isExecuting
                  ? const CircularProgressIndicator()
                  : const Text('Execute'),
            ),
          ],
        ),
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            _selectedTool!.name,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Text(
            _selectedTool!.description,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        const Divider(),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              ...properties.entries.map((entry) => _buildFieldForProperty(entry.key, entry.value)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isExecuting ? null : _executeTool,
                child: _isExecuting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Execute'),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(
                  'Error: $_error',
                  style: const TextStyle(color: Colors.red),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
  
  /// Build the result display UI
  Widget _buildResultDisplay() {
    if (_result == null) {
      return const Center(
        child: Text('No results to display'),
      );
    }
    
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        if (_result!.isError == true)
          const Text(
            'Tool execution error:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
        ..._result!.content.map((content) {
          if (content is TextContent) {
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(content.text),
              ),
            );
          } else {
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Unsupported content type: ${content.runtimeType}'),
              ),
            );
          }
        }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.customTheme ?? Theme.of(context);
    
    return Theme(
      data: theme,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.title ?? 'MCP Tools'),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadTools,
              tooltip: 'Refresh tools',
            ),
          ],
        ),
        body: !widget.client.isConnected
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Client is not connected'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadTools,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
            : DefaultTabController(
                length: widget.showExecutionUI && _selectedTool != null ? (_result != null ? 3 : 2) : 1,
                child: Column(
                  children: [
                    if (widget.showExecutionUI && _selectedTool != null)
                      TabBar(
                        tabs: [
                          const Tab(text: 'Tools'),
                          const Tab(text: 'Execute'),
                          if (_result != null)
                            const Tab(text: 'Result'),
                        ],
                      ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _buildToolSelection(),
                          if (widget.showExecutionUI && _selectedTool != null)
                            _buildToolExecution(),
                          if (widget.showExecutionUI && _selectedTool != null && _result != null)
                            _buildResultDisplay(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
