import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fridge_note/core/di/session_scope.dart';
import 'package:fridge_note/core/sync/sync_status.dart';
import 'package:fridge_note/features/auth/domain/entities/app_user.dart';
import 'package:fridge_note/features/auth/domain/repositories/auth_repository.dart';
import 'package:fridge_note/features/auth/domain/usecases/auth_usecases.dart';
import 'package:fridge_note/features/auth/presentation/cubit/email_sign_in_cubit.dart';
import 'package:fridge_note/features/auth/presentation/cubit/session_cubit.dart';
import 'package:fridge_note/features/lists/domain/entities/list_item.dart';
import 'package:fridge_note/features/lists/domain/entities/item_category.dart';
import 'package:fridge_note/features/lists/domain/repositories/lists_repository.dart';
import 'package:fridge_note/features/lists/domain/usecases/add_item.dart';
import 'package:fridge_note/features/lists/domain/usecases/create_list.dart';
import 'package:fridge_note/features/lists/domain/usecases/item_actions.dart';
import 'package:fridge_note/features/lists/domain/usecases/watch_items.dart';
import 'package:fridge_note/features/lists/domain/usecases/watch_lists.dart';
import 'package:fridge_note/features/lists/presentation/bloc/list_detail_bloc.dart';
import 'package:fridge_note/features/lists/presentation/bloc/lists_bloc.dart';
import 'package:fridge_note/features/usuals/domain/entities/usual_item.dart';
import 'package:fridge_note/features/usuals/domain/repositories/usuals_repository.dart';
import 'package:fridge_note/features/usuals/domain/usecases/usual_actions.dart';
import 'package:fridge_note/features/usuals/presentation/cubit/usuals_cubit.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/fixtures.dart';

class MockListsRepository extends Mock implements ListsRepository {}

class MockUsualsRepository extends Mock implements UsualsRepository {}

class MockAuthRepository extends Mock implements AuthRepository {}

class MockSessionScope extends Mock implements SessionScope {}

const synced = SyncStatus(phase: SyncPhase.synced, pending: 0);
const demoUser = AppUser(id: 'sirine', name: 'Sirine', color: 1, isDemo: true);

void main() {
  setUpAll(() {
    registerFallbackValue(milk());
    registerFallbackValue(const NewItem(listId: '', name: ''));
    registerFallbackValue(demoUser);
  });

  group('ListsBloc', () {
    late MockListsRepository repo;

    setUp(() {
      repo = MockListsRepository();
      when(() => repo.watchLists()).thenAnswer((_) => Stream.value([weeklyList()]));
      when(() => repo.createList(name: any(named: 'name'), store: any(named: 'store')))
          .thenAnswer((_) async => 'new-list');
    });

    ListsBloc build() => ListsBloc(watchLists: WatchLists(repo), createList: CreateList(repo));

    blocTest<ListsBloc, ListsState>(
      'shows the lists from the database',
      build: build,
      act: (bloc) => bloc.add(const ListsStarted()),
      expect: () => [ListsState(loading: false, lists: [weeklyList()])],
    );

    blocTest<ListsBloc, ListsState>(
      'remembers the id of a new list so the page can open it',
      build: build,
      act: (bloc) => bloc.add(const ListCreated(name: 'Picnic')),
      expect: () => [const ListsState(loading: false, createdListId: 'new-list')],
    );
  });

  group('ListDetailBloc', () {
    late MockListsRepository repo;
    late StreamController<List<ListItem>> items;

    setUp(() {
      repo = MockListsRepository();
      items = StreamController<List<ListItem>>.broadcast();
      when(() => repo.watchList('list')).thenAnswer((_) => Stream.value(weeklyList()));
      when(() => repo.watchItems('list')).thenAnswer((_) => items.stream);
      when(() => repo.setChecked(any(), any())).thenAnswer((_) async {});
      when(() => repo.removeItem(any())).thenAnswer((_) async {});
      when(() => repo.reorder(any(), any())).thenAnswer((_) async {});
    });

    tearDown(() => items.close());

    ListDetailBloc build() => ListDetailBloc(
          watchList: WatchList(repo),
          watchItems: WatchItems(repo),
          toggleItem: ToggleItem(repo),
          changeQuantity: ChangeQuantity(repo),
          removeItem: RemoveItem(repo),
          reorderItems: ReorderItems(repo),
          addItem: AddItem(repo),
          syncStatus: () => Stream.value(synced),
        );

    blocTest<ListDetailBloc, ListDetailState>(
      'combines the list, its items and the sync status',
      build: build,
      act: (bloc) async {
        bloc.add(const ListDetailStarted('list'));
        await Future<void>.delayed(Duration.zero);
        items.add([milk(), milk(id: 'eggs', name: 'Eggs', checked: true)]);
      },
      wait: const Duration(milliseconds: 50),
      verify: (bloc) {
        expect(bloc.state.loading, isFalse);
        expect(bloc.state.list, weeklyList());
        expect(bloc.state.items, hasLength(2));
        expect(bloc.state.leftCount, 1);
        expect(bloc.state.sync, synced);
      },
    );

    blocTest<ListDetailBloc, ListDetailState>(
      'toggling an item saves the opposite state',
      build: build,
      act: (bloc) => bloc.add(ItemToggled(milk(checked: false))),
      verify: (_) => verify(() => repo.setChecked(any(), true)).called(1),
    );

    blocTest<ListDetailBloc, ListDetailState>(
      'a removed item disappears right away',
      build: build,
      seed: () => ListDetailState(loading: false, items: [milk(), milk(id: 'eggs')]),
      act: (bloc) => bloc.add(ItemRemoved(milk())),
      expect: () => [
        isA<ListDetailState>().having((s) => s.items.map((i) => i.id), 'ids', ['eggs']),
      ],
    );

    blocTest<ListDetailBloc, ListDetailState>(
      'a reorder shows the new order before the database answers',
      build: build,
      seed: () => ListDetailState(loading: false, items: [milk(id: 'a'), milk(id: 'b'), milk(id: 'c')]),
      act: (bloc) => bloc.add(const ItemsReordered(2, 0)),
      expect: () => [
        isA<ListDetailState>().having((s) => s.items.map((i) => i.id), 'ids', ['c', 'a', 'b']),
      ],
      verify: (_) => verify(() => repo.reorder('list', ['c', 'a', 'b'])).called(1),
    );
  });

  group('UsualsCubit', () {
    late MockUsualsRepository usuals;

    setUp(() {
      usuals = MockUsualsRepository();
      when(() => usuals.watchUsuals())
          .thenAnswer((_) => Stream.value([eggsUsual(favorite: true), _bread()]));
    });

    blocTest<UsualsCubit, UsualsState>(
      'the hearted filter only shows hearted items',
      build: () => UsualsCubit(
        watchUsuals: WatchUsuals(usuals),
        toggleFavorite: ToggleFavorite(usuals),
        addUsualToList: AddUsualToList(usuals, MockListsRepository()),
      ),
      act: (cubit) async {
        await Future<void>.delayed(Duration.zero);
        cubit.setFilter(UsualsFilter.hearted);
      },
      verify: (cubit) => expect(cubit.state.visible.map((u) => u.name), ['Eggs']),
    );
  });

  group('SessionCubit', () {
    late MockAuthRepository auth;
    late MockSessionScope scope;

    setUp(() {
      auth = MockAuthRepository();
      scope = MockSessionScope();
      SessionCubit.closeDelay = Duration.zero;
      when(() => auth.startDemo()).thenAnswer((_) async => demoUser);
      when(() => auth.restore()).thenAnswer((_) async => null);
      when(() => auth.signOut()).thenAnswer((_) async {});
      when(() => scope.open(any())).thenAnswer((_) async {});
      when(() => scope.close()).thenAnswer((_) async {});
    });

    SessionCubit build({bool demo = false}) => SessionCubit(
          startDemo: StartDemo(auth),
          restoreSession: RestoreSession(auth),
          signOut: SignOut(auth),
          scope: scope,
          startInDemo: demo,
        );

    blocTest<SessionCubit, SessionState>(
      'without a saved session it shows the welcome screen',
      build: build,
      act: (cubit) => cubit.init(),
      expect: () => [const SessionState(status: SessionStatus.signedOut)],
    );

    blocTest<SessionCubit, SessionState>(
      'the web build opens the demo straight away',
      build: () => build(demo: true),
      act: (cubit) => cubit.init(),
      expect: () => [
        const SessionState(status: SessionStatus.unknown, busy: true),
        const SessionState(status: SessionStatus.signedIn, user: demoUser),
      ],
      verify: (_) => verify(() => scope.open(demoUser)).called(1),
    );

    blocTest<SessionCubit, SessionState>(
      'if the session can not open, it goes back to the welcome screen with a message',
      setUp: () => when(() => scope.open(any())).thenThrow(Exception('disk full')),
      build: build,
      act: (cubit) => cubit.startDemo(),
      skip: 1,
      expect: () => [
        isA<SessionState>()
            .having((s) => s.status, 'status', SessionStatus.signedOut)
            .having((s) => s.error, 'error', isNotNull),
      ],
    );

    blocTest<SessionCubit, SessionState>(
      'signing out closes the session',
      build: build,
      seed: () => const SessionState(status: SessionStatus.signedIn, user: demoUser),
      act: (cubit) => cubit.signOut(),
      expect: () => [const SessionState(status: SessionStatus.signedOut)],
      verify: (_) {
        verify(() => scope.close()).called(1);
        verify(() => auth.signOut()).called(1);
      },
    );
  });

  group('EmailSignInCubit', () {
    late MockAuthRepository auth;

    setUp(() {
      auth = MockAuthRepository();
      when(() => auth.sendEmailCode(any())).thenAnswer((_) async {});
      when(() => auth.verifyEmailCode(email: any(named: 'email'), code: any(named: 'code')))
          .thenAnswer((_) async => demoUser);
    });

    EmailSignInCubit build() =>
        EmailSignInCubit(sendCode: SendEmailCode(auth), verifyCode: VerifyEmailCode(auth));

    blocTest<EmailSignInCubit, EmailSignInState>(
      'goes to the code step after sending the email',
      build: build,
      act: (cubit) => cubit.sendCode('sirine@example.com'),
      expect: () => [
        const EmailSignInState(email: 'sirine@example.com', busy: true),
        const EmailSignInState(step: EmailStep.enterCode, email: 'sirine@example.com'),
      ],
    );

    blocTest<EmailSignInCubit, EmailSignInState>(
      'shows the error for a bad address',
      build: build,
      act: (cubit) => cubit.sendCode('nope'),
      expect: () => [
        const EmailSignInState(email: 'nope', busy: true),
        isA<EmailSignInState>().having((s) => s.error, 'error', isNotNull),
      ],
    );

    blocTest<EmailSignInCubit, EmailSignInState>(
      'a right code gives the signed-in user',
      build: build,
      seed: () => const EmailSignInState(step: EmailStep.enterCode, email: 'a@b.co'),
      act: (cubit) => cubit.verify('123456'),
      verify: (cubit) => expect(cubit.state.user, demoUser),
    );
  });
}

UsualItem _bread() => const UsualItem(
      id: 'usual-bread',
      name: 'Bread',
      category: ItemCategory.bakery,
      quantity: 1,
      unit: 'pcs',
      price: 3,
      favorite: false,
      timesBought: 3,
    );
