import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/demo/demo_partner.dart';
import '../../../../core/demo/fake_remote.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/avatar.dart';
import '../../../../core/widgets/page_header.dart';
import '../../../../core/widgets/pill_button.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../auth/presentation/cubit/session_cubit.dart';
import '../../../lists/domain/entities/member.dart';
import '../../domain/repositories/profile_repository.dart';
import '../cubit/profile_cubit.dart';
import '../cubit/theme_cubit.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = sl<AppUser>();
    return BlocProvider(
      create: (_) => ProfileCubit(userId: user.id, watchProfile: sl(), updateProfile: sl()),
      child: BlocListener<ProfileCubit, Member?>(
        // Keep the name on the home screen up to date.
        listener: (context, member) {
          if (member != null) {
            context.read<SessionCubit>().profileChanged(name: member.name, color: member.color);
          }
        },
        child: _ProfileView(user: user),
      ),
    );
  }
}

class _ProfileView extends StatelessWidget {
  const _ProfileView({required this.user});

  final AppUser user;

  Future<void> _rename(BuildContext context, String current) async {
    final cubit = context.read<ProfileCubit>();
    final controller = TextEditingController(text: current);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.colors.screen,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Text('Your name'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          onSubmitted: (value) => Navigator.pop(context, value),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Save')),
        ],
      ),
    );
    controller.dispose();
    if (name != null && name.trim().isNotEmpty) await cubit.rename(name);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;

    return BlocBuilder<ProfileCubit, Member?>(
      builder: (context, member) {
        final name = member?.name ?? user.name;
        final color = member?.color ?? user.color;

        return Scaffold(
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                PageHeader(title: 'Profile', onBack: () => context.go('/home')),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 130),
                    children: [
                      Center(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          child: InitialAvatar(key: ValueKey(color), name: name, color: Color(color), size: 92),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Center(
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => _rename(context, name),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(name, style: text.headlineMedium),
                                const SizedBox(width: 8),
                                Icon(Icons.edit_rounded, size: 18, color: c.muted),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (user.email != null)
                        Center(child: Text(user.email!, style: text.bodyMedium?.copyWith(color: c.muted))),
                      const SizedBox(height: 24),
                      const SectionLabel('Avatar color'),
                      AppCard(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            for (final choice in AppColors.avatarChoices)
                              _ColorDot(
                                color: choice,
                                selected: choice.toARGB32() == color,
                                onTap: () => context.read<ProfileCubit>().setColor(choice.toARGB32()),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      const SectionLabel('Theme'),
                      BlocBuilder<ThemeCubit, AppThemeMode>(
                        builder: (context, mode) => _ThemePicker(
                          value: mode,
                          onChanged: context.read<ThemeCubit>().setMode,
                        ),
                      ),
                      if (user.isDemo) ...[
                        const SizedBox(height: 20),
                        const SectionLabel('Demo'),
                        const _DemoControls(),
                      ],
                      const SizedBox(height: 28),
                      PillButton(
                        label: user.isDemo ? 'Leave demo' : 'Sign out',
                        icon: Icons.logout_rounded,
                        style: PillStyle.outline,
                        onPressed: () => context.read<SessionCubit>().signOut(),
                      ),
                      const SizedBox(height: 12),
                      Center(child: Text('fridge-note 1.0', style: text.bodySmall)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({required this.color, required this.selected, required this.onTap});

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 40,
        height: 40,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: selected ? color : Colors.transparent, width: 2),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            // The black swatch would vanish on the dark background without it.
            border: Border.all(color: context.colors.border),
          ),
          child: selected ? const Icon(Icons.check_rounded, size: 18, color: Colors.white) : null,
        ),
      ),
    );
  }
}

class _ThemePicker extends StatelessWidget {
  const _ThemePicker({required this.value, required this.onChanged});

  final AppThemeMode value;
  final ValueChanged<AppThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    const options = [
      (AppThemeMode.system, 'System', Icons.brightness_auto_rounded),
      (AppThemeMode.light, 'Light', Icons.light_mode_rounded),
      (AppThemeMode.dark, 'Dark', Icons.dark_mode_rounded),
    ];

    return Row(
      children: [
        for (final option in options)
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: option.$1 == AppThemeMode.dark ? 0 : 10),
              child: GestureDetector(
                onTap: () => onChanged(option.$1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 76,
                  decoration: BoxDecoration(
                    color: option.$1 == value ? c.primarySoft : c.card,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: option.$1 == value ? c.primary : c.border),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(option.$3, color: option.$1 == value ? c.primary : c.muted),
                      const SizedBox(height: 6),
                      Text(option.$2, style: text.labelMedium),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Switches to play with sync in the demo.
class _DemoControls extends StatefulWidget {
  const _DemoControls();

  @override
  State<_DemoControls> createState() => _DemoControlsState();
}

class _DemoControlsState extends State<_DemoControls> {
  @override
  Widget build(BuildContext context) {
    final remote = sl<FakeRemote>();
    final partner = sl<DemoPartner>();
    final text = Theme.of(context).textTheme;

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('Phone is offline', style: text.titleSmall),
            subtitle: Text('Your changes wait in the outbox', style: text.bodySmall),
            value: !remote.isOnline,
            onChanged: (offline) => setState(() => remote.online = !offline),
          ),
          const Divider(height: 1),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text('Anis is editing', style: text.titleSmall),
            subtitle: Text('A change every few seconds', style: text.bodySmall),
            value: partner.isRunning,
            onChanged: (on) => setState(() => on ? partner.start() : partner.stop()),
          ),
        ],
      ),
    );
  }
}
