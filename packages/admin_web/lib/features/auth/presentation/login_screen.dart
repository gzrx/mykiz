import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/kiz_theme.dart';
import '../application/auth_provider.dart';

/// Login screen for Admin Web authentication.
///
/// Provides Staff ID and password fields with KIZ branding.
/// On successful login, the GoRouter redirect guard navigates to the dashboard.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  static const _demoAccounts = <({String id, String name})>[
    (id: 'S98765', name: 'Dr. Aminah'),
    (id: 'S87654', name: 'Encik Razak'),
  ];

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    await ref.read(authProvider.notifier).login(
          identifier: _identifierController.text.trim(),
          password: _passwordController.text,
        );
  }

  void _fillDemo(String id) {
    _identifierController.text = id;
    _passwordController.text = 'password123';
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final theme = Theme.of(context);
    final isLoading = authState.status == AuthStatus.loading;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(KizSpacing.xl),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // KIZ Branding - Logo placeholder
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: KizColors.primary,
                    borderRadius: BorderRadius.circular(KizRadius.card),
                  ),
                  child: const Icon(
                    Icons.apartment_rounded,
                    size: 48,
                    color: KizColors.onBackground,
                  ),
                ),
                const SizedBox(height: KizSpacing.base),

                // App title
                Text(
                  'MyKIZ Admin',
                  style: KizFonts.display(fontSize: 32),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: KizSpacing.sm),

                // Subtitle
                Text(
                  'Kolej Ibu Zain Management Portal',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: KizColors.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: KizSpacing.xxl),

                // Login form
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Staff ID field
                      TextFormField(
                        key: const Key('staffField'),
                        controller: _identifierController,
                        decoration: const InputDecoration(
                          labelText: 'Staff ID',
                          hintText: 'Enter your Staff ID',
                          prefixIcon: Icon(Icons.badge_outlined),
                        ),
                        textInputAction: TextInputAction.next,
                        enabled: !isLoading,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your Staff ID';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: KizSpacing.base),

                      // Password field
                      TextFormField(
                        key: const Key('passwordField'),
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          hintText: 'Enter your password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        enabled: !isLoading,
                        onFieldSubmitted: (_) => _handleLogin(),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: KizSpacing.xl),

                      // Error message
                      if (authState.errorMessage != null) ...[
                        Container(
                          padding: const EdgeInsets.all(KizSpacing.md),
                          decoration: BoxDecoration(
                            color: KizColors.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: KizColors.error.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: KizColors.error,
                                size: 20,
                              ),
                              const SizedBox(width: KizSpacing.sm),
                              Expanded(
                                child: Text(
                                  authState.errorMessage!,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: KizColors.error,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: KizSpacing.base),
                      ],

                      // Login button
                      SizedBox(
                        height: KizTheme.minTouchTarget,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _handleLogin,
                          child: isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: KizColors.onBackground,
                                  ),
                                )
                              : const Text('Sign In'),
                        ),
                      ),
                      const SizedBox(height: KizSpacing.sm),
                      Align(
                        alignment: Alignment.center,
                        child: PopupMenuButton<String>(
                          tooltip: 'Fill demo credentials',
                          onSelected: _fillDemo,
                          itemBuilder: (context) => [
                            for (final a in _demoAccounts)
                              PopupMenuItem(
                                value: a.id,
                                child: Text('${a.id} — ${a.name}'),
                              ),
                          ],
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.science_outlined, size: 16),
                              SizedBox(width: 4),
                              Text('Demo'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
