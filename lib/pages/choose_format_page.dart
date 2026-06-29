import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../components/mello_logo.dart';
import '../models/order_checkout.dart';
import '../services/auth_service.dart';
import '../services/roll_repository.dart';
import 'checkout_page.dart';

const _bg = Color(0xFFFFF9F6);
const _accent = Color(0xFFE89F94);
const _accentDeep = Color(0xFFD8897E);
const _ink = Color(0xFF2A2628);
const _muted = Color(0xFF6B5B5F);
const _border = Color(0xFF2A2628);

/// Choix du format d'impression après « Send to print » sur [RollCompletePage].
///
/// Le total suit le prix du format sélectionné. Confirm → [CheckoutPage].
class ChooseFormatPage extends StatefulWidget {
  const ChooseFormatPage({super.key});

  @override
  State<ChooseFormatPage> createState() => _ChooseFormatPageState();
}

class _ChooseFormatPageState extends State<ChooseFormatPage> {
  int _selectedIndex = 0;

  /// Catalogues statiques ; prix en dollars pour l'affichage du total.
  static const _formats = [
    _FormatOption(
      title: 'Standard print',
      subtitle: '4x6 - glossy',
      price: 12.99,
      iconAsset: 'lib/images/icones_standard.svg',
    ),
    _FormatOption(
      title: 'Polaroid',
      subtitle: '3x3 - glossy',
      price: 15.99,
      iconAsset: 'lib/images/icones_polaroid.svg',
    ),
    _FormatOption(
      title: 'strips',
      subtitle: '4 photos each',
      price: 14.99,
      iconAsset: 'lib/images/icones_strip.svg',
    ),
  ];

  double get _total => _formats[_selectedIndex].price.toDouble();

  Future<void> _confirmFormat() async {
    final userId = AuthService.instance.currentUserId;
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must be signed in to continue.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final rollId = await RollRepository.getRollId(userId);
    if (rollId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No active roll found. Complete your photos first.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final formatOption = _formats[_selectedIndex];
    final printFormat = OrderCheckout.formatFromTitle(formatOption.title);
    final subtotal = formatOption.price.toDouble();

    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => CheckoutPage(
          order: OrderCheckout(
            formatTitle: formatOption.title,
            formatSubtitle: formatOption.subtitle,
            subtotal: subtotal,
            rollId: rollId,
            format: printFormat,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const MelloLogo(height: 40),
                    const SizedBox(height: 28),
                    Text(
                      'Choose your format',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.lora(
                        fontSize: 34,
                        fontWeight: FontWeight.w700,
                        color: _ink,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 28),
                    ...List.generate(_formats.length, (index) {
                      final format = _formats[index];
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: index < _formats.length - 1 ? 14 : 0,
                        ),
                        child: _FormatCard(
                          format: format,
                          selected: _selectedIndex == index,
                          onTap: () => setState(() => _selectedIndex = index),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
            // Barre fixe en bas : total + confirmation (hors scroll).
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
              child: _CheckoutBar(
                total: _total,
                onConfirm: _confirmFormat,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FormatOption {
  const _FormatOption({
    required this.title,
    required this.subtitle,
    required this.price,
    required this.iconAsset,
  });

  final String title;
  final String subtitle;
  final double price;
  final String iconAsset;
}

/// Carte cliquable : fond saumon si sélectionnée, bordure sinon.
class _FormatCard extends StatelessWidget {
  const _FormatCard({
    required this.format,
    required this.selected,
    required this.onTap,
  });

  final _FormatOption format;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: selected ? _accent : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: selected
                ? null
                : Border.all(color: _border, width: 1.2),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            child: Row(
              children: [
                SizedBox(
                  width: 56,
                  height: 56,
                  child: SvgPicture.asset(
                    format.iconAsset,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        format.title,
                        style: GoogleFonts.lora(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: _ink,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        format.subtitle,
                        style: GoogleFonts.lora(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: _muted,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${format.price}\$',
                  style: GoogleFonts.lora(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: _ink,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Récapitulatif prix + bouton Confirm.
class _CheckoutBar extends StatelessWidget {
  const _CheckoutBar({
    required this.total,
    required this.onConfirm,
  });

  final double total;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border, width: 1.2),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total',
                  style: GoogleFonts.lora(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: _muted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${total.toStringAsFixed(2)}\$',
                  style: GoogleFonts.lora(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: _ink,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
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
                onTap: onConfirm,
                borderRadius: BorderRadius.circular(28),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  child: Text(
                    'Confirm',
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
        ],
      ),
    );
  }
}
