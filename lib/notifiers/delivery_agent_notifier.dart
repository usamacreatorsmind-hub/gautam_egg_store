import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:sure_wholesaler/models/DeliveryAgentModel.dart';
import 'package:sure_wholesaler/repositories/delivery_agent_repository.dart';

class DeliveryAgentNotifier
    extends StateNotifier<AsyncValue<DeliveryAgentModel?>> {
  final DeliveryAgentRepository _repository;
  final String? _agentId;
  StreamSubscription<DeliveryAgentModel?>? _subscription;

  DeliveryAgentNotifier(this._repository, this._agentId)
      : super(const AsyncValue.loading()) {
    _init();
  }

  void _init() {
    if (_agentId == null) {
      state = const AsyncValue.data(null);
      return;
    }

    _subscription = _repository.getDeliveryAgent(_agentId!).listen(
      (agent) {
        state = AsyncValue.data(agent);
      },
      onError: (error, stackTrace) {
        state = AsyncValue.error(error, stackTrace);
      },
    );
  }

  Future<DeliveryAgentModel?> getDeliveryAgentByAgentId(String agentId) async {
    return await _repository.getDeliveryAgentByAgentId(agentId);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

final deliveryAgentProvider = StateNotifierProvider.family<
    DeliveryAgentNotifier,
    AsyncValue<DeliveryAgentModel?>,
    String?>((ref, agentId) {
  final repo = ref.read(deliveryAgentRepositoryProvider);
  return DeliveryAgentNotifier(repo, agentId);
});

final deliveryAgentRepositoryProvider =
    Provider<DeliveryAgentRepository>((ref) {
  return DeliveryAgentRepositoryImpl();
});
