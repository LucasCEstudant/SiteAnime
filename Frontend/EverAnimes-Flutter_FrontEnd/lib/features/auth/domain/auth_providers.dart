import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../data/auth_remote_datasource.dart';
import '../domain/auth_repository.dart';

/// Provider do datasource remoto de autenticação.
final authDatasourceProvider = Provider<AuthRemoteDatasource>((ref) {
  return AuthRemoteDatasource(ref.read(apiClientProvider));
});

/// Provider do repositório de autenticação.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.read(authDatasourceProvider));
});
