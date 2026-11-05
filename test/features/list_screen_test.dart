import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fridge_note/core/sync/sync_status.dart';
import 'package:fridge_note/core/theme/app_theme.dart';
import 'package:fridge_note/core/widgets/empty_state.dart';
import 'package:fridge_note/features/lists/domain/entities/item_category.dart';
import 'package:fridge_note/features/lists/domain/entities/list_item.dart';
import 'package:fridge_note/features/lists/presentation/bloc/list_detail_bloc.dart';
import 'package:fridge_note/features/lists/presentation/pages/list_detail_page.dart';
import 'package:fridge_note/features/lists/presentation/widgets/item_card.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/fixtures.dart';

class MockListDetailBloc extends MockBloc<ListDetailEvent, ListDetailState> implements ListDetailBloc {}

void main() {
  late MockListDetailBloc bloc;

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
    registerFallbackValue(const ListDetailStarted(''));
  });

  setUp(() => bloc = MockListDetailBloc());

  Future<void> pumpList(WidgetTester tester, List<ListItem> items) async {
    tester.view.physicalSize = const Size(390, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    when(() => bloc.state).thenReturn(ListDetailState(
      loading: false,
      list: weeklyList(itemCount: items.length, leftCount: items.where((i) => !i.checked).length),
      items: items,
      sync: const SyncStatus(phase: SyncPhase.synced, pending: 0),
    ));
    await tester.pumpWidget(MaterialApp(
      theme: AppTheme.light(),
      home: BlocProvider<ListDetailBloc>.value(
        value: bloc,
        child: const ListDetailView(listId: 'list'),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 500));
  }

  final twoItems = [milk(), milk(id: 'eggs', name: 'Eggs', checked: true)];

  testWidgets('shows each item with its amount and who added it', (tester) async {
    await pumpList(tester, twoItems);

    expect(find.text('Weekly groceries'), findsOneWidget);
    expect(find.text('Milk'), findsOneWidget);
    expect(find.text('2 L · €2.30'), findsNWidgets(2));
    expect(find.text('Added by Sirine'), findsOneWidget);
    expect(find.text('Got by Anis'), findsOneWidget, reason: 'checked items say who got them');
  });

  testWidgets('shows the summary rows under the items', (tester) async {
    await pumpList(tester, twoItems);

    expect(find.text('Items left'), findsOneWidget);
    expect(find.text('1 of 2'), findsOneWidget);
    expect(find.text('Estimated total'), findsOneWidget);
    expect(find.text('€4.60'), findsOneWidget);
    expect(find.text('Green Corner Market'), findsOneWidget);
    expect(find.text('Synced'), findsOneWidget);
  });

  testWidgets('a checked item is struck through, an open one is not', (tester) async {
    await pumpList(tester, twoItems);

    final strikes = tester.widgetList<StrikeText>(find.byType(StrikeText)).toList();
    expect(strikes.map((s) => (s.text, s.struck)), [('Milk', false), ('Eggs', true)]);
  });

  testWidgets('tapping the check circle toggles the item', (tester) async {
    await pumpList(tester, twoItems);

    await tester.tap(find.byType(CheckCircle).first);
    verify(() => bloc.add(ItemToggled(twoItems.first))).called(1);
  });

  testWidgets('typing a name and pressing done adds it with a guessed category', (tester) async {
    await pumpList(tester, twoItems);

    await tester.enterText(find.byType(TextField), 'bananas');
    await tester.testTextInput.receiveAction(TextInputAction.done);

    verify(() => bloc.add(const ItemAdded(NewItem(
          listId: 'list',
          name: 'bananas',
          category: ItemCategory.produce,
        )))).called(1);
  });

  testWidgets('swiping an item to the left removes it', (tester) async {
    await pumpList(tester, twoItems);

    await tester.drag(find.text('Milk'), const Offset(-500, 0));
    await tester.pumpAndSettle();

    verify(() => bloc.add(ItemRemoved(twoItems.first))).called(1);
  });

  testWidgets('an empty list shows the illustration and one line of text', (tester) async {
    await pumpList(tester, []);

    expect(find.byType(FridgeIllustration), findsOneWidget);
    expect(find.text('Nothing on this list yet.'), findsOneWidget);
  });
}
