import 'package:sure_wholesaler/core/constants/collections.dart';
import 'package:sure_wholesaler/generics/generic_firestore.dart';
import 'package:sure_wholesaler/models/flash_sale_model.dart';

class FlashSaleService {
  final FirestoreRepository<FlashSaleModel> _repo = FirestoreRepository(
    collectionPath: Collections.flashSales,
    fromFirestore: FlashSaleModel.fromFirestore,
  );

  Stream<List<FlashSaleModel>> streamActiveFlashSales() =>
      _repo.streamQuery((q) => q.where('isActive', isEqualTo: true));
}
