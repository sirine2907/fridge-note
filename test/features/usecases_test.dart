import 'package:flutter_test/flutter_test.dart';
import 'package:fridge_note/features/auth/domain/repositories/auth_repository.dart';
import 'package:fridge_note/features/auth/domain/usecases/auth_usecases.dart';
import 'package:fridge_note/features/invite/domain/repositories/invite_repository.dart';
import 'package:fridge_note/features/invite/domain/usecases/invite_usecases.dart';
import 'package:fridge_note/features/lists/domain/entities/item_category.dart';
import 'package:fridge_note/features/lists/domain/entities/list_item.dart';
import 'package:fridge_note/features/lists/domain/repositories/lists_repository.dart';
import 'package:fridge_note/features/lists/domain/usecases/add_item.dart';
import 'package:fridge_note/features/lists/domain/usecases/create_list.dart';
import 'package:fridge_note/features/lists/domain/usecases/item_actions.dart';
import 'package:fridge_note/features/usuals/domain/repositories/usuals_repository.dart';
import 'package:fridge_note/features/usuals/domain/usecases/usual_actions.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/fixtures.dart';

class MockListsRepository extends Mock implements ListsRepository {}

class MockUsualsRepository extends Mock implements UsualsRepository {}

class MockAuthRepository extends Mock implements AuthRepository {}

class MockInviteRepository extends Mock implements InviteRepository {}

void main() {
  late MockListsRepository lists;

  setUpAll(() {
    registerFallbackValue(const NewItem(listId: '', name: ''));
    registerFallbackValue(milk());
    registerFallbackValue(eggsUsual());
  });

  setUp(() {
    lists = MockListsRepository();
    when(() => lists.addItem(any())).thenAnswer((_) async {});
    when(() => lists.setQuantity(any(), any())).thenAnswer((_) async {});
    when(() => lists.setChecked(any(), any())).thenAnswer((_) async {});
    when(() => lists.reorder(any(), any())).thenAnswer((_) async {});
  });

  group('AddItem', () {
    test('trims the name and starts it with a capital', () async {
      await AddItem(lists)(const NewItem(listId: 'l', name: '  oat milk '));
      final saved = verify(() => lists.addItem(captureAny())).captured.single as NewItem;
      expect(saved.name, 'Oat milk');
    });

    test('keeps the quantity at least 1', () async {
      await AddItem(lists)(const NewItem(listId: 'l', name: 'Eggs', quantity: 0));
      final saved = verify(() => lists.addItem(captureAny())).captured.single as NewItem;
      expect(saved.quantity, 1);
    });

    test('refuses an empty name', () {
      expect(() => AddItem(lists)(const NewItem(listId: 'l', name: '   ')), throwsArgumentError);
      verifyNever(() => lists.addItem(any()));
    });
  });

  group('ChangeQuantity', () {
    test('clamps to 1..99', () async {
      await ChangeQuantity(lists)(milk(quantity: 2), 500);
      verify(() => lists.setQuantity(any(), 99)).called(1);
    });

    test('does nothing when the value is the same', () async {
      await ChangeQuantity(lists)(milk(quantity: 2), 2);
      verifyNever(() => lists.setQuantity(any(), any()));
    });
  });

  test('ToggleItem flips the checked state', () async {
    await ToggleItem(lists)(milk(checked: false));
    verify(() => lists.setChecked(any(), true)).called(1);
  });

  test('ReorderItems moves an item down like ReorderableListView reports it', () async {
    final items = [milk(id: 'a'), milk(id: 'b'), milk(id: 'c')];
    // Dragging "a" below "b": the list view reports newIndex 2.
    final result = await ReorderItems(lists)(items, 0, 2);
    expect(result.map((i) => i.id), ['b', 'a', 'c']);
    verify(() => lists.reorder('list', ['b', 'a', 'c'])).called(1);
  });

  test('CreateList refuses an empty name', () {
    expect(() => CreateList(lists)(name: ' '), throwsArgumentError);
  });

  test('AddUsualToList adds the item and counts the purchase', () async {
    final usuals = MockUsualsRepository();
    when(() => usuals.markBought(any())).thenAnswer((_) async {});

    await AddUsualToList(usuals, lists)(eggsUsual(), 'list');

    final saved = verify(() => lists.addItem(captureAny())).captured.single as NewItem;
    expect(saved.name, 'Eggs');
    expect(saved.quantity, 12);
    verify(() => usuals.markBought(any())).called(1);
  });

  group('email sign-in', () {
    late MockAuthRepository auth;

    setUp(() {
      auth = MockAuthRepository();
      when(() => auth.sendEmailCode(any())).thenAnswer((_) async {});
    });

    test('sends the code to the cleaned up address', () async {
      await SendEmailCode(auth)('  Sirine@Example.com ');
      verify(() => auth.sendEmailCode('sirine@example.com')).called(1);
    });

    test('refuses something that is not an email', () {
      expect(() => SendEmailCode(auth)('sirine'), throwsA(isA<AuthFailure>()));
    });

    test('the code must be 6 digits', () {
      expect(() => VerifyEmailCode(auth)(email: 'a@b.co', code: '12a456'), throwsA(isA<AuthFailure>()));
    });
  });

  test('invite codes are not case sensitive', () async {
    final invites = MockInviteRepository();
    when(() => invites.join(any())).thenAnswer((_) async => 'list');
    await JoinList(invites)(' movie24 ');
    verify(() => invites.join('MOVIE24')).called(1);
  });

  test('CreateInviteLink builds the full link', () async {
    final invites = MockInviteRepository();
    when(() => invites.createInvite('list')).thenAnswer((_) async => 'K7Q2MX');
    final link = await CreateInviteLink(invites, baseUrl: 'https://x.dev/invite/')('list');
    expect(link, 'https://x.dev/invite/K7Q2MX');
  });

  group('ItemCategory.guess', () {
    test('finds the shelf from the name', () {
      expect(ItemCategory.guess('Oat milk'), ItemCategory.dairy);
      expect(ItemCategory.guess('Bin bags'), ItemCategory.household);
      expect(ItemCategory.guess('Cherry tomatoes'), ItemCategory.produce);
    });

    test('falls back to other', () {
      expect(ItemCategory.guess('Birthday candles'), ItemCategory.other);
    });
  });
}
