import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:provider/provider.dart';

import '../../config/theme/colors.dart';
import '../../config/theme/spacing.dart';
import '../../config/theme/typography.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../routes/app_router.dart';
import '../../utils/snackbar.dart';
import '../../utils/validators.dart';
import '../../widgets/common/primary_button.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameController = TextEditingController();
  bool _editing = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _nameController.text = user?.name ?? '';
  }

  Future<void> _saveName() async {
    if (Validators.name(_nameController.text) != null) {
      AppSnackbar.error(context, Validators.name(_nameController.text)!);
      return;
    }
    setState(() => _saving = true);
    try {
      await context
          .read<AuthProvider>()
          .updateProfile(name: _nameController.text.trim());
      if (mounted) setState(() => _editing = false);
    } catch (error) {
      if (mounted) AppSnackbar.error(context, error.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text("You'll need to sign in again."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Log out')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await context.read<AuthProvider>().logout();
    if (mounted)
      Navigator.pushNamedAndRemoveUntil(context, AppRouter.login, (_) => false);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final theme = context.watch<ThemeProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    final user = auth.user;
    final initials = (user?.name ?? 'U')
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .map((part) => part[0])
        .take(2)
        .join()
        .toUpperCase();

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(padding: const EdgeInsets.all(AppSpacing.xl), children: [
        Container(
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(AppRadius.lg)),
            child: Column(children: [
              CircleAvatar(
                  radius: 34,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                  child: Text(initials,
                      style:
                          AppTypography.h2.copyWith(color: AppColors.primary))),
              const SizedBox(height: AppSpacing.lg),
              if (_editing)
                TextFormField(
                    controller: _nameController,
                    validator: Validators.name,
                    textAlign: TextAlign.center,
                    style: AppTypography.h3.copyWith(color: textColor))
              else
                Text(user?.name ?? 'User',
                    style: AppTypography.h3.copyWith(color: textColor)),
              const SizedBox(height: AppSpacing.xs),
              Text(user?.email ?? '',
                  style: AppTypography.body.copyWith(color: secondary)),
              const SizedBox(height: AppSpacing.lg),
              if (_editing)
                PrimaryButton(
                    label: 'Save changes',
                    onPressed: _saveName,
                    isLoading: _saving)
              else
                TextButton.icon(
                    onPressed: () => setState(() => _editing = true),
                    icon: const Icon(Symbols.edit),
                    label: const Text('Edit profile')),
            ])),
        const SizedBox(height: AppSpacing.xxl),
        Text('Preferences', style: AppTypography.h3.copyWith(color: textColor)),
        const SizedBox(height: AppSpacing.sm),
        ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Symbols.dark_mode, color: secondary),
            title: Text('Dark theme',
                style: AppTypography.bodyMedium.copyWith(color: textColor)),
            trailing: Switch(
                value: theme.isDark, onChanged: (_) => theme.toggleTheme())),
        const SizedBox(height: AppSpacing.xxl),
        Text('Account', style: AppTypography.h3.copyWith(color: textColor)),
        const SizedBox(height: AppSpacing.sm),
        ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Symbols.logout, color: AppColors.expense),
            title: Text('Log out',
                style: AppTypography.bodyMedium
                    .copyWith(color: AppColors.expense)),
            onTap: _logout),
        const SizedBox(height: AppSpacing.xxl),
        Text('About', style: AppTypography.h3.copyWith(color: textColor)),
        const SizedBox(height: AppSpacing.sm),
        Text('SpendWise 1.0.0',
            style: AppTypography.body.copyWith(color: secondary)),
        const SizedBox(height: AppSpacing.xs),
        Text('Made by Tayyab Alam',
            style: AppTypography.caption.copyWith(color: secondary)),
      ]),
    );
  }
}
