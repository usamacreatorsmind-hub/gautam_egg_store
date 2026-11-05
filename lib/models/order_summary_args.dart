// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:sure_wholesaler/models/address_model.dart';
import 'package:sure_wholesaler/models/delivery_model.dart';
import 'package:sure_wholesaler/screens/cart/repeat_schdule_model.dart';
import 'package:sure_wholesaler/models/product_model.dart';

class OrderSummaryArgs {
  final List<ProductModel> products;
  final FullDeliveryAddress deliveryAddress;
  final DeliveryType deliveryType;
  final bool isSubscription;
  final String? warehouseId;
  final RepeatSchedule? repeatSchedule;

  OrderSummaryArgs({
    required this.products,
    required this.deliveryAddress,
    required this.deliveryType,
    required this.isSubscription,
    required this.warehouseId,
    this.repeatSchedule,
  });

  @override
  String toString() =>
      'OrderSummaryArgs(products: $products, deliveryAddress: $deliveryAddress, deliveryType: $deliveryType, isSubscription: $isSubscription, warehouseId: $warehouseId, repeatSchedule: $repeatSchedule)';
}
