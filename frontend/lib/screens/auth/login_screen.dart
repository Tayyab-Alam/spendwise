import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../config/theme/colors.dart';
import '../../config/theme/spacing.dart';
import '../../config/theme/typography.dart';
import '../../core/errors/app_exception.dart';
import '../../providers/auth_provider.dart';
import '../../routes/app_router.dart';
import '../../utils/snackbar.dart';
import '../../utils/validators.dart';
import '../../widgets/common/primary_button.dart';
import '../../widgets/inputs/app_text_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();

    try {
      await authProvider.login(
        email: _emailController.text,
        password: _passwordController.text,
      );

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppRouter.home);
    } on AppException catch (e) {
      if (!mounted) return;
      AppSnackbar.error(context, e.message);
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.error(
        context,
        authProvider.error ?? 'An unexpected error occurred. Please try again.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final authProvider = context.watch<AuthProvider>();

    final secondaryTextColor = isDark
        ? AppColors.darkTextSecondary
        : AppColors.lightTextSecondary;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBg : AppColors.lightBg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppSpacing.xxl),

                  // Brand name
                  Text(
                    'SpendWise',
                    style: AppTypography.h2.copyWith(
                      color: AppColors.primary,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),

                  // Heading
                  Text(
                    'Welcome back',
                    style: AppTypography.h1.copyWith(
                      color: isDark ? AppColors.darkText : AppColors.lightText,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // Subheading
                  Text(
                    'Sign in to continue managing your money.',
                    style: AppTypography.body.copyWith(
                      color: secondaryTextColor,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxxl),

                  // Email input
                  AppTextField(
                    controller: _emailController,
                    label: 'Email',
                    hint: 'name@example.com',
                    prefixIcon: Symbols.mail,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    validator: Validators.email,
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Password input
                  AppTextField(
                    controller: _passwordController,
                    label: 'Password',
                    hint: 'Enter your password',
                    prefixIcon: Symbols.lock,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _handleLogin(),
                    validator: (val) => Validators.required(val, 'Password'),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Symbols.visibility : Symbols.visibility_off,
                        color: secondaryTextColor.withValues(alpha: 0.7),
                        size: 20,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Sign In button
                  PrimaryButton(
                    label: 'Sign In',
                    isLoading: authProvider.isLoading,
                    onPressed: _handleLogin,
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Bottom navigation row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account?",
                        style: AppTypography.body.copyWith(
                          color: secondaryTextColor,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, AppRouter.register);
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          textStyle: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: const Text('Create one'),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
