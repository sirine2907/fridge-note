import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/sync/sync_engine.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/avatar.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/page_header.dart';
import '../../../../core/widgets/pill_button.dart';
import '../../../../core/widgets/round_back_button.dart';
import '../../../../core/widgets/ticker_builder.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../lists/domain/entities/shopping_list.dart';
import '../../../lists/presentation/bloc/current_list_cubit.dart';
import '../../../lists/presentation/widgets/category_style.dart';
import '../cubit/trip_cubit.dart';
import '../widgets/trip_widgets.dart';

/// The trip in progress (built from the "order tracking" layout of the reference).
class ShoppingTripPage extends StatelessWidget {
  const ShoppingTripPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CurrentListCubit, String?>(
      builder: (context, listId) {
        if (listId == null) {
          return Scaffold(
            body: SafeArea(
              child: Column(
                children: [
                  PageHeader(title: 'Shopping trip', onBack: () => context.go('/home')),
                  const Expanded(child: EmptyState(message: 'Pick a list first.')),
                ],
              ),
            ),
          );
        }
        return BlocProvider(
          key: ValueKey(listId),
          create: (_) => TripCubit(
            listId: listId,
            watchList: sl(),
            watchItems: sl(),
            watchActivity: sl(),
            syncStatus: sl<SyncEngine>().watchStatus,
            startTrip: sl(),
            finishTrip: sl(),
            nudgeShopper: sl(),
            toggleItem: sl(),
          ),
          child: const _TripView(),
        );
      },
    );
  }
}

class _TripView extends StatelessWidget {
  const _TripView();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final me = sl<AppUser>();

    return BlocBuilder<TripCubit, TripState>(
      builder: (context, state) {
        final list = state.list;
        final cubit = context.read<TripCubit>();

        return Scaffold(
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                PageHeader(
                  title: 'Shopping trip',
                  subtitle: list?.name,
                  onBack: () => context.go('/list'),
                ),
                Expanded(
                  child: list == null
                      ? const SizedBox.shrink()
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                          children: [
                            AppCard(
                              padding: const EdgeInsets.fromLTRB(16, 20, 16, 18),
                              child: Column(
                                children: [
                                  TripStepper(stage: state.stage),
                                  const SizedBox(height: 18),
                                  Row(
                                    children: [
                                      Text(
                                        '${list.checkedCount} of ${list.itemCount} in the basket',
                                        style: Theme.of(context).textTheme.titleSmall,
                                      ),
                                      const Spacer(),
                                      Text(
                                        '${(list.progress * 100).round()}%',
                                        style: Theme.of(context).textTheme.titleSmall?.copyWith(color: c.primary),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  SmoothProgressBar(value: list.progress),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: StatusTile(
                                    color: c.mint,
                                    icon: Icons.receipt_long_rounded,
                                    value: '${list.leftCount}',
                                    label: 'Items left',
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: StatusTile(
                                    color: c.sky,
                                    icon: Icons.storefront_rounded,
                                    value: list.store.isEmpty ? 'Any' : list.store,
                                    label: 'Store',
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TickerBuilder(
                                    builder: (_) => StatusTile(
                                      color: c.lilac,
                                      icon: Icons.update_rounded,
                                      value: state.lastUpdate == null ? '-' : timeAgo(state.lastUpdate!),
                                      label: 'Updated',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            _ShopperCard(list: list, isMe: list.shopper?.id == me.id, onNudge: cubit.nudge),
                            const SizedBox(height: 22),
                            const SectionLabel('Live activity', trailing: LiveDot()),
                            if (state.activity.isEmpty)
                              Text('Nothing yet.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: c.muted))
                            else
                              for (var i = 0; i < state.activity.length && i < 4; i++)
                                Padding(
                                  key: ValueKey(state.activity[i].id),
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: AppearIn(
                                    child: ActivityRow(activity: state.activity[i], highlight: i == 0),
                                  ),
                                ),
                            if (state.remaining.isNotEmpty) ...[
                              const SizedBox(height: 14),
                              const SectionLabel('Still to get'),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  for (final item in state.remaining)
                                    ActionChip(
                                      key: ValueKey(item.id),
                                      avatar: Icon(CategoryStyle.of(context, item.category).icon,
                                          size: 16, color: CategoryStyle.of(context, item.category).ink),
                                      label: Text(item.name),
                                      tooltip: 'Check off ${item.name}',
                                      onPressed: () => cubit.toggle(item),
                                      backgroundColor: c.card,
                                      side: BorderSide(color: c.border),
                                      shape: const StadiumBorder(),
                                      labelStyle: Theme.of(context).textTheme.labelMedium,
                                    ),
                                ],
                              ),
                            ],
                          ],
                        ),
                ),
                if (list != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                    child: _BottomButton(state: state),
                  ),
                SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ShopperCard extends StatelessWidget {
  const _ShopperCard({required this.list, required this.isMe, required this.onNudge});

  final ShoppingList list;
  final bool isMe;
  final Future<void> Function() onNudge;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final text = Theme.of(context).textTheme;
    final shopper = list.shopper;

    if (shopper == null) {
      return AppCard(
        child: Row(
          children: [
            PastelTile(
              color: c.primarySoft,
              size: 52,
              radius: 26,
              child: Icon(Icons.directions_walk_rounded, color: c.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Who\'s shopping', style: text.bodySmall),
                  Text('Nobody yet', style: text.titleMedium),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final since = list.tripStartedAt;
    return AppCard(
      child: Row(
        children: [
          InitialAvatar(name: shopper.name, color: Color(shopper.color), size: 52),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Who\'s shopping', style: text.bodySmall),
                Text(isMe ? 'You' : shopper.name, style: text.titleMedium?.copyWith(fontSize: 17)),
                if (since != null)
                  TickerBuilder(
                    builder: (_) => Text(
                      'Started ${timeAgo(since)}',
                      style: text.bodySmall,
                    ),
                  ),
              ],
            ),
          ),
          if (!isMe) ...[
            RoundIconButton(
              icon: Icons.chat_bubble_rounded,
              tooltip: 'Nudge ${shopper.firstName}',
              filled: true,
              onPressed: () async {
                await onNudge();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Nudge sent to ${shopper.firstName}')),
                  );
                }
              },
            ),
            const SizedBox(width: 8),
            RoundIconButton(
              icon: Icons.call_rounded,
              tooltip: 'Call ${shopper.firstName}',
              filled: true,
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('No phone number saved for ${shopper.firstName}')),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BottomButton extends StatelessWidget {
  const _BottomButton({required this.state});

  final TripState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<TripCubit>();
    switch (state.stage) {
      case TripStage.planned:
        return PillButton(
          label: 'Start shopping',
          icon: Icons.shopping_cart_rounded,
          onPressed: (state.list?.itemCount ?? 0) == 0 ? null : cubit.start,
        );
      case TripStage.shopping:
      case TripStage.done:
        return PillButton(
          label: 'Finish trip',
          icon: Icons.check_circle_rounded,
          style: state.stage == TripStage.done ? PillStyle.primary : PillStyle.soft,
          onPressed: () async {
            await cubit.finish();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Trip finished. Checked items were cleared.')),
              );
            }
          },
        );
    }
  }
}
