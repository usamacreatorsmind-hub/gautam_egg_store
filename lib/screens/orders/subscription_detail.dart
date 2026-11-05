import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sure_wholesaler/core/constants/app_constants.dart';
import 'package:sure_wholesaler/firebase/subscription_firestore_ds.dart';
import 'package:sure_wholesaler/models/subscription_model.dart';
import 'package:sure_wholesaler/widgets/app_loader.dart';

class SubscriptionDetail extends ConsumerWidget {
  final String subscriptionId;

  const SubscriptionDetail({required this.subscriptionId, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscriptionAsync =
        ref.watch(subscriptionByIdProvider(subscriptionId));

    return Scaffold(
      bottomNavigationBar: subscriptionAsync.when(
        data: (subscription) {
          if (subscription == null) {
            return const SizedBox.shrink();
          }
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: const Text(
                "Back",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          );
        },
        loading: () => const SizedBox.shrink(),
        error: (e, st) => const SizedBox.shrink(),
      ),
      appBar: AppBar(title: const Text("Subscription Details")),
      body: subscriptionAsync.when(
        data: (subscription) {
          if (subscription == null) {
            return const Center(child: Text("Subscription not found"));
          }

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: _SubscriptionHeader(subscription: subscription),
              ),

              /// INFO
              SliverToBoxAdapter(
                child: _SectionCard(
                  title: "Subscription Info",
                  child: Column(
                    children: [
                      _InfoRow("ID", subscription.id ?? ""),
                      _InfoRow("Status", subscription.status),
                      if (subscription.lastOrderId != null)
                        _InfoRow("Last Order", subscription.lastOrderId!),
                    ],
                  ),
                ),
              ),

              /// SCHEDULE
              SliverToBoxAdapter(
                child: _SectionCard(
                  title: "Schedule",
                  child: Column(
                    children: [
                      _InfoRow("Frequency",
                          subscription.repeatSchedule.frequency.name),
                      _InfoRow(
                        "Time",
                        "${subscription.repeatSchedule.timeSlot.hour}:${subscription.repeatSchedule.timeSlot.minute}",
                      ),
                      if (subscription.nextDeliveryAt != null)
                        _InfoRow("Next Delivery",
                            _formatDate(subscription.nextDeliveryAt!)),
                    ],
                  ),
                ),
              ),

              /// PRODUCTS
              SliverToBoxAdapter(
                child: _SectionCard(
                  title: "Products",
                  child: Column(
                    children: subscription.productDetails.entries.map((entry) {
                      final productId = entry.key.split('_').first;
                      final product = subscription.products.firstWhere(
                        (p) => p.id == productId,
                      );
                      final detail = entry.value;

                      return _ProductRow(product.name, detail.quantity,
                          detail.pricePerPack, detail.finalAmount);
                    }).toList(),
                  ),
                ),
              ),

              /// BILLING
              SliverToBoxAdapter(
                child: _SectionCard(
                  title: "Billing",
                  child: Column(
                    children: [
                      _BillRow("Subtotal", subscription.subtotal),
                      _BillRow("Discount", -subscription.discount),
                      _BillRow("Delivery", subscription.deliveryCharge),
                      _BillRow("Platform Fee",
                          subscription.taxConfig.platformCharge > 0 ? subscription.taxConfig.platformCharge : 5.0),
                      _BillRow(
                          "Packing Fee", subscription.taxConfig.handlingCharge > 0 ? subscription.taxConfig.handlingCharge : 5.0),
                      const Divider(),
                      _BillRow("Total", subscription.total, isBold: true),
                    ],
                  ),
                ),
              ),

              /// ADDRESS
              SliverToBoxAdapter(
                child: _SectionCard(
                  title: "Delivery Address",
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(subscription.user.userName,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(subscription.deliveryAddress.phone),
                      Text(subscription.deliveryAddress.fullAddress()),
                    ],
                  ),
                ),
              ),

              /// USER
              SliverToBoxAdapter(
                child: _SectionCard(
                  title: "Customer",
                  child: Column(
                    children: [
                      _InfoRow("Name", subscription.user.userName),
                      _InfoRow("Phone", subscription.user.mobileNo),
                      _InfoRow("Email", subscription.user.email),
                    ],
                  ),
                ),
              ),

              /// TIMELINE
              SliverToBoxAdapter(
                child: _SectionCard(
                  title: "Timeline",
                  child: Column(
                    children: [
                      _InfoRow("Created", _formatDate(subscription.createdAt)),
                      _InfoRow("Updated", _formatDate(subscription.updatedAt)),
                    ],
                  ),
                ),
              ),

              /// ACTIONS
              SliverToBoxAdapter(
                child: _Actions(subscription: subscription),
              ),

              const SliverToBoxAdapter(child: SizedBox(height: 30)),
            ],
          );
        },
        loading: () => const Center(child: AppLoader()),
        error: (e, st) => Center(child: Text("Error: $e")),
      ),
    );
  }
}

//// ================= HEADER =================

class _SubscriptionHeader extends StatelessWidget {
  final SubscriptionModel subscription;

  const _SubscriptionHeader({required this.subscription});

  @override
  Widget build(BuildContext context) {
    Color color;

    switch (subscription.status) {
      case "active":
        color = AppColors.success;
        break;
      case "paused":
        color = AppColors.warning;
        break;
      case "cancelled":
        color = AppColors.error;
        break;
      default:
        color = AppColors.grey500;
    }

    return Card(
      margin: const EdgeInsets.all(12),
      child: ListTile(
        leading: const Icon(Icons.autorenew),
        title: const Text("Subscription"),
        trailing: Chip(
          label: Text(subscription.status.toUpperCase()),
          backgroundColor: color.withOpacity(0.2),
        ),
        subtitle: subscription.nextDeliveryAt != null
            ? Text("Next: ${_formatDate(subscription.nextDeliveryAt!)}")
            : null,
      ),
    );
  }
}

//// ================= ACTIONS =================
class _Actions extends StatelessWidget {
  final SubscriptionModel subscription;

  const _Actions({required this.subscription});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          /// LEFT BUTTON (Pause / Resume)
          if (subscription.isActive || subscription.isPaused)
            Expanded(
              child: ElevatedButton(
                onPressed: () {},
                child: Text(
                  subscription.isActive ? "Pause" : "Resume",
                ),
              ),
            ),

          if (subscription.isActive || subscription.isPaused)
            const SizedBox(width: 10),

          /// RIGHT BUTTON (Cancel)
          Expanded(
            child: OutlinedButton(
              onPressed: () {},
              child: const Text("Cancel"),
            ),
          ),
        ],
      ),
    );
  }
}

//// ================= COMMON UI =================

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _BillRow extends StatelessWidget {
  final String label;
  final double value;
  final bool isBold;

  const _BillRow(this.label, this.value, {this.isBold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text("₹${value.toStringAsFixed(2)}",
              style: TextStyle(
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}

class _ProductRow extends StatelessWidget {
  final String name;
  final int qty;
  final double price;
  final double total;

  const _ProductRow(this.name, this.qty, this.price, this.total);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(name),
      subtitle: Text("Qty: $qty × ₹$price"),
      trailing: Text("₹$total"),
    );
  }
}

//// ================= UTILS =================

String _formatDate(DateTime date) {
  return DateFormat("dd MMM yyyy, hh:mm a").format(date);
}
