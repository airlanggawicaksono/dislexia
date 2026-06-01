import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Shown right after a successful `GenerateAccountEvent` so the user
/// can copy their 16-digit account number to clipboard. The
/// auto-generated display name (e.g. "amusing-bee") is also surfaced.
class AccountNumberCard extends StatelessWidget {
  final String accountNumber;
  final String? displayName;

  const AccountNumberCard({
    super.key,
    required this.accountNumber,
    this.displayName,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.key, color: theme.colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Your new account number',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: SelectableText(
                    accountNumber,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontFamily: 'monospace',
                      letterSpacing: 2,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Copy',
                  icon: const Icon(Icons.copy, size: 18),
                  onPressed: () async {
                    await Clipboard.setData(
                      ClipboardData(text: accountNumber),
                    );
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Account number copied'),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'This is the only credential for your account. Save it '
            'somewhere safe — you will need it to log back in.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          if (displayName != null && displayName!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Display name: $displayName',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
