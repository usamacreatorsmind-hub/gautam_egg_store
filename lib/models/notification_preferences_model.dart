class NotificationPreferencesModel {
  final bool order;
  final bool delivery;
  final bool product;
  final bool stock;
  final bool offer;
  final bool system;

  const NotificationPreferencesModel({
    this.order = true,
    this.delivery = true,
    this.product = true,
    this.stock = true,
    this.offer = true,
    this.system = true,
  });

  bool get allEnabled =>
      order && delivery && product && stock && offer && system;

  factory NotificationPreferencesModel.fromMap(Map<String, dynamic> map) {
    return NotificationPreferencesModel(
      order: map['order'] ?? true,
      delivery: map['delivery'] ?? true,
      product: map['product'] ?? true,
      stock: map['stock'] ?? true,
      offer: map['offer'] ?? true,
      system: map['system'] ?? true,
    );
  }

  Map<String, dynamic> toMap() => {
        'order': order,
        'delivery': delivery,
        'product': product,
        'stock': stock,
        'offer': offer,
        'system': system,
      };

  NotificationPreferencesModel copyWith({
    bool? order,
    bool? delivery,
    bool? product,
    bool? stock,
    bool? offer,
    bool? system,
  }) {
    return NotificationPreferencesModel(
      order: order ?? this.order,
      delivery: delivery ?? this.delivery,
      product: product ?? this.product,
      stock: stock ?? this.stock,
      offer: offer ?? this.offer,
      system: system ?? this.system,
    );
  }

  NotificationPreferencesModel withAll(bool enabled) {
    return NotificationPreferencesModel(
      order: enabled,
      delivery: enabled,
      product: enabled,
      stock: enabled,
      offer: enabled,
      system: enabled,
    );
  }
}
