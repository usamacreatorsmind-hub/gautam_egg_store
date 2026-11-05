// Centralised status constants for the entire app.
// Use these instead of bare string literals to avoid typos and make
// refactoring safe — a single change here propagates everywhere.

abstract final class OrderStatus {
  static const String pending = 'pending';
  static const String confirmed = 'confirmed';
  static const String packed = 'packed';
  static const String outForDelivery = 'out_for_delivery';
  static const String delivered = 'delivered';
  static const String cancelled = 'cancelled';
}

abstract final class PaymentStatus {
  static const String paid = 'paid';
  static const String unpaid = 'unpaid';
  static const String pending = 'pending';
  static const String awaitingPayment = 'awaiting_payment';
}

abstract final class PaymentMethod {
  static const String cod = 'COD';
  static const String online = 'ONLINE'; 
}

abstract final class EntityStatus {
  static const String active = 'active';
  static const String inactive = 'inactive';
}

abstract final class SliderStatus {
  static const String active = 'active';
  static const String upcoming = 'upcoming';
  static const String expired = 'expired';
}

/// Delivery-agent specific statuses.
/// Stored with capital-I 'Inactive' in Firestore for legacy reasons;
/// isActive comparisons use toLowerCase() to stay case-insensitive.
abstract final class AgentStatus {
  static const String active = 'active';
  static const String inactive = 'Inactive';
}

/// Lifecycle for an eco_subscription document.
/// pending  → admin verifies → active
/// active   → Cloud Function auto-creates orders on schedule
/// paused   → user-initiated pause (no orders created)
/// cancelled → permanently stopped
abstract final class SubscriptionStatus {
  static const String pending = 'pending';
  static const String active = 'active';
  static const String paused = 'paused';
  static const String cancelled = 'cancelled';
}

abstract final class KycStatus {
  static const String draft = 'draft';
  static const String pending = 'pending';
  static const String approved = 'approved';
  static const String rejected = 'rejected';
}

abstract final class BusinessType {
  static const String soleProprietor = 'sole_proprietor';
  static const String partnership = 'partnership';
  static const String privateLimited = 'private_limited';
  static const String llp = 'llp';
}
