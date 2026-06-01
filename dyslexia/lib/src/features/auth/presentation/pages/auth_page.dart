import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/auth/auth_bloc.dart';
import '../widgets/account_number_card.dart';
import '../widgets/auth_mode_switcher.dart';
import '../widgets/auth_text_field.dart';

enum AuthMode { login, generate }

/// Desktop auth page. Rendered in place of the main shell when the
/// user has no active session. The same widget handles both
/// \“log in with existing account number\“ and \“generate a new
/// account\“ via the [AuthModeSwitcher] tabs.
class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _accountController = TextEditingController();
  AuthMode _mode = AuthMode.login;

  @override
  void dispose() {
    _accountController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final bloc = context.read<AuthBloc>();
    switch (_mode) {
      case AuthMode.login:
        bloc.add(LoginEvent(_accountController.text));
        break;
      case AuthMode.generate:
        bloc.add(const GenerateAccountEvent());
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: BlocConsumer<AuthBloc, AuthState>(
            listenWhen: (prev, curr) =>
                curr is Unauthenticated && curr.errorMessage != null,
            listener: (context, state) {
              if (state is Unauthenticated && state.errorMessage != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(state.errorMessage!)),
                );
              }
            },
            builder: (context, state) {
              final unauth = state is Unauthenticated ? state : null;
              final isLoading = state is AuthLoading;

              if (unauth?.pendingAccountNumber != null) {
                // After generating an account, show the number and a button
                // to continue, simplifying the UI to prevent confusion.
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AccountNumberCard(
                      accountNumber: unauth!.pendingAccountNumber!,
                      displayName: unauth.pendingDisplayName,
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: isLoading
                          ? null
                          : () => context.read<AuthBloc>().add(
                                LoginEvent(unauth.pendingAccountNumber!),
                              ),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text(
                              'Continue to App',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ],
                );
              }

              // Default view for login or generate.
              return SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Dyslexia',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Sign in to your reading workspace',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: 32),
                      AuthModeSwitcher(
                        mode: _mode,
                        onChanged: (next) {
                          if (isLoading) return;
                          setState(() => _mode = next);
                        },
                      ),
                      const SizedBox(height: 24),
                      if (_mode == AuthMode.login) ...[
                        AuthTextField(
                          controller: _accountController,
                          label: '16-digit account number',
                          enabled: !isLoading,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(16),
                          ],
                          validator: (value) {
                            final v = (value ?? '').trim();
                            if (v.isEmpty) {
                              return 'Please enter your account number';
                            }
                            if (v.length != 16) {
                              return 'Account number must be 16 digits';
                            }
                            return null;
                          },
                        ),
                      ] else ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer
                                .withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'We will generate a 16-digit account '
                            'number for you. Save it — it is the only '
                            'way to log back in.',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: isLoading ? null : _submit,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                height: 18,
                                width: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                _mode == AuthMode.login
                                    ? 'Log in'
                                    : 'Generate account',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
