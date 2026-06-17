import 'package:supabase_flutter/supabase_flutter.dart';

/// Appels aux Edge Functions Supabase (Mediaclip).
class EdgeFunctionService {
  EdgeFunctionService._();

  static final EdgeFunctionService instance = EdgeFunctionService._();

  SupabaseClient get _supabase => Supabase.instance.client;

  /// Étapes 1–6 : crée la commande Mediaclip (release=false, en attente de paiement).
  Future<Map<String, dynamic>> processMediaclipOrder({
    required String rollId,
    required String format,
    required double amount,
    required String orderId,
  }) async {
    final response = await _supabase.functions.invoke(
      'process-mediaclip-order',
      body: {
        'rollId': rollId,
        'format': format,
        'amount': amount,
        'orderId': orderId,
      },
    );

    if (response.status != 200) {
      final data = response.data;
      final message = data is Map
          ? data['error']?.toString() ?? data.toString()
          : data?.toString();
      throw Exception(message ?? 'Mediaclip error');
    }

    final data = response.data;
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    throw Exception('Unexpected Mediaclip response');
  }

  /// Étape 7 : release après paiement (Stripe plus tard ; debug manuel pour l'instant).
  Future<void> releaseMediaclipOrder({
    required String hubOrderId,
    required String orderId,
  }) async {
    final response = await _supabase.functions.invoke(
      'release-mediaclip-order',
      body: {
        'hubOrderId': hubOrderId,
        'orderId': orderId,
      },
    );

    if (response.status != 200) {
      final data = response.data;
      final message = data is Map
          ? data['error']?.toString() ?? data.toString()
          : data?.toString();
      throw Exception(message ?? 'Release error');
    }
  }
}
