/// Résultat d'une tentative de paiement (Stripe à brancher plus tard).
sealed class PaymentResult {
  const PaymentResult();
}

class PaymentSuccess extends PaymentResult {
  const PaymentSuccess();
}

class PaymentFailure extends PaymentResult {
  const PaymentFailure(this.message);

  final String message;
}

/// Simulation de paiement pendant l'intégration Stripe.
class PaymentService {
  /// Délai réseau simulé avant succès ou échec.
  static const processingDuration = Duration(seconds: 2);

  /// Pour tester l'échec en dev : code postal `FAIL` (insensible à la casse).
  static Future<PaymentResult> processPayment({
    required String postalCode,
  }) async {
    await Future<void>.delayed(processingDuration);

    if (postalCode.trim().toUpperCase() == 'FAIL') {
      return const PaymentFailure(
        'Payment could not be completed. Check your card or try again.',
      );
    }

    return const PaymentSuccess();
  }
}
