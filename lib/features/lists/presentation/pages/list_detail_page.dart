import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/sync/sync_engine.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/page_header.dart';
import '../../../../core/widgets/pill_button.dart';
import '../../../../core/widgets/sync_chip.dart';
import '../../domain/entities/item_category.dart';
import '../../domain/entities/list_item.dart';
import '../../domain/entities/shopping_list.dart';
import '../../domain/usecases/trip_actions.dart';
import '../bloc/current_list_cubit.dart';
import '../bloc/list_detail_bloc.dart';
import '../widgets/item_card.dart';
import '../widgets/sheets.dart';

/// The list itself (built from the "checkout" layout of the reference design).
class ListDetailPage extends StatelessWidget {
  const ListDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CurrentListCubit, String?>(
      builder: (context, listId) {
        if (listId == null) {
          return Scaffold(
            body: SafeArea(
              child: Column(
                children: [
                  PageHeader(title: 'List', onBack: () => context.go('/home')),
                  const Expanded(child: EmptyState(message: 'Create a list on the home screen first.')),
                ],
              ),
            ),
          );
        }
        return BlocProvider(
          key: ValueKey(listId),
          create: (_) => ListDetailBloc(
            watchList: sl(),
            watchItems: sl(),
            toggleItem: sl(),
            changeQuantity: sl(),
            removeItem: sl(),
            reorderItems: sl(),
            addItem: sl(),
            syncStatus: sl<SyncEngine>().watchStatus,
          )..add(ListDetailStarted(listId)),
          child: _ListDetailView(listId: listId),
        );
      },
    );
  }
}

class _ListDetailView extends StatelessWidget {
  const _ListDetailView({required this.listId});

  final String listId;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return BlocBuilder<ListDetailBloc, ListDetailState>(
      builder: (context, state) {
        final list = state.list;
        final bloc = context.read<ListDetailBloc>();
        final others = list?.members.skip(1).map((m) => m.firstName).toList() ?? [];

        return Scaffold(
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                PageHeader(
                  title: list?.name ?? '',
                  subtitle: others.isEmpty ? 'Only you' : 'With ${others.join(', ')}',
                  onBack: () => context.go('/home'),
                ),
                SyncChip(status: state.sync),
                const SizedBox(height: 8),
                Expanded(
                  child: state.loading
                      ? const SizedBox.shrink()
                      : state.items.isEmpty
                          ? ListView(
                              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                              children: [
                                _QuickAdd(listId: listId),
                                const SizedBox(height: 12),
                                const EmptyState(message: 'Nothing on this list yet.'),
                              ],
                            )
                          : ReorderableListView.builder(
                              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                              buildDefaultDragHandles: false,
                              header: Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: _QuickAdd(listId: listId),
                              ),
                              footer: _Summary(state: state),
                              proxyDecorator: (child, _, animation) => ScaleTransition(
                                scale: Tween(begin: 1.0, end: 1.03).animate(animation),
                                child: Material(color: Colors.transparent, child: child),
                              ),
                              onReorder: (from, to) => bloc.add(ItemsReordered(from, to)),
                              itemCount: state.items.length,
                              itemBuilder: (context, i) {
                                final item = state.items[i];
                                return _DismissibleItem(
                                  key: ValueKey(item.id),
                                  index: i,
                                  item: item,
                                  onRemoved: () => bloc.add(ItemRemoved(item)),
                                  child: ItemCard(
                                    item: item,
                                    onToggle: () => bloc.add(ItemToggled(item)),
                                    onQuantityChanged: (q) => bloc.add(QuantityChanged(item, q)),
                                  ),
                                );
                              },
                            ),
                ),
                if (list != null)
                  Container(
                    color: c.screen,
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                    child: _TripButton(list: list),
                  ),
                // Room for the floating nav bar. With extendBody the Scaffold already
                // puts the bar's height into padding.bottom.
                SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DismissibleItem extends StatelessWidget {
  const _DismissibleItem({
    super.key,
    required this.index,
    required this.item,
    required this.onRemoved,
    required this.child,
  });

  final int index;
  final ListItem item;
  final VoidCallback onRemoved;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Dismissible(
        key: ValueKey('dismiss-${item.id}'),
        direction: DismissDirection.endToStart,
        onDismissed: (_) {
          onRemoved();
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text('${item.name} removed')));
        },
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 24),
          decoration: BoxDecoration(
            color: AppColors.red.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Icon(Icons.delete_outline_rounded, color: AppColors.red),
        ),
        child: ReorderableDelayedDragStartListener(index: index, child: child),
      ),
    );
  }
}

