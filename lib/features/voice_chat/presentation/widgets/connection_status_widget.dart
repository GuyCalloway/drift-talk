import 'package:flutter/material.dart';

import '../../domain/repositories/voice_chat_repository.dart';

class ConnectionStatusWidget extends StatelessWidget {
  final ConnectionStatus connectionStatus;
  final VoidCallback onToggleConnection;

  const ConnectionStatusWidget({
    super.key,
    required this.connectionStatus,
    required this.onToggleConnection,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return IconButton(
      onPressed: onToggleConnection,
      icon: _buildStatusIcon(theme),
      tooltip: _getStatusTooltip(),
    );
  }

  Widget _buildStatusIcon(ThemeData theme) {
    switch (connectionStatus) {
      case ConnectionStatus.connected:
        return Icon(
          Icons.cloud_done,
          color: Colors.green,
        );
      case ConnectionStatus.connecting:
        return SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: theme.colorScheme.onPrimary,
          ),
        );
      case ConnectionStatus.reconnecting:
        return SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.orange,
          ),
        );
      case ConnectionStatus.error:
        return Icon(
          Icons.cloud_off,
          color: theme.colorScheme.error,
        );
      case ConnectionStatus.disconnected:
        return Icon(
          Icons.cloud_off,
          color: Colors.grey,
        );
    }
  }

  String _getStatusTooltip() {
    switch (connectionStatus) {
      case ConnectionStatus.connected:
        return 'Connected - Tap to disconnect';
      case ConnectionStatus.connecting:
        return 'Connecting...';
      case ConnectionStatus.reconnecting:
        return 'Reconnecting...';
      case ConnectionStatus.error:
        return 'Connection error - Tap to retry';
      case ConnectionStatus.disconnected:
        return 'Disconnected - Tap to connect';
    }
  }
}