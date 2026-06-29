import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

/// Résultat d'une tentative de paiement Stripe.
sealed class PaymentResult {
  const PaymentResult();
}

class PaymentSuccess extends PaymentResult {
  const PaymentSuccess({this.paymentIntentId});

  final String? paymentIntentId;
}

class PaymentFailure extends PaymentResult {
  const PaymentFailure(this.message);

  final String message;
}

class PaymentCancelled extends PaymentResult {
  const PaymentCancelled();
}

/// Paiement via Stripe Payment Sheet (PaymentIntent créé côté serveur).
class PaymentService {
  PaymentService._();

  static String get publishableKey =>
      dotenv.env['STRIPE_PUBLISHABLE_KEY']?.trim() ?? '';

  static bool get isConfigured =>
      publishableKey.isNotEmpty && publishableKey.startsWith('pk_');

  static Future<void> initialize() async {
    if (!isConfigured) {
      if (kDebugMode) {
        debugPrint(
          'STRIPE_PUBLISHABLE_KEY missing — checkout payments disabled.',
        );
      }
      return;
    }

    Stripe.publishableKey = publishableKey;
    await Stripe.instance.applySettings();
  }

  static Future<PaymentResult> presentPaymentSheet({
    required String clientSecret,
    String merchantDisplayName = 'MelloSnap',
  }) async {
    if (!isConfigured) {
      return const PaymentFailure(
        'Stripe is not configured. Add STRIPE_PUBLISHABLE_KEY to .env',
      );
    }

    try {
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: merchantDisplayName,
          googlePay: PaymentSheetGooglePay(
            merchantCountryCode: 'CA',
            currencyCode: 'CAD',
            testEnv: kDebugMode,
          ),
          style: ThemeMode.system,
        ),
      );

      await Stripe.instance.presentPaymentSheet();

      return const PaymentSuccess();
    } on StripeException catch (e) {
      if (e.error.code == FailureCode.Canceled) {
        return const PaymentCancelled();
      }
      return PaymentFailure(
        e.error.localizedMessage ?? 'Payment could not be completed.',
      );
    } catch (e) {
      return PaymentFailure(e.toString());
    }
  }
}
