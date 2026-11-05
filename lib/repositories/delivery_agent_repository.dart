import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:sure_wholesaler/core/constants/app_constants.dart';
import 'package:sure_wholesaler/models/DeliveryAgentModel.dart';

abstract class DeliveryAgentRepository {
  Stream<DeliveryAgentModel> getDeliveryAgent(String agentId);
  Future<DeliveryAgentModel> getDeliveryAgentByAgentId(String agentId);
}

class DeliveryAgentRepositoryImpl implements DeliveryAgentRepository {
  final FirebaseFirestore firestore = AppConfig.firestore;

  static const String _collection = 'delivery_agents';

  @override
  Stream<DeliveryAgentModel> getDeliveryAgent(String agentId) {
    return firestore.collection(_collection).doc(agentId).snapshots().map((snapshot) {
      if (!snapshot.exists) {
        throw Exception('Delivery agent not found');
      }
      return DeliveryAgentModel.fromJson(snapshot.data()!);
    });
  }

  @override
  Future<DeliveryAgentModel> getDeliveryAgentByAgentId(String agentId) async {
    final doc = await firestore.collection(_collection).doc(agentId).get();
    if (!doc.exists) {
      throw Exception('Delivery agent not found');
    }
    return DeliveryAgentModel.fromJson(doc.data()!);
  }
}
