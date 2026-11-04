import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/avatar.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/pill_button.dart';
import '../../../auth/presentation/cubit/session_cubit.dart';
import '../bloc/current_list_cubit.dart';
import '../bloc/lists_bloc.dart';
import '../widgets/list_card.dart';
import '../widgets/sheets.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ListsBloc(watchLists: sl(), createList: sl())..add(const ListsStarted()),
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView();

  void _open(BuildContext context, String listId) {
    context.read<CurrentListCubit>().select(listId);
    context.go('/list');
  }

  Future<void> _newList(BuildContext context) async {
    final bloc = context.read<ListsBloc>();
    final result = await NewListSheet.show(context);
    if (result != null) bloc.add(ListCreated(name: result.$1, store: result.$2));
  }

  Future<void> _joinWithCode(BuildContext context) async {
    final code = await showDialog<String>(context: context, builder: (_) => const _CodeDialog());
    if (code != null && code.trim().isNotEmpty && context.mounted) {
      context.push('/invite/${code.trim().toUpperCase()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    final user = context.watch<SessionCubit>().state.user;
    final tints = [c.lilac, c.mint, c.sky, c.peach];

    return BlocConsumer<ListsBloc, ListsState>(
      listenWhen: (a, b) => b.createdListId != null && a.createdListId != b.createdListId,
      listener: (context, state) => _open(context, state.createdListId!),
      builder: (context, state) {
        return Scaffold(
          body: SafeArea(
            bottom: false,
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Hello, ${user?.name ?? 'there'}', style: text.bodyLarge?.copyWith(color: c.muted)),
                              const SizedBox(height: 2),
                              Text('My lists', style: text.headlineMedium),
                            ],
                          ),
                        ),
                        if (user != null)
                          GestureDetector(
                            onTap: () => context.go('/profile'),
                            child: InitialAvatar(name: user.name, color: Color(user.color), size: 48),
                          ),
                      ],
                    ),
                  ),
                ),
                if (user?.isDemo ?? false)
                  const SliverPadding(
                    padding: EdgeInsets.fromLTRB(20, 8, 20, 4),
                    sliver: SliverToBoxAdapter(child: _DemoBanner()),
                  ),
                if (!state.loading && state.lists.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyState(
                      message: 'No lists yet. Start one and invite your people.',
                      action: PillButton(
                        label: 'New list',
                        icon: Icons.add_rounded,
                        expand: false,
                        onPressed: () => _newList(context),
                      ),
                    ),
                  )
                else ...[
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                    sliver: SliverList.separated(
                      itemCount: state.lists.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 14),
                      itemBuilder: (context, i) {
                        final list = state.lists[i];
                        return ListCard(
                          key: ValueKey(list.id),
                          list: list,
                          tint: tints[i % tints.length],
                          onTap: () => _open(context, list.id),
                        );
                      },
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 130),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        children: [
                          PillButton(
                            label: 'New list',
                            icon: Icons.add_rounded,
                            style: PillStyle.soft,
                            onPressed: () => _newList(context),
                          ),
                          const SizedBox(height: 4),
                          TextButton(
                            onPressed: () => _joinWithCode(context),
                            child: Text('Have an invite code?', style: text.titleSmall?.copyWith(color: c.primary)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DemoBanner extends StatelessWidget {
  const _DemoBanner();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.yellow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Icon(Icons.bolt_rounded, color: AppColors.ink, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Demo mode: Anis is shopping on another phone. Open Weekly groceries to watch it update.',
              style: text.bodySmall?.copyWith(color: AppColors.ink, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _CodeDialog extends StatefulWidget {
  const _CodeDialog();

  @override
  State<_CodeDialog> createState() => _CodeDialogState();
}

class _CodeDialogState extends State<_CodeDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final demo = context.read<SessionCubit>().state.isDemo;
    return AlertDialog(
      backgroundColor: context.colors.screen,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      title: const Text('Join a list'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(hintText: 'Invite code'),
            onSubmitted: (value) => Navigator.pop(context, value),
          ),
          if (demo)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                'In the demo, try MOVIE24 to join Yasmine\'s list.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        TextButton(onPressed: () => Navigator.pop(context, _controller.text), child: const Text('Join')),
      ],
    );
  }
}
