import 'package:supabase_flutter/supabase_flutter.dart';

/// Commandes Supabase (table `orders`) avant envoi Mediaclip.
class OrderService {
  OrderService._();

  static SupabaseClient get _client => Supabase.instance.client;

  /// Crée ou met à jour la commande pending pour ce rouleau (une seule par roll_id).
  static Future<String> upsertPendingOrder({
    required String userId,
    required String rollId,
    required String format,
    required double amount,
    required double taxes,
  }) async {
    final existing = await _client
        .from('orders')
        .select('id')
        .eq('user_id', userId)
        .eq('roll_id', rollId)
        .eq('status', 'pending')
        .maybeSingle();

    if (existing != null) {
      final id = existing['id'] as String;
      await _client.from('orders').update({
        'format': format,
        'amount': amount,
        'taxes': taxes,
      }).eq('id', id);
      return id;
    }

    final row = await _client
        .from('orders')
        .insert({
          'user_id': userId,
          'roll_id': rollId,
          'format': format,
          'amount': amount,
          'taxes': taxes,
          'status': 'pending',
        })
        .select('id')
        .single();

    return row['id'] as String;
  }
}
