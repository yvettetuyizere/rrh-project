// lib/repositories/injection.dart
import 'package:get_it/get_it.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'report_repository.dart';

final getIt = GetIt.instance;

void configureRepositoryDependencies() {
  // Register Firebase instances
  getIt.registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance);
  getIt.registerLazySingleton<FirebaseStorage>(() => FirebaseStorage.instance);
  
  // Register ReportRepository
  getIt.registerLazySingleton<ReportRepository>(
    () => ReportRepository(getIt<FirebaseFirestore>(), getIt<FirebaseStorage>()),
  );
}