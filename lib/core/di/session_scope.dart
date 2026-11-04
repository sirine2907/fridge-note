import 'package:get_it/get_it.dart';

import '../../features/auth/domain/entities/app_user.dart';
import '../../features/invite/data/demo_invite_repository.dart';
import '../../features/invite/domain/repositories/invite_repository.dart';
import '../../features/invite/domain/usecases/invite_usecases.dart';
import '../../features/lists/data/repositories/lists_repository_impl.dart';
import '../../features/lists/domain/entities/member.dart';
import '../../features/lists/domain/repositories/lists_repository.dart';
import '../../features/lists/domain/usecases/add_item.dart';
import '../../features/lists/domain/usecases/create_list.dart';
import '../../features/lists/domain/usecases/item_actions.dart';
import '../../features/lists/domain/usecases/trip_actions.dart';
import '../../features/lists/domain/usecases/watch_activity.dart';
import '../../features/lists/domain/usecases/watch_items.dart';
import '../../features/lists/domain/usecases/watch_lists.dart';
import '../../features/lists/presentation/bloc/current_list_cubit.dart';
import '../../features/profile/data/profile_repository_impl.dart';
import '../../features/profile/domain/repositories/profile_repository.dart';
import '../../features/profile/domain/usecases/profile_usecases.dart';
import '../../features/usuals/data/usuals_repository_impl.dart';
import '../../features/usuals/domain/repositories/usuals_repository.dart';
import '../../features/usuals/domain/usecases/usual_actions.dart';
import '../config/env.dart';
import '../database/app_database.dart';
import '../database/connection/memory.dart';
import '../database/connection/persistent.dart';
import '../demo/demo_partner.dart';
import '../demo/demo_seed.dart';
import '../demo/fake_remote.dart';
import '../sync/local_clock.dart';
import '../sync/local_store.dart';
import '../sync/sync_engine.dart';
import '../sync/sync_remote.dart';

/// Everything that belongs to one signed-in person: their database, the sync
/// engine and the repositories. Opened on sign-in, thrown away on sign-out.
abstract class SessionScope {
  Future<void> open(AppUser user);

  Future<void> close();
}

/// Builds the server side for a real (non demo) user. Set up in injection.dart.
typedef RemoteFactory = ({SyncRemote remote, InviteRepository invites}) Function(AppUser user);

class GetItSessionScope implements SessionScope {
  GetItSessionScope(this.getIt, {this.realRemote});

  final GetIt getIt;
  final RemoteFactory? realRemote;

  static const scopeName = 'session';

  @override
  Future<void> open(AppUser user) async {
    await close();

    final db = AppDatabase(
      user.isDemo ? openInMemoryDatabase() : openPersistentDatabase(user.id),
    );
    final store = LocalStore(db);
    final clock = LocalClock();

    SyncRemote remote;
    InviteRepository invites;
    DemoPartner? partner;
    if (user.isDemo) {
      final fake = FakeRemote(userId: user.id, seed: DemoSeed.build());
      partner = DemoPartner(fake);
      remote = fake;
      invites = DemoInviteRepository(fake);
    } else {
      final factory = realRemote;
      if (factory == null) {
        await db.close();
        throw StateError('This build has no backend configured');
      }
      final real = factory(user);
      remote = real.remote;
      invites = real.invites;
    }

    final sync = SyncEngine(db: db, store: store, remote: remote, clock: clock);

    getIt.pushNewScope(
      scopeName: scopeName,
      init: (sl) {
        sl
          ..registerSingleton<AppUser>(user)
          ..registerSingleton<AppDatabase>(db)
          ..registerSingleton<LocalStore>(store)
          ..registerSingleton<LocalClock>(clock)
          ..registerSingleton<SyncRemote>(remote)
          ..registerSingleton<SyncEngine>(sync)
          ..registerSingleton<InviteRepository>(invites);
        if (remote is FakeRemote) sl.registerSingleton<FakeRemote>(remote);
        if (partner != null) sl.registerSingleton<DemoPartner>(partner);

        // Repositories
        sl
          ..registerLazySingleton<ListsRepository>(
            () => ListsRepositoryImpl(db: db, store: store, clock: clock, userId: user.id),
          )
          ..registerLazySingleton<UsualsRepository>(
            () => UsualsRepositoryImpl(db: db, store: store, clock: clock),
          )
          ..registerLazySingleton<ProfileRepository>(
            () => ProfileRepositoryImpl(db: db, store: store, clock: clock),
          );

        // Use cases
        sl
          ..registerFactory(() => WatchLists(sl()))
          ..registerFactory(() => WatchList(sl()))
          ..registerFactory(() => WatchItems(sl()))
          ..registerFactory(() => WatchActivity(sl()))
          ..registerFactory(() => CreateList(sl()))
          ..registerFactory(() => AddItem(sl()))
          ..registerFactory(() => ToggleItem(sl()))
          ..registerFactory(() => ChangeQuantity(sl()))
          ..registerFactory(() => RemoveItem(sl()))
          ..registerFactory(() => ReorderItems(sl()))
          ..registerFactory(() => StartTrip(sl()))
          ..registerFactory(() => FinishTrip(sl()))
          ..registerFactory(() => NudgeShopper(sl()))
          ..registerFactory(() => WatchUsuals(sl()))
          ..registerFactory(() => ToggleFavorite(sl()))
          ..registerFactory(() => AddUsualToList(sl(), sl()))
          ..registerFactory(() => WatchProfile(sl()))
          ..registerFactory(() => UpdateProfile(sl()))
          ..registerFactory(() => CreateInviteLink(sl(), baseUrl: Env.inviteBaseUrl))
          ..registerFactory(() => PreviewInvite(sl()))
          ..registerFactory(() => JoinList(sl()));

        sl.registerLazySingleton<CurrentListCubit>(() => CurrentListCubit(sl()));
      },
      dispose: () async {
        // Stop things in the opposite order they were started.
        partner?.stop();
        if (getIt.isRegistered<CurrentListCubit>()) {
          await getIt<CurrentListCubit>().close();
        }
        await sync.dispose();
        await remote.dispose();
        await store.dispose();
        await db.close();
      },
    );

    await getIt<ProfileRepository>().ensureProfile(
      Member(id: user.id, name: user.name, color: user.color),
    );

    // Pull the first snapshot before the home screen shows. If the network is
    // slow we don't wait for it: the screens read the local database anyway.
    await sync.start().timeout(const Duration(seconds: 4), onTimeout: () {});
    partner?.start();
  }

  @override
  Future<void> close() async {
    if (getIt.hasScope(scopeName)) {
      await getIt.popScopesTill(scopeName);
    }
  }
}
