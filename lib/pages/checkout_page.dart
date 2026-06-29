import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../components/mello_logo.dart';
import '../models/order_checkout.dart';
import '../services/auth_service.dart';
import '../services/edge_function_service.dart';
import '../services/order_service.dart';
import '../services/payment_service.dart';
import '../services/profile_service.dart';
import '../services/roll_repository.dart';
import '../services/roll_storage_service.dart';
import 'order_confirmation_page.dart';

const _bg = Color(0xFFFFF9F6);
const _accent = Color(0xFFE89F94);
const _accentDeep = Color(0xFFD8897E);
const _ink = Color(0xFF2A2628);
const _muted = Color(0xFF6B5B5F);
const _border = Color(0xFF2A2628);
const _fieldFill = Color(0xFFFFF0ED);
const _errorBg = Color(0xFFFFE8E5);
const _errorText = Color(0xFFB85C52);

final _postalCodePattern = RegExp(
  r'^[A-Za-z]\d[A-Za-z][ -]?\d[A-Za-z]\d$',
);

/// Paiement : adresse de livraison validée + récapitulatif (scrollable).
class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key, required this.order});

  final OrderCheckout order;

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _postalController = TextEditingController();
  final _countryController = TextEditingController(text: 'Canada');

  static const _provinces = [
    'Quebec',
    'Ontario',
    'British Columbia',
    'Alberta',
    'Other',
  ];

  String _province = _provinces.first;
  bool _isProcessing = false;
  bool _autoValidate = false;
  String? _paymentError;

  @override
  void dispose() {
    _scrollController.dispose();
    _nameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _postalController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  String? _required(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required for shipping.';
    }
    return null;
  }

  String? _validatePostalCode(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return 'Postal code is required for shipping.';
    }
    if (!_postalCodePattern.hasMatch(trimmed)) {
      return 'Enter a valid Canadian postal code (e.g. H2X 1Y4).';
    }
    return null;
  }

  String get _deliverySummary {
    final parts = [
      _cityController.text.trim(),
      _province,
      _postalController.text.trim().toUpperCase(),
    ].where((s) => s.isNotEmpty);
    return parts.join(', ');
  }

  Future<void> _confirmAndPay() async {
    setState(() {
      _autoValidate = true;
      _paymentError = null;
    });

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    if (!PaymentService.isConfigured) {
      setState(() {
        _paymentError =
            'Payments are not configured yet. Add STRIPE_PUBLISHABLE_KEY to .env '
            '(see STRIPE_SETUP.md).';
      });
      return;
    }

    setState(() => _isProcessing = true);
    _showLoadingDialog('Preparing your order...');

    String? orderId;
    String? paymentIntentId;

    try {
      final userId = AuthService.instance.currentUserId;
      if (userId == null) {
        throw Exception('You must be signed in to continue.');
      }

      await ProfileService.upsertShippingAddress(
        userId: userId,
        name: _nameController.text,
        address: _addressController.text,
        city: _cityController.text,
        province: _province,
        postalCode: _postalController.text,
      );

      orderId = await OrderService.upsertPendingOrder(
        userId: userId,
        rollId: widget.order.rollId,
        format: widget.order.formatApiValue,
        amount: widget.order.total,
        taxes: widget.order.taxes,
      );

      await RollStorageService.uploadActiveRoll(
        userId: userId,
        rollId: widget.order.rollId,
      );

      final paymentData = await EdgeFunctionService.instance.createPaymentIntent(
        orderId: orderId,
      );
      final clientSecret = paymentData['clientSecret'] as String?;
      paymentIntentId = paymentData['paymentIntentId'] as String?;
      if (clientSecret == null || clientSecret.isEmpty) {
        throw Exception('Could not start payment.');
      }

      if (mounted) Navigator.of(context).pop(); // close loading before sheet

      final paymentResult = await PaymentService.presentPaymentSheet(
        clientSecret: clientSecret,
      );

      switch (paymentResult) {
        case PaymentCancelled():
          return;
        case PaymentFailure(:final message):
          if (mounted) {
            setState(() => _paymentError = message);
          }
          return;
        case PaymentSuccess():
          break;
      }

      await OrderService.markOrderPaid(
        orderId: orderId,
        paymentIntentId: paymentIntentId,
      );

      if (!mounted) return;
      _showLoadingDialog('Fulfilling your order...');

      final data = await EdgeFunctionService.instance.processMediaclipOrder(
        rollId: widget.order.rollId,
        format: widget.order.formatApiValue,
        amount: widget.order.total,
        orderId: orderId,
      );

      final hubOrderId = data['hubOrderId']?.toString();
      if (hubOrderId != null && hubOrderId.isNotEmpty) {
        await EdgeFunctionService.instance.releaseMediaclipOrder(
          hubOrderId: hubOrderId,
          orderId: orderId,
        );
      }

      await RollRepository.clearActiveRoll(userId);

      if (!mounted) return;
      Navigator.of(context).pop(); // close loading dialog

      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => OrderConfirmationPage(
            order: widget.order,
            orderId: orderId!,
            hubOrderId: hubOrderId,
            receiptEmail: AuthService.instance.currentUser?.email ?? '',
            deliverySummary: _deliverySummary,
          ),
        ),
      );
    } catch (e) {
      if (mounted && Navigator.of(context).canPop()) {
        Navigator.of(context).pop(); // close loading dialog if open
      }
      if (!mounted) return;
      setState(() {
        _paymentError = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showLoadingDialog(String message) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => PopScope(
        canPop: false,
        child: AlertDialog(
          content: Row(
            children: [
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: _accentDeep,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Text(
                  message,
                  style: GoogleFonts.lora(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: _ink,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                    child: Form(
                      key: _formKey,
                      autovalidateMode: _autoValidate
                          ? AutovalidateMode.onUserInteraction
                          : AutovalidateMode.disabled,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const MelloLogo(height: 40),
                          const SizedBox(height: 20),
                          _BackToRoll(
                            enabled: !_isProcessing,
                            onPressed: () {
                              Navigator.of(context)
                                ..pop()
                                ..pop();
                            },
                          ),
                          const SizedBox(height: 28),
                          Text(
                            'Delivery address',
                            style: GoogleFonts.lora(
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              color: _ink,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _SectionCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _CheckoutField(
                                  label: 'Full name',
                                  controller: _nameController,
                                  enabled: !_isProcessing,
                                  textInputAction: TextInputAction.next,
                                  validator: (v) => _required(v, 'Full name'),
                                ),
                                const SizedBox(height: 14),
                                _CheckoutField(
                                  label: 'Address',
                                  controller: _addressController,
                                  enabled: !_isProcessing,
                                  textInputAction: TextInputAction.next,
                                  validator: (v) => _required(v, 'Address'),
                                ),
                                const SizedBox(height: 14),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: _CheckoutField(
                                        label: 'City',
                                        controller: _cityController,
                                        enabled: !_isProcessing,
                                        textInputAction: TextInputAction.next,
                                        validator: (v) => _required(v, 'City'),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _CheckoutField(
                                        label: 'Postal code',
                                        controller: _postalController,
                                        enabled: !_isProcessing,
                                        textInputAction: TextInputAction.next,
                                        textCapitalization:
                                            TextCapitalization.characters,
                                        validator: _validatePostalCode,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                _CheckoutField(
                                  label: 'Country',
                                  controller: _countryController,
                                  enabled: !_isProcessing,
                                  textInputAction: TextInputAction.next,
                                  validator: (v) => _required(v, 'Country'),
                                ),
                                const SizedBox(height: 14),
                                _ProvinceField(
                                  value: _province,
                                  provinces: _provinces,
                                  enabled: !_isProcessing,
                                  onChanged: (v) => setState(() => _province = v),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 28),
                          Text(
                            'Order Summary',
                            style: GoogleFonts.lora(
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              color: _ink,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _SectionCard(
                            child: Column(
                              children: [
                                _SummaryRow(
                                  label: 'Roll',
                                  value: '${order.photoCount} photos',
                                ),
                                _SummaryRow(
                                  label: 'Format',
                                  value: order.formatLine,
                                ),
                                _SummaryRow(
                                  label: 'Delivery',
                                  value: order.deliveryLabel,
                                ),
                                _SummaryRow(
                                  label: 'Subtotal',
                                  value: _money(order.subtotal),
                                ),
                                _SummaryRow(
                                  label: 'Shipping',
                                  value: 'free',
                                ),
                                _SummaryRow(
                                  label: 'Taxes (TPS+TVQ)',
                                  value: _money(order.taxes),
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  child: Divider(
                                    height: 1,
                                    color: Color(0xFFE8D8D4),
                                  ),
                                ),
                                _SummaryRow(
                                  label: 'Total',
                                  value: _money(order.total),
                                  bold: true,
                                ),
                              ],
                            ),
                          ),
                          if (_paymentError != null) ...[
                            const SizedBox(height: 20),
                            _PaymentErrorBanner(message: _paymentError!),
                          ],
                          const SizedBox(height: 28),
                          _PayButton(
                            total: order.total,
                            enabled: !_isProcessing,
                            onPressed: _confirmAndPay,
                          ),
                          const SizedBox(height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.lock_outline, size: 16, color: _muted),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'Secured by Stripe · Apple Pay & Google Pay accepted',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.lora(
                                    fontSize: 12,
                                    color: _muted,
                                    height: 1.35,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _money(double amount) => '${amount.toStringAsFixed(2)}\$';
}

class _PaymentErrorBanner extends StatelessWidget {
  const _PaymentErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _errorBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _errorText.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: _errorText, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.lora(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: _errorText,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BackToRoll extends StatelessWidget {
  const _BackToRoll({
    required this.onPressed,
    this.enabled = true,
  });

  final VoidCallback onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: enabled ? onPressed : null,
        icon: Icon(Icons.arrow_back, size: 20, color: enabled ? _ink : _muted),
        label: Text(
          'Back to roll',
          style: GoogleFonts.lora(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: enabled ? _ink : _muted,
          ),
        ),
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border, width: 1.2),
      ),
      child: child,
    );
  }
}

class _CheckoutField extends StatelessWidget {
  const _CheckoutField({
    required this.label,
    required this.controller,
    this.validator,
    this.enabled = true,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
  });

  final String label;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final bool enabled;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.lora(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _ink,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          enabled: enabled,
          validator: validator,
          textInputAction: textInputAction,
          textCapitalization: textCapitalization,
          style: GoogleFonts.lora(fontSize: 15, color: _ink),
          decoration: InputDecoration(
            filled: true,
            fillColor: enabled ? _fieldFill : _fieldFill.withValues(alpha: 0.6),
            errorStyle: GoogleFonts.lora(fontSize: 12, color: _errorText),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: _border.withValues(alpha: 0.35)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _accent, width: 1.4),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _errorText, width: 1.2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _errorText, width: 1.4),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProvinceField extends StatelessWidget {
  const _ProvinceField({
    required this.value,
    required this.provinces,
    required this.onChanged,
    this.enabled = true,
  });

  final String value;
  final List<String> provinces;
  final ValueChanged<String> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Province/State',
          style: GoogleFonts.lora(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _ink,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: value,
          items: provinces
              .map(
                (p) => DropdownMenuItem(
                  value: p,
                  child: Text(
                    p,
                    style: GoogleFonts.lora(fontSize: 15, color: _ink),
                  ),
                ),
              )
              .toList(),
          onChanged: enabled
              ? (v) {
                  if (v != null) onChanged(v);
                }
              : null,
          decoration: InputDecoration(
            filled: true,
            fillColor: enabled ? _fieldFill : _fieldFill.withValues(alpha: 0.6),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: _border.withValues(alpha: 0.35)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: _accent, width: 1.4),
            ),
          ),
          icon: const Icon(Icons.keyboard_arrow_down, color: _ink),
          borderRadius: BorderRadius.circular(10),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.bold = false,
  });

  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final style = GoogleFonts.lora(
      fontSize: bold ? 17 : 15,
      fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
      color: _ink,
      height: 1.4,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label, style: style)),
          Text(value, style: style),
        ],
      ),
    );
  }
}

class _PayButton extends StatelessWidget {
  const _PayButton({
    required this.total,
    required this.onPressed,
    this.enabled = true,
  });

  final double total;
  final VoidCallback onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: enabled
              ? const [_accentDeep, _accent]
              : [_accentDeep.withValues(alpha: 0.45), _accent.withValues(alpha: 0.45)],
        ),
        boxShadow: enabled
            ? [
                BoxShadow(
                  color: _accentDeep.withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(28),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Center(
              child: Text(
                'Confirm and pay ${total.toStringAsFixed(2)}\$',
                style: GoogleFonts.lora(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
