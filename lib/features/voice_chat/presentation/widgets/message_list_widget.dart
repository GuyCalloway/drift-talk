import 'package:flutter/material.dart';

import '../../domain/entities/voice_message.dart';
import 'message_bubble_widget.dart';

class MessageListWidget extends StatefulWidget {
  final List<VoiceMessage> messages;

  const MessageListWidget({
    super.key,
    required this.messages,
  });

  @override
  State<MessageListWidget> createState() => _MessageListWidgetState();
}

class _MessageListWidgetState extends State<MessageListWidget> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(MessageListWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Auto-scroll to bottom when new messages arrive
    if (widget.messages.length != oldWidget.messages.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Start a conversation',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Type a message below to begin chatting with the AI assistant',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: widget.messages.length,
      itemBuilder: (context, index) {
        final message = widget.messages[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: MessageBubbleWidget(
            message: message,
            showAvatar: _shouldShowAvatar(index),
          ),
        );
      },
    );
  }

  bool _shouldShowAvatar(int index) {
    if (index == 0) return true;
    
    final currentMessage = widget.messages[index];
    final previousMessage = widget.messages[index - 1];
    
    // Show avatar if message type changed or if there's a significant time gap
    return currentMessage.type != previousMessage.type ||
           currentMessage.timestamp.difference(previousMessage.timestamp).inMinutes > 5;
  }
}