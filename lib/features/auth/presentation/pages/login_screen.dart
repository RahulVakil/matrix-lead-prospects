import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/enums/user_role.dart';
import '../cubit/auth_cubit.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.navyDark,
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.surfacePrimary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Center(
                  child: Text(
                    'JM',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: AppColors.navyPrimary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Matrix Lead & Prospects',
                style: AppTextStyles.heading1.copyWith(color: AppColors.textOnDark),
              ),
              const SizedBox(height: 8),
              Text(
                'Select a role to continue',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textOnDark.withValues(alpha: 0.7)),
              ),
              const SizedBox(height: 40),
              _roleButton(context, UserRole.rm, 'Relationship Manager', Icons.person),
              const SizedBox(height: 12),
              _roleButton(context, UserRole.teamLead, 'Team Lead', Icons.group),
              const SizedBox(height: 12),
              _roleButton(context, UserRole.checker, 'Checker', Icons.verified_user),
              const SizedBox(height: 12),
              _roleButton(context, UserRole.admin, 'Admin / MIS', Icons.admin_panel_settings),
            ],
          ),
        ),
      ),
    );
  }

  Widget _roleButton(BuildContext context, UserRole role, String label, IconData icon) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: () => context.read<AuthCubit>().login(role),
        icon: Icon(icon, size: 20),
        label: Text(label, style: AppTextStyles.labelLarge.copyWith(color: AppColors.navyPrimary)),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.surfacePrimary,
          foregroundColor: AppColors.navyPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
          elevation: 0,
        ),
      ),
    );
  }
}
