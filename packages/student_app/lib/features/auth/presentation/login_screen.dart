import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/kiz_theme.dart';
import '../application/auth_provider.dart';

/// Login screen for student authentication.
///
/// Provides matric number and password fields with KIZ branding.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _matricController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _matricController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    await ref.read(authProvider.notifier).login(
          identifier: _matricController.text.trim(),
          password: _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState.status == AuthStatus.loading;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: KizSpacing.xl,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // App branding
                  Text(
                    'MyKIZ Siswa',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.leagueSpartan(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: KizColors.onBackground,
                    ),
                  ),
                  const SizedBox(height: KizSpacing.sm),
                  Text(
                    'Student Portal',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: KizColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: KizSpacing.xxl + KizSpacing.base),

                  // Error message
                  if (authState.errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(KizSpacing.md),
                      decoration: BoxDecoration(
                        color: KizColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(KizRadius.input),
                        border: Border.all(color: KizColors.error),
                      ),
                      child: Text(
                        authState.errorMessage!,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: KizColors.error,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: KizSpacing.base),
                  ],

                  // Matric Number field
                  TextFormField(
                    controller: _matricController,
                    enabled: !isLoading,
                    decoration: const InputDecoration(
                      labelText: 'Matric Number',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your matric number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: KizSpacing.base),

                  // Password field
                  TextFormField(
                    controller: _passwordController,
                    enabled: !isLoading,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
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
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _handleLogin(),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: KizSpacing.xl),

                  // Login button
                  SizedBox(
                    height: kMinTouchTarget,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _handleLogin,
                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: KizColors.onBackground,
                              ),
                            )
                          : const Text('Login'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
