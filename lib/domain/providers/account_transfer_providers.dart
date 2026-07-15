import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/account_transfer.dart';
import '../../data/repositories/account_transfer_repository.dart';
import 'goal_providers.dart';

final accountTransferRepositoryProvider =
    Provider<AccountTransferRepository>((ref) {
  return AccountTransferRepository(ref.watch(isarProvider));
});

final allAccountTransfersProvider =
    StreamProvider<List<AccountTransfer>>((ref) {
  return ref.watch(accountTransferRepositoryProvider).watchAllTransfers();
});
