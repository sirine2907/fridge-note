import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/pill_button.dart';
import '../../../../core/widgets/round_back_button.dart';
import '../../../lists/presentation/bloc/current_list_cubit.dart';
import '../cubit/invite_cubits.dart';

/// Opened from an invite link: /invite/:code
class JoinInvitePage extends StatelessWidget {
  const JoinInvitePage({super.key, required this.code});

  final String code;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => JoinCubit(previewInvite: sl(), joinList: sl())..load(code),
      child: const _JoinView(),
    );
  }
}

class _JoinView extends StatelessWidget {
  const _JoinView();

  void _close(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;

    return BlocConsumer<JoinCubit, JoinState>(
      listenWhen: (a, b) => b.status == JoinStatus.joined && a.status != JoinStatus.joined,
      listener: (context, state) {
        sl<CurrentListCubit>().select(state.listId!);
        context.go('/list');
      },
      builder: (context, state) {
        final preview = state.preview;

        Widget body;
        if (state.status == JoinStatus.loading) {
          body = Center(child: CircularProgressIndicator(color: c.primary));
        } else if (preview == null) {
          body = EmptyState(
            message: state.error ?? 'This invite link does not work any more. Ask for a new one.',
          );
        } else {
          body = SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Column(
              children: [
                Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(color: c.primarySoft, shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: const FridgeIllustration(size: 170),
                ),
                const SizedBox(height: 28),
                Text(
                  '${preview.inviterName} invited you to',
                  style: text.bodyLarge?.copyWith(color: c.muted),
                ),
                const SizedBox(height: 4),
                Text(preview.listName, style: text.headlineMedium, textAlign: TextAlign.center),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    _Pill(icon: Icons.receipt_long_rounded, label: plural(preview.itemCount, 'item')),
                    _Pill(icon: Icons.group_rounded, label: plural(preview.memberCount, 'member')),
                  ],
                ),
                if (state.error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(state.error!, style: text.bodyMedium?.copyWith(color: AppColors.red)),
                  ),
                const SizedBox(height: 32),
                PillButton(
                  label: preview.alreadyMember ? 'Open list' : 'Join list',
                  icon: preview.alreadyMember ? Icons.arrow_forward_rounded : Icons.group_add_rounded,
                  loading: state.status == JoinStatus.joining,
                  onPressed: () => context.read<JoinCubit>().join(),
                ),
                if (preview.alreadyMember)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text('You are already on this list.', style: text.bodySmall),
                  ),
              ],
            ),
          );
        }

        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: RoundBackButton(onPressed: () => _close(context)),
                  ),
                ),
                Expanded(child: body),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: c.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: c.primary),
          const SizedBox(width: 6),
          Text(label, style: Theme.of(context).textTheme.labelMedium),
        ],
      ),
    );
  }
}
