import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../components/mello_logo.dart';
import '../models/order_checkout.dart';
import '../services/auth_service.dart';
import '../services/edge_function_service.dart';
import '../services/roll_repository.dart';
import 'home_page.dart';

const _bg = Color(0xFFFFF9F6);
const _accent = Color(0xFFE89F94);
const _accentDeep = Color(0xFFD8897E);
const _ink = Color(0xFF2A2628);
const _muted = Color(0xFF6B5B5F);
const _border = Color(0xFF2A2628);

/// Confirmation après paiement (commande validée).
class OrderConfirmationPage extends StatefulWidget {
  const OrderConfirmationPage({
    super.key,
    required this.order,
    required this.orderId,
    required this.receiptEmail,
    required this.deliverySummary,
    this.hubOrderId,
  });

  final OrderCheckout order;
  final String orderId;
  final String receiptEmail;
  final String deliverySummary;
  final String? hubOrderId;

  @override
  State<OrderConfirmationPage> createState() => _OrderConfirmationPageState();
}

class _OrderConfirmationPageState extends State<OrderConfirmationPage> {
  bool _isReleasing = false;

  Future<void> _testReleaseOrder() async {
    final hubOrderId = widget.hubOrderId;
    if (hubOrderId == null || hubOrderId.isEmpty) return;

    setState(() => _isReleasing = true);
    try {
      await EdgeFunctionService.instance.releaseMediaclipOrder(
        hubOrderId: hubOrderId,
        orderId: widget.orderId,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order released! Printing started.'),
          backgroundColor: Color(0xFF5E8A6A),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: const Color(0xFFC05040),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isReleasing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const MelloLogo(height: 40),
              const SizedBox(height: 36),
              Center(
                child: Container(
                  width: 88,
                  height: 88,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [_accentDeep, _accent],
                    ),
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 48,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 28),
              Text(
                "You're all set!",
                textAlign: TextAlign.center,
                style: GoogleFonts.lora(
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  color: _ink,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Order #${widget.orderId} confirmed. Receipt sent to ${widget.receiptEmail}',
                textAlign: TextAlign.center,
                style: GoogleFonts.lora(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: _muted,
                  height: 1.45,
                ),
              ),
              if (widget.hubOrderId != null &&
                  widget.hubOrderId!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  'Mediaclip ref: ${widget.hubOrderId}',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.lora(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _muted,
                  ),
                ),
              ],
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _border, width: 1.2),
                ),
                child: Column(
                  children: [
                    _ConfirmRow(
                      label: 'Photos',
                      value: '${order.photoCount} photos',
                    ),
                    _ConfirmRow(
                      label: 'Delivery',
                      value: widget.deliverySummary,
                    ),
                    _ConfirmRow(
                      label: 'Charged',
                      value: '${order.total.toStringAsFixed(2)}\$',
                      bold: true,
                    ),
                  ],
                ),
              ),
              if (kDebugMode &&
                  widget.hubOrderId != null &&
                  widget.hubOrderId!.isNotEmpty) ...[
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _isReleasing ? null : _testReleaseOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: _isReleasing
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'TEST: Release order (simulate payment)',
                          style: GoogleFonts.lora(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ],
              const SizedBox(height: 32),
              DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: const LinearGradient(
                    colors: [_accentDeep, _accent],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _accentDeep.withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () async {
                      final userId = AuthService.instance.currentUserId;
                      if (userId != null) {
                        await RollRepository.clearActiveRoll(userId);
                      }
                      if (!context.mounted) return;
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute<void>(
                          builder: (_) => const HomePage(),
                        ),
                        (_) => false,
                      );
                    },
                    borderRadius: BorderRadius.circular(28),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      child: Center(
                        child: Text(
                          'Start a new roll',
                          style: GoogleFonts.lora(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConfirmRow extends StatelessWidget {
  const _ConfirmRow({
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
