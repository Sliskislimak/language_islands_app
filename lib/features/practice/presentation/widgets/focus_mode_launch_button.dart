import 'package:flutter/material.dart';
import 'package:language_islands_app/core/theme/app_theme.dart';

class FocusModeLaunchButton extends StatelessWidget {
  const FocusModeLaunchButton({
    super.key,
    required this.sentenceCount,
    required this.onPressed,
  });

  final int sentenceCount;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        color: AppTheme.bgDark,
        border: Border(
          top: BorderSide(color: AppTheme.surfaceBorder),
        ),
      ),
      child: Material(
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: sentenceCount > 0 ? onPressed : null,
          borderRadius: BorderRadius.circular(12),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF6366F1),
                  const Color(0xFF8B5CF6),
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.bolt_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Start Focus Mode · $sentenceCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
