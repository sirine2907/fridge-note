import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/lists/domain/entities/shopping_list.dart';
import '../../features/lists/domain/usecases/watch_lists.dart';
import '../../features/lists/presentation/bloc/current_list_cubit.dart';
import '../di/injection.dart';
import '../widgets/floating_nav_bar.dart';

/// The five tabs with the floating nav bar on top of them.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: sl<CurrentListCubit>(),
      child: Scaffold(
        extendBody: true,
        body: shell,
        bottomNavigationBar: BlocBuilder<CurrentListCubit, String?>(
          builder: (context, listId) => StreamBuilder<ShoppingList?>(
            stream: listId == null ? null : sl<WatchList>()(listId),
            builder: (context, snapshot) {
              final left = snapshot.data?.leftCount ?? 0;
              return FloatingNavBar(
                currentIndex: shell.currentIndex,
                onTap: (index) => shell.goBranch(index, initialLocation: index == shell.currentIndex),
                items: [
                  const NavBarItem(icon: Icons.home_rounded, label: 'Home'),
                  NavBarItem(icon: Icons.receipt_long_rounded, label: 'List', badge: left),
                  const NavBarItem(icon: Icons.shopping_cart_rounded, label: 'Trip'),
                  const NavBarItem(icon: Icons.favorite_rounded, label: 'Usuals'),
                  const NavBarItem(icon: Icons.person_rounded, label: 'Profile'),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
