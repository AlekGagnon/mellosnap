import 'package:supabase_flutter/supabase_flutter.dart';

/// Adresses livraison + facturation enregistrées pour le checkout.
class CheckoutProfile {
  const CheckoutProfile({
    this.name,
    this.address,
    this.city,
    this.province,
    this.postalCode,
    this.billingSameAsShipping = true,
    this.billingName,
    this.billingAddress,
    this.billingCity,
    this.billingProvince,
    this.billingPostalCode,
  });

  final String? name;
  final String? address;
  final String? city;
  final String? province;
  final String? postalCode;
  final bool billingSameAsShipping;
  final String? billingName;
  final String? billingAddress;
  final String? billingCity;
  final String? billingProvince;
  final String? billingPostalCode;

  bool get hasShipping =>
      _filled(name) && _filled(address) && _filled(city) && _filled(postalCode);

  bool get hasBilling =>
      _filled(billingName) &&
      _filled(billingAddress) &&
      _filled(billingCity) &&
      _filled(billingPostalCode);

  static bool _filled(String? value) => value != null && value.trim().isNotEmpty;

  factory CheckoutProfile.fromRow(Map<String, dynamic> row) {
    return CheckoutProfile(
      name: row['name'] as String?,
      address: row['address'] as String?,
      city: row['city'] as String?,
      province: row['province'] as String?,
      postalCode: row['postal_code'] as String?,
      billingSameAsShipping: row['billing_same_as_shipping'] as bool? ?? true,
      billingName: row['billing_name'] as String?,
      billingAddress: row['billing_address'] as String?,
      billingCity: row['billing_city'] as String?,
      billingProvince: row['billing_province'] as String?,
      billingPostalCode: row['billing_postal_code'] as String?,
    );
  }
}

/// Profil utilisateur (adresses livraison + facturation pour Mediaclip).
class ProfileService {
  ProfileService._();

  static SupabaseClient get _client => Supabase.instance.client;

  static Future<CheckoutProfile?> fetchCheckoutProfile(String userId) async {
    final row = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (row == null) return null;
    return CheckoutProfile.fromRow(Map<String, dynamic>.from(row));
  }

  static Future<void> upsertCheckoutAddresses({
    required String userId,
    required String name,
    required String address,
    required String city,
    required String province,
    required String postalCode,
    required bool billingSameAsShipping,
    required String billingName,
    required String billingAddress,
    required String billingCity,
    required String billingProvince,
    required String billingPostalCode,
  }) async {
    final shippingName = name.trim();
    final shippingAddress = address.trim();
    final shippingCity = city.trim();
    final shippingProvince = province.trim();
    final shippingPostalCode = postalCode.trim().toUpperCase();

    final resolvedBillingName =
        billingSameAsShipping ? shippingName : billingName.trim();
    final resolvedBillingAddress =
        billingSameAsShipping ? shippingAddress : billingAddress.trim();
    final resolvedBillingCity =
        billingSameAsShipping ? shippingCity : billingCity.trim();
    final resolvedBillingProvince =
        billingSameAsShipping ? shippingProvince : billingProvince.trim();
    final resolvedBillingPostalCode = billingSameAsShipping
        ? shippingPostalCode
        : billingPostalCode.trim().toUpperCase();

    await _client.from('profiles').upsert({
      'id': userId,
      'name': shippingName,
      'address': shippingAddress,
      'city': shippingCity,
      'province': shippingProvince,
      'postal_code': shippingPostalCode,
      'billing_same_as_shipping': billingSameAsShipping,
      'billing_name': resolvedBillingName,
      'billing_address': resolvedBillingAddress,
      'billing_city': resolvedBillingCity,
      'billing_province': resolvedBillingProvince,
      'billing_postal_code': resolvedBillingPostalCode,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }
}