/// Type a name and press enter to add it. The tune button opens the full form.
class _QuickAdd extends StatefulWidget {
  const _QuickAdd({required this.listId});

  final String listId;

  @override
  State<_QuickAdd> createState() => _QuickAddState();
}

class _QuickAddState extends State<_QuickAdd> {
  final _controller = TextEditingController();
  final _focus = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _add(String name) {
    if (name.trim().isEmpty) return;
    context.read<ListDetailBloc>().add(ItemAdded(NewItem(
          listId: widget.listId,
          name: name,
          category: ItemCategory.guess(name),
        )));
    _controller.clear();
    _focus.requestFocus();
  }

  Future<void> _openForm() async {
    final bloc = context.read<ListDetailBloc>();
    final item = await AddItemSheet.show(context, listId: widget.listId, initialName: _controller.text);
    if (item != null) {
      bloc.add(ItemAdded(item));
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return TextField(
      controller: _controller,
      focusNode: _focus,
      textCapitalization: TextCapitalization.sentences,
      textInputAction: TextInputAction.done,
      onSubmitted: _add,
      decoration: InputDecoration(
        hintText: 'Add an item...',
        prefixIcon: Icon(Icons.add_rounded, color: c.primary),
        suffixIcon: IconButton(
          tooltip: 'More options',
          icon: Icon(Icons.tune_rounded, color: c.primary),
          onPressed: _openForm,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(999),
          borderSide: BorderSide(color: c.primary, width: 1.5),
        ),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.state});

  final ListDetailState state;

  @override
  Widget build(BuildContext context) {
    final list = state.list;
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
        child: Column(
          children: [
            _SummaryRow(
              label: 'Items left',
              value: '${state.leftCount} of ${state.items.length}',
            ),
            const Divider(height: 1),
            _SummaryRow(label: 'Estimated total', value: money(state.estimatedTotal), bold: true),
            const Divider(height: 1),
            _SummaryRow(
              label: 'Store',
              value: (list?.store.isEmpty ?? true) ? 'Any store' : list!.store,
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value, this.bold = false});

  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Text(label, style: text.bodyMedium?.copyWith(color: context.colors.muted)),
          const SizedBox(width: 12),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Text(
                value,
                key: ValueKey(value),
                textAlign: TextAlign.right,
                overflow: TextOverflow.ellipsis,
                style: bold ? text.titleLarge?.copyWith(fontSize: 18) : text.titleSmall,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TripButton extends StatelessWidget {
  const _TripButton({required this.list});

  final ShoppingList list;

  @override
  Widget build(BuildContext context) {
    switch (list.stage) {
      case TripStage.planned:
        return PillButton(
          label: 'Start shopping',
          icon: Icons.shopping_cart_rounded,
          onPressed: list.itemCount == 0
              ? null
              : () async {
                  await sl<StartTrip>()(list.id);
                  if (context.mounted) context.go('/trip');
                },
        );
      case TripStage.shopping:
        return PillButton(
          label: '${list.shopper!.firstName} is shopping',
          icon: Icons.route_rounded,
          onPressed: () => context.go('/trip'),
        );
      case TripStage.done:
        return PillButton(
          label: 'Finish trip',
          icon: Icons.celebration_rounded,
          onPressed: () => context.go('/trip'),
        );
    }
  }
}
