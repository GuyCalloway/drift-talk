import 'package:flutter/material.dart';

import '../utils/logger.dart';
import 'exceptions.dart';
import 'failures.dart';

class ErrorHandler {
  static Failure handleException(dynamic exception) {
    AppLogger.error('Exception caught', exception);
    
    if (exception is NetworkException) {
      return NetworkFailure(exception.message, exception.code);
    } else if (exception is ServerException) {
      return ServerFailure(exception.message, exception.code, exception.statusCode);
    } else if (exception is AuthenticationException) {
      return AuthenticationFailure(exception.message, exception.code);
    } else if (exception is AudioException) {
      return AudioFailure(exception.message, exception.code);
    } else if (exception is WebSocketException) {
      return WebSocketFailure(exception.message, exception.code);
    } else if (exception is CacheException) {
      return CacheFailure(exception.message, exception.code);
    } else if (exception is PermissionException) {
      return PermissionFailure(exception.message, exception.code);
    } else if (exception is ValidationException) {
      return ValidationFailure(exception.message, exception.code, exception.errors);
    } else if (exception is TimeoutException) {
      return TimeoutFailure(exception.message, exception.code);
    } else {
      return UnknownFailure(exception.toString());
    }
  }

  static String getErrorMessage(Failure failure) {
    switch (failure.runtimeType) {
      case NetworkFailure:
        return 'Network connection error. Please check your internet connection and try again.';
      case ServerFailure:
        final serverFailure = failure as ServerFailure;
        if (serverFailure.statusCode != null) {
          return 'Server error (${serverFailure.statusCode}): ${failure.message}';
        }
        return 'Server error: ${failure.message}';
      case AuthenticationFailure:
        return 'Authentication failed. Please check your API key and try again.';
      case AudioFailure:
        return 'Audio processing error: ${failure.message}';
      case WebSocketFailure:
        return 'Connection error: ${failure.message}';
      case CacheFailure:
        return 'Local storage error: ${failure.message}';
      case PermissionFailure:
        return 'Permission required: ${failure.message}';
      case ValidationFailure:
        return 'Invalid input: ${failure.message}';
      case TimeoutFailure:
        return 'Request timed out: ${failure.message}';
      default:
        return failure.message.isNotEmpty 
            ? failure.message 
            : 'An unexpected error occurred. Please try again.';
    }
  }

  static Color getErrorColor(Failure failure, BuildContext context) {
    final theme = Theme.of(context);
    
    switch (failure.runtimeType) {
      case NetworkFailure:
      case WebSocketFailure:
        return Colors.orange;
      case AuthenticationFailure:
        return Colors.red;
      case PermissionFailure:
        return Colors.amber;
      case ValidationFailure:
        return Colors.blue;
      default:
        return theme.colorScheme.error;
    }
  }

  static IconData getErrorIcon(Failure failure) {
    switch (failure.runtimeType) {
      case NetworkFailure:
        return Icons.wifi_off;
      case ServerFailure:
        return Icons.cloud_off;
      case AuthenticationFailure:
        return Icons.lock;
      case AudioFailure:
        return Icons.mic_off;
      case WebSocketFailure:
        return Icons.link_off;
      case CacheFailure:
        return Icons.storage;
      case PermissionFailure:
        return Icons.security;
      case ValidationFailure:
        return Icons.warning;
      case TimeoutFailure:
        return Icons.timer_off;
      default:
        return Icons.error;
    }
  }

  static void showErrorSnackBar(
    BuildContext context,
    Failure failure, {
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              getErrorIcon(failure),
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                getErrorMessage(failure),
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: getErrorColor(failure, context),
        duration: duration,
        action: action,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  static void showErrorDialog(
    BuildContext context,
    Failure failure, {
    String? title,
    List<Widget>? actions,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: Icon(
          getErrorIcon(failure),
          color: getErrorColor(failure, context),
          size: 32,
        ),
        title: Text(title ?? 'Error'),
        content: Text(getErrorMessage(failure)),
        actions: actions ?? [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

class ErrorWidget extends StatelessWidget {
  final Failure failure;
  final VoidCallback? onRetry;
  final String? customMessage;

  const ErrorWidget({
    super.key,
    required this.failure,
    this.onRetry,
    this.customMessage,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              ErrorHandler.getErrorIcon(failure),
              size: 64,
              color: ErrorHandler.getErrorColor(failure, context),
            ),
            const SizedBox(height: 24),
            Text(
              'Oops! Something went wrong',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              customMessage ?? ErrorHandler.getErrorMessage(failure),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}