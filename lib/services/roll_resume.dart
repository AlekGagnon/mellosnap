import 'package:flutter/material.dart';

import '../pages/camera_page.dart';
import '../pages/checkout_page.dart';
import '../pages/choose_format_page.dart';
import '../pages/roll_complete_page.dart';
import 'roll_repository.dart';

/// Reprend le parcours là où l'utilisateur s'était arrêté.
class RollResume {
  RollResume._();

  static Widget _pageForState(ActiveRollState state) {
    switch (state.stage) {
      case RollStage.checkout:
        final order = state.toCheckoutOrder();
        if (order != null) {
          return CheckoutPage(order: order);
        }
        return const ChooseFormatPage();
      case RollStage.format:
        return const ChooseFormatPage();
      case RollStage.complete:
      case null:
        return const RollCompletePage();
    }
  }

  /// Navigation depuis la home (bouton continuer).
  static Future<void> navigate(BuildContext context, ActiveRollState state) async {
    if (state.isIncomplete) {
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => CameraPage(
            initialPhotoPaths: state.photoPaths,
          ),
        ),
      );
      return;
    }

    if (!state.isComplete) return;

    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => _pageForState(state),
      ),
    );
  }

  static Future<bool> confirmDiscardRoll(BuildContext context) async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Start a new roll?'),
        content: const Text(
          'Your current photos will be deleted. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete photos'),
          ),
        ],
      ),
    );
    return discard ?? false;
  }

  static String continueButtonLabel(ActiveRollState state) {
    if (state.isIncomplete) {
      return 'Continue roll (${state.photoPaths.length} / ${CameraPage.maxPhotos})';
    }
    return switch (state.stage) {
      RollStage.checkout => 'Continue checkout',
      RollStage.format => 'Choose print format',
      RollStage.complete || null => 'Send to print',
    };
  }
}
