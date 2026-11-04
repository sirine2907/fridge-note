import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/phone_frame.dart';
import 'features/auth/presentation/cubit/session_cubit.dart';
import 'features/profile/domain/repositories/profile_repository.dart';
import 'features/profile/presentation/cubit/theme_cubit.dart';

class FridgeNoteApp extends StatefulWidget {
  const FridgeNoteApp({
    super.key,
    required this.session,
    required this.theme,
    this.initialLocation,
  });

  final SessionCubit session;
  final ThemeCubit theme;
  final String? initialLocation;

  @override
  State<FridgeNoteApp> createState() => _FridgeNoteAppState();
}

class _FridgeNoteAppState extends State<FridgeNoteApp> {
  late final GoRouter _router = buildRouter(widget.session, initialLocation: widget.initialLocation);

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: widget.session),
        BlocProvider.value(value: widget.theme),
      ],
      child: BlocBuilder<ThemeCubit, AppThemeMode>(
        builder: (context, _) => MaterialApp.router(
          title: 'fridge-note',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: context.read<ThemeCubit>().themeMode,
          routerConfig: _router,
          builder: (context, child) => PhoneFrame(child: child!),
        ),
      ),
    );
  }
}
