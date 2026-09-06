import 'package:flutter/material.dart';
import 'package:sint/sint.dart';

import '../../utils/constants/auth_translation_constants.dart';

/// A persistent recovery message that does not infer whether an account exists.
class AccountLoadErrorNotice extends StatelessWidget {
  const AccountLoadErrorNotice({super.key, required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.amber.withAlpha(20),
          border: Border.all(color: Colors.amber.withAlpha(100)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AuthTranslationConstants.accountLoadErrorTitle.tr,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AuthTranslationConstants.accountLoadErrorMessage.tr,
              style: const TextStyle(color: Colors.white, height: 1.4),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: onRetry,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.amber.shade100,
                side: BorderSide(color: Colors.amber.shade100),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
              child: Text(
                AuthTranslationConstants.retryAccountLoad.tr,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
