import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';
import '../data/dtos/user_dtos.dart';
import '../data/users_remote_datasource.dart';

/// Provider do datasource de usuários.
final usersDatasourceProvider = Provider<UsersRemoteDatasource>((ref) {
  return UsersRemoteDatasource(ref.read(apiClientProvider));
});

/// Provider que carrega a lista de usuários.
/// Pode ser invalidado para forçar reload.
final usersListProvider = FutureProvider<List<UserDto>>((ref) async {
  final datasource = ref.read(usersDatasourceProvider);
  return datasource.getAll();
});
