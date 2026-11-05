import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sure_wholesaler/models/flash_sale_model.dart';
import 'package:sure_wholesaler/services/flash_sale_service.dart';

final flashSaleServiceProvider =
    Provider<FlashSaleService>((ref) => FlashSaleService());

final flashSalesProvider = StreamProvider<List<FlashSaleModel>>((ref) {
  return ref.read(flashSaleServiceProvider).streamActiveFlashSales();
});

/// The first currently-live flash sale, or null if none is running.
final liveFlashSaleProvider = Provider<FlashSaleModel?>((ref) {
  return ref.watch(flashSalesProvider).maybeWhen(
        data: (sales) {
          for (final s in sales) {
            if (s.isLive) return s;
          }
          return null;
        },
        orElse: () => null,
      );
});
