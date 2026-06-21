import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/auth/auth_bloc.dart';

/// Tiny user menu for the desktop shell. Renders an avatar bubble
/// with the first letter of the user's display name; tapping it
/// opens a menu with the display name + a log out action.
///
/// Lives inside the shell, which is wrapped in [BlocProvider] for
/// [AuthBloc] by `main.dart`, so the `context.read<AuthBloc>()` call
/// below resolves correctly.
class AuthUserMenu extends StatelessWidget {
  const AuthUserMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      buildWhen: (prev, curr) => curr is Authenticated,
      builder: (context, state) {
        if (state is! Authenticated) return const SizedBox.shrink();
        final user = state.session.user;
        final initial = user.displayName.isNotEmpty
            ? user.displayName.substring(0, 1).toUpperCase()
            : '?';
        return PopupMenuButton<String>(
          tooltip: 'Account',
          offset: const Offset(0, 40),
          icon: CircleAvatar(
            radius: 16,
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: Text(
              initial,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          onSelected: (value) {
            if (value == 'logout') {
              context.read<AuthBloc>().add(const LogoutEvent());
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              enabled: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.displayName.isEmpty ? 'Account' : user.displayName,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  if (user.accountNumber.isNotEmpty)
                    Row(
                      children: [
                        Text(
                          '#${user.accountNumber}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.6),
                              ),
                        ),
                        const SizedBox(width: 4),
                        InkWell(
                          onTap: () async {
                            await Clipboard.setData(
                              ClipboardData(text: user.accountNumber),
                            );
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Account number copied'),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(4),
                          child: Padding(
                            padding: const EdgeInsets.all(2),
                            child: Icon(
                              Icons.copy_rounded,
                              size: 18,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.8),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'logout',
              child: Row(
                children: [
                  Icon(Icons.logout, size: 18),
                  SizedBox(width: 8),
                  Text('Log out'),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
