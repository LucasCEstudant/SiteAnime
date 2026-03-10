import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../api/api_exception.dart';

/// Reusable error view with icon, message, and retry button.
/// Replaces duplicated `_ErrorView` across multiple pages.
class ErrorView extends StatelessWidget {
  const ErrorView({
    super.key,
    required this.error,
    required this.onRetry,
    this.fallbackMessage,
  });

  /// The error object — if [ApiException], its message is shown,
  /// otherwise [fallbackMessage] is displayed.
  final Object error;

  /// Called when the user taps the retry button.
  final VoidCallback onRetry;

  /// Message shown when [error] is not an [ApiException].
  final String? fallbackMessage;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final message = error is ApiException
        ? (error as ApiException).message
        : fallbackMessage ?? l10n.unexpectedErrorFallback;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(l10n.tryAgain),
            ),
          ],
        ),
      ),
    );
  }
}
