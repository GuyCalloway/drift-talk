import 'package:flutter/material.dart';

class MessageInputWidget extends StatefulWidget {
  final Function(String message, String? context) onSendMessage;
  final bool isLoading;
  final bool isConnected;

  const MessageInputWidget({
    super.key,
    required this.onSendMessage,
    required this.isLoading,
    required this.isConnected,
  });

  @override
  State<MessageInputWidget> createState() => _MessageInputWidgetState();
}

class _MessageInputWidgetState extends State<MessageInputWidget> {
  final TextEditingController _messageController = TextEditingController();
  final TextEditingController _contextController = TextEditingController();
  bool _hasText = false;
  bool _showContext = false;

  @override
  void initState() {
    super.initState();
    _messageController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _messageController.removeListener(_onTextChanged);
    _messageController.dispose();
    _contextController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = _messageController.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() {
        _hasText = hasText;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, -1),
            blurRadius: 8,
            color: Colors.black.withOpacity(0.08),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Context field (collapsible with animation)
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              height: _showContext ? null : 0,
              child: _showContext
                  ? Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: theme.colorScheme.primary.withOpacity(0.1),
                            ),
                          ),
                          child: TextField(
                            controller: _contextController,
                            maxLines: 2,
                            textCapitalization: TextCapitalization.sentences,
                            enabled: widget.isConnected && !widget.isLoading,
                            decoration: InputDecoration(
                              hintText: 'e.g., "Standing outside the British Museum"',
                              hintStyle: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface.withOpacity(0.5),
                              ),
                              prefixIcon: Icon(
                                Icons.location_on,
                                color: theme.colorScheme.primary,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.all(16),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
            
            // Main input container
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: _hasText
                      ? theme.colorScheme.primary.withOpacity(0.3)
                      : theme.colorScheme.outline.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  // Context toggle button
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: IconButton(
                      onPressed: () => setState(() => _showContext = !_showContext),
                      icon: AnimatedRotation(
                        turns: _showContext ? 0.5 : 0,
                        duration: const Duration(milliseconds: 300),
                        child: Icon(
                          Icons.add_circle_outline,
                          color: _showContext 
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface.withOpacity(0.6),
                          size: 24,
                        ),
                      ),
                      tooltip: _showContext ? 'Hide context' : 'Add location context',
                    ),
                  ),
                  
                  // Message input field
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      maxLines: null,
                      maxLength: 500,
                      textCapitalization: TextCapitalization.sentences,
                      enabled: widget.isConnected && !widget.isLoading,
                      style: theme.textTheme.bodyLarge,
                      decoration: InputDecoration(
                        hintText: widget.isConnected
                            ? 'Ask me anything...'
                            : 'Connecting...',
                        hintStyle: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 4,
                        ),
                        counterText: '',
                        suffixIcon: widget.isLoading
                            ? Padding(
                                padding: const EdgeInsets.all(12),
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              )
                            : null,
                      ),
                      onSubmitted: widget.isConnected && !widget.isLoading && _hasText
                          ? (value) => _sendMessage()
                          : null,
                    ),
                  ),

                  // Send button
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      child: IconButton(
                        onPressed: widget.isConnected && 
                                  !widget.isLoading && 
                                  _hasText
                            ? _sendMessage
                            : null,
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: widget.isConnected && 
                                    !widget.isLoading && 
                                    _hasText
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: widget.isLoading
                              ? SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: theme.colorScheme.onPrimary,
                                  ),
                                )
                              : Icon(
                                  Icons.send,
                                  size: 16,
                                  color: widget.isConnected && 
                                         !widget.isLoading && 
                                         _hasText
                                      ? theme.colorScheme.onPrimary
                                      : theme.colorScheme.onSurface.withOpacity(0.5),
                                ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Quick suggestions (when no messages)
            if (widget.isConnected && !widget.isLoading) ...[
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildQuickSuggestion(
                      context,
                      '🏛️ Tell me about museums',
                      'Tell me about this museum',
                    ),
                    const SizedBox(width: 8),
                    _buildQuickSuggestion(
                      context,
                      '🌉 Describe this bridge',
                      'What\'s interesting about this bridge?',
                    ),
                    const SizedBox(width: 8),
                    _buildQuickSuggestion(
                      context,
                      '📚 Local history',
                      'What\'s the history of this place?',
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuickSuggestion(BuildContext context, String label, String message) {
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap: () {
        _messageController.text = message;
        _hasText = true;
        setState(() {});
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.primary.withOpacity(0.2),
          ),
        ),
        child: Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  void _sendMessage() {
    final message = _messageController.text.trim();
    final context = _contextController.text.trim();
    
    if (message.isEmpty || !widget.isConnected || widget.isLoading) {
      return;
    }

    widget.onSendMessage(message, context.isEmpty ? null : context);

    // Clear inputs after sending
    _messageController.clear();
    _contextController.clear();
    _hasText = false;
    _showContext = false;
    setState(() {});
  }
}