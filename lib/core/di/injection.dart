// Injection typée à la compilation (get_it + injectable).
//
// Les trois modules d'UX sont enregistrés ici en singletons : le palier, la
// politique de notification et le bus de moments doivent avoir UNE instance,
// sinon la garantie « un seul endroit décide » ne tient plus (CONSTITUTION
// P9 et P10).

import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/listing/data/datasources/listing_remote_datasource.dart';
import '../../features/listing/data/repositories/listing_repository_impl.dart';
import '../../features/listing/domain/repositories/listing_repository.dart';
import '../moments/moment.dart';
import '../moments/savings_counter.dart';
import '../notifications/notification_policy.dart';
import '../progression/stage_resolver.dart';

final getIt = GetIt.instance;

@InjectableInit(preferRelativeImports: true, asExtension: false)
Future<void> configureDependencies() async {
  // Enregistrements manuels des modules d'UX — volontairement explicites :
  // ils sont trop structurants pour être découverts par génération de code.
  getIt
    ..registerLazySingleton<StageResolver>(DefaultStageResolver.new)
    ..registerLazySingleton<NotificationPolicy>(DefaultNotificationPolicy.new)
    ..registerLazySingleton<MomentBus>(MomentBus.new)
    ..registerLazySingleton<SavingsCounter>(SavingsCounter.new);

  // Feature `listing` — le seul point où la couche data est câblée.
  // La présentation ne connaît que l'interface de domaine.
  getIt
    ..registerLazySingleton<SupabaseClient>(() => Supabase.instance.client)
    ..registerLazySingleton<ListingRemoteDataSource>(
      () => ListingRemoteDataSource(getIt<SupabaseClient>()),
    )
    ..registerLazySingleton<ListingRepository>(
      () => ListingRepositoryImpl(getIt<ListingRemoteDataSource>()),
    );

  // TODO(E0.1) : brancher $initGetIt(getIt) une fois build_runner exécuté.
}
