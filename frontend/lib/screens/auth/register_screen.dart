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

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();

    try {
      await authProvider.register(
        name: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text,
      );

      if (!mounted) return;
      // Auto-login succeeds -> navigate to home
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRouter.home,
        (route) => false,
      );
    } on AppException catch (e) {
      if (!mounted) return;
      AppSnackbar.error(context, e.message);
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.error(
        context,
        authProvider.error ?? 'Registration failed. Please try again.',
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
                  // Back arrow
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Symbols.arrow_back,
                      color: isDark ? AppColors.darkText : AppColors.lightText,
                    ),
                    padding: EdgeInsets.zero,
                    alignment: Alignment.centerLeft,
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Heading
                  Text(
                    'Create your account',
                    style: AppTypography.h1.copyWith(
                      color: isDark ? AppColors.darkText : AppColors.lightText,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // Subheading
                  Text(
                    'Start tracking your spending in seconds.',
                    style: AppTypography.body.copyWith(
                      color: secondaryTextColor,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxxl),

                  // Name input
                  AppTextField(
                    controller: _nameController,
                    label: 'Full name',
                    hint: 'Tayyab Alam',
                    prefixIcon: Symbols.person,
                    textInputAction: TextInputAction.next,
                    validator: Validators.name,
                  ),
                  const SizedBox(height: AppSpacing.lg),

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
                    hint: 'Create a password',
                    prefixIcon: Symbols.lock,
                    obscureText: _obscurePassword,
                    helperText: 'At least 8 characters',
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _handleRegister(),
                    validator: Validators.password,
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

                  // Create Account button
                  PrimaryButton(
                    label: 'Create Account',
                    isLoading: authProvider.isLoading,
                    onPressed: _handleRegister,
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Bottom navigation row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account?',
                        style: AppTypography.body.copyWith(
                          color: secondaryTextColor,
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          textStyle: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: const Text('Sign in'),
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
