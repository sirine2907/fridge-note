import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/pill_button.dart';
import '../cubit/session_cubit.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key, this.next});

  /// Where to go after signing in, e.g. an invite link.
  final String? next;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AppLogo(),
                    const SizedBox(height: 28),
                    Center(
                      child: Container(
                        width: 270,
                        height: 270,
                        decoration: BoxDecoration(color: c.primarySoft, shape: BoxShape.circle),
                        alignment: Alignment.center,
                        child: const FridgeIllustration(size: 210),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text('One list for\nthe whole home.', style: text.headlineLarge),
                    const SizedBox(height: 12),
                    Text(
                      'Add things from anywhere and watch them get ticked off while someone is in the shop. Works offline too.',
                      style: text.bodyLarge?.copyWith(color: c.muted),
                    ),
                    const SizedBox(height: 32),
                    BlocBuilder<SessionCubit, SessionState>(
                      builder: (context, session) => Column(
                        children: [
                          if (session.error != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Text(session.error!, style: text.bodyMedium?.copyWith(color: AppColors.red)),
                            ),
                          PillButton(
                            label: 'Continue with email',
                            icon: Icons.mail_rounded,
                            onPressed: session.busy
                                ? null
                                : () => context.push(
                                      next == null ? '/sign-in' : '/sign-in?next=${Uri.encodeComponent(next!)}',
                                    ),
                          ),
                          const SizedBox(height: 12),
                          PillButton(
                            label: 'Try demo',
                            icon: Icons.play_arrow_rounded,
                            style: PillStyle.soft,
                            loading: session.busy,
                            onPressed: () => context.read<SessionCubit>().startDemo(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        'The demo runs on this device only. Nothing is uploaded.',
                        textAlign: TextAlign.center,
                        style: text.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Little violet note icon plus the app name.
class AppLogo extends StatelessWidget {
  const AppLogo({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: c.primary, borderRadius: BorderRadius.circular(14)),
          child: const Icon(Icons.sticky_note_2_rounded, color: Colors.white, size: 22),
        ),
        const SizedBox(width: 10),
        Text('fridge-note', style: Theme.of(context).textTheme.titleLarge),
      ],
    );
  }
}
