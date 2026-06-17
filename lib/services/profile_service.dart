import 'package:supabase_flutter/supabase_flutter.dart';

/// Profil utilisateur (adresse de livraison pour Mediaclip).
class ProfileService {
  ProfileService._();

  static SupabaseClient get _client => Supabase.instance.client;

  static Future<void> upsertShippingAddress({
    required String userId,
    required String name,
    required String address,
    required String city,
    required String province,
    required String postalCode,
  }) async {
    await _client.from('profiles').upsert({
      'id': userId,
      'name': name.trim(),
      'address': address.trim(),
      'city': city.trim(),
      'province': province.trim(),
      'postal_code': postalCode.trim().toUpperCase(),
      'updated_at': DateTime.now().toIso8601String(),
    });
  }
}
