import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/page_header.dart';
import '../../../../core/widgets/pill_button.dart';
import '../../../lists/presentation/bloc/current_list_cubit.dart';
import '../../../lists/presentation/widgets/category_style.dart';
import '../../domain/entities/usual_item.dart';
import '../cubit/usuals_cubit.dart';

/// Things we buy often (built from the "wishlist" layout of the reference).
class UsualsPage extends StatelessWidget {
  const UsualsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => UsualsCubit(watchUsuals: sl(), toggleFavorite: sl(), addUsualToList: sl()),
      child: const _UsualsView(),
    );
  }
}

class _UsualsView extends StatelessWidget {
  const _UsualsView();

  Future<void> _add(BuildContext context, UsualItem usual) async {
    final current = context.read<CurrentListCubit>();
    final listId = current.state;
    if (listId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Create a list first')),
      );
      return;
    }
    final listName = current.current?.name ?? 'your list';
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('${usual.name} added to $listName')));
    await context.read<UsualsCubit>().addToList(usual, listId);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<UsualsCubit, UsualsState>(
      builder: (context, state) {
        final cubit = context.read<UsualsCubit>();
        final visible = state.visible;

        return Scaffold(
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                PageHeader(title: 'Usuals', subtitle: 'Bought most often', onBack: () => context.go('/home')),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                  child: _FilterTabs(value: state.filter, onChanged: cubit.setFilter),
                ),
                Expanded(
                  child: state.loading
                      ? const SizedBox.shrink()
                      : visible.isEmpty
                          ? EmptyState(
                              message: state.filter == UsualsFilter.hearted
                                  ? 'Tap the heart on things you buy every week.'
                                  : 'Things you buy often will show up here.',
                            )
                          : GridView.builder(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 130),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 14,
                                crossAxisSpacing: 14,
                                mainAxisExtent: 262,
                              ),
                              itemCount: visible.length,
                              itemBuilder: (context, i) {
                                final usual = visible[i];
                                return UsualTile(
                                  key: ValueKey(usual.id),
                                  usual: usual,
                                  added: state.justAdded.contains(usual.id),
                                  onHeart: () => cubit.toggleFavorite(usual),
                                  onAdd: () => _add(context, usual),
                                );
                              },
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

class _FilterTabs extends StatelessWidget {
  const _FilterTabs({required this.value, required this.onChanged});

  final UsualsFilter value;
  final ValueChanged<UsualsFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: c.primarySoft,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          for (final filter in UsualsFilter.values)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(filter),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: filter == value ? c.card : Colors.transparent,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    filter == UsualsFilter.all ? 'All usuals' : 'Hearted',
                    style: text.titleSmall?.copyWith(color: filter == value ? c.ink : c.muted),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class UsualTile extends StatelessWidget {
  const UsualTile({
    super.key,
    required this.usual,
    required this.added,
    required this.onHeart,
    required this.onAdd,
  });

  final UsualItem usual;
  final bool added;
  final VoidCallback onHeart;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final style = CategoryStyle.of(context, usual.category);

    return AppCard(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(color: style.tile, borderRadius: BorderRadius.circular(20)),
              child: Stack(
                children: [
                  Center(child: Icon(style.icon, size: 54, color: style.ink)),
                  if (usual.badge != null)
                    Positioned(top: 10, left: 10, child: YellowBadge(usual.badge!)),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: _HeartButton(on: usual.favorite, onTap: onHeart, name: usual.name),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(usual.name, style: text.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(
                  '${amount(usual.quantity, usual.unit)} · ${money(usual.price * usual.quantity)}',
                  style: text.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: PillButton(
              key: ValueKey(added),
              label: added ? 'Added' : 'Add to list',
              icon: added ? Icons.check_rounded : Icons.add_rounded,
              height: 40,
              style: added ? PillStyle.soft : PillStyle.primary,
              onPressed: added ? null : onAdd,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeartButton extends StatelessWidget {
  const _HeartButton({required this.on, required this.onTap, required this.name});

  final bool on;
  final VoidCallback onTap;
  final String name;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      button: true,
      label: on ? 'Remove $name from hearted' : 'Heart $name',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(color: c.card, shape: BoxShape.circle),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
            child: Icon(
              on ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              key: ValueKey(on),
              size: 19,
              color: on ? AppColors.red : c.muted,
            ),
          ),
        ),
      ),
    );
  }
}
