/// Format d'impression pour Mediaclip / Supabase orders.
enum PrintFormat {
  standard,
  polaroid,
  strip,
}

/// Données de commande passées du choix de format jusqu'à la confirmation.
class OrderCheckout {
  const OrderCheckout({
    required this.formatTitle,
    required this.formatSubtitle,
    required this.subtotal,
    required this.rollId,
    required this.format,
    this.orderId,
    this.photoCount = 24,
    this.deliveryLabel = 'Standard (3-5 days)',
  });

  final String formatTitle;
  final String formatSubtitle;
  final double subtotal;
  final String rollId;
  final PrintFormat format;
  /// Renseigné après upsert Supabase au moment du paiement.
  final String? orderId;
  final int photoCount;
  final String deliveryLabel;

  static const _referenceSubtotal = 22.0;
  static const _referenceTaxes = 3.20;

  double get shipping => 0;

  /// TPS + TVQ (proportionnel au sous-total, calibré sur 22,00 $ → 3,20 $).
  double get taxes => subtotal * (_referenceTaxes / _referenceSubtotal);

  double get total => subtotal + taxes;

  String get formatApiValue => switch (format) {
        PrintFormat.standard => 'standard',
        PrintFormat.polaroid => 'polaroid',
        PrintFormat.strip => 'strip',
      };

  String get formatLine {
    final s = formatSubtitle.toLowerCase();
    if (s.contains('4x6')) return '4x6 prints';
    if (s.contains('3x3')) return '3x3 prints';
    if (s.contains('strip')) return 'Photo strips';
    return formatSubtitle;
  }

  static PrintFormat formatFromTitle(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('polaroid')) return PrintFormat.polaroid;
    if (lower.contains('strip')) return PrintFormat.strip;
    return PrintFormat.standard;
  }
}
