import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';
import 'routing/app_router.dart';

class LeadProspectsApp extends StatelessWidget {
  const LeadProspectsApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authCubit = context.read<AuthCubit>();
    final router = createRouter(authCubit);

    return MaterialApp.router(
      title: 'Matrix - Lead & Prospects',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
    );
  }
}
