import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Tab "Mi ciclo" (maquetado · pantalla "ciclo"): la personalización por ciclo
/// menstrual está APLAZADA en el MVP — este tab es un adelanto sereno, sin
/// datos falsos ni promesas de fecha.
class CycleScreen extends StatelessWidget {
  const CycleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final serif = Theme.of(context).textTheme.headlineMedium!;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F0FA),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: const Text(
                  'COMING SOON',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Mi ciclo', style: serif),
              const SizedBox(height: 8),
              const Text(
                'Soon Aura will be able to adapt your microhabits to the moment '
                "of your cycle, if you want. No pressure: it'll arrive when it's ready.",
                style: TextStyle(
                  fontSize: 14,
                  height: 1.5,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
