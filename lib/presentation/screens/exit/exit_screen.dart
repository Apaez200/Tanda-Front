import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../widgets/custom_button.dart';

class ExitScreen extends StatelessWidget {
  const ExitScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now().day;
    final safeDate = DateTime.now().add(const Duration(days: 60));
    final safeDateStr = '${safeDate.day}/${safeDate.month}/${safeDate.year}';

    // Determinar penalización según el día del mes
    final String penDesc;
    if (today <= 15) {
      penDesc = '15% = -\$150';
    } else if (today <= 30) {
      penDesc = '10% = -\$100';
    } else {
      penDesc = '5% = -\$50';
    }

    return Scaffold(
      backgroundColor: darkBg,
      appBar: AppBar(
        title: Text('Salir del Grupo', style: titleBold(20)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ADVERTENCIA
            FadeInDown(
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: warningRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: warningRed.withOpacity(0.5)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('⚠️', style: TextStyle(fontSize: 26)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '¿Seguro que quieres salirte? Esto tiene consecuencias.',
                        style: bodyText(15, color: offWhite, weight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // TABLA PENALIZACIONES
            FadeInUp(
              delay: const Duration(milliseconds: 100),
              child: _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Penalización según cuándo avises:', style: titleSemi(15)),
                    const SizedBox(height: 14),
                    _penRow('✅', 'Con 2+ meses de aviso', 'Sin penalización', successGreen),
                    _penRow('🟡', 'Con 1-2 meses', 'Pierdes 5% (~\$50)', accentGold),
                    _penRow('🟠', 'Con 15-30 días', 'Pierdes 10% (~\$100)', const Color(0xFFE67E22)),
                    _penRow('🔴', 'Menos de 15 días', 'Pierdes 15% (~\$150)', warningRed),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // TU SITUACIÓN
            FadeInUp(
              delay: const Duration(milliseconds: 200),
              child: _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Si avisas HOY (día $today):', style: titleSemi(15)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: warningRed.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: warningRed.withOpacity(0.4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_rounded, color: warningRed, size: 22),
                          const SizedBox(width: 8),
                          Text('Penalización: $penDesc', style: bodyText(14, color: warningRed, weight: FontWeight.w700)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: successGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: successGreen.withOpacity(0.4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle_rounded, color: successGreen, size: 22),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Si esperas hasta el $safeDateStr, sales sin perder nada',
                              style: bodyText(13, color: successGreen),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),

            // BOTONES
            FadeInUp(
              delay: const Duration(milliseconds: 300),
              child: CustomButton(
                label: 'Iniciar proceso de salida ahora ($penDesc)',
                onPressed: () => _confirmExit(context),
                variant: CustomButtonVariant.danger,
                fullWidth: true,
              ),
            ),
            const SizedBox(height: 12),
            FadeInUp(
              delay: const Duration(milliseconds: 360),
              child: CustomButton(
                label: 'Mejor me quedo 😅',
                onPressed: () => context.pop(),
                variant: CustomButtonVariant.secondary,
                fullWidth: true,
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _confirmExit(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('¿Confirmas?', style: titleBold(18)),
        content: Text(
          'Perderás \$150 de penalización por salir con menos de 15 días de aviso.',
          style: bodyText(14, color: softGray),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar', style: bodyText(14, color: softGray)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Confirmar salida', style: bodyText(14, color: warningRed, weight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: cardBg,
          content: Text(
            'Solicitud registrada. Tienes 15 días hábiles para completar el proceso.',
            style: bodyText(13, color: offWhite),
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 4),
        ),
      );
      context.pop();
    }
  }

  Widget _card({required Widget child}) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: child,
      );

  Widget _penRow(String emoji, String label, String consequence, Color color) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 10),
            Expanded(child: Text(label, style: bodyText(13, color: softGray))),
            Text(consequence, style: bodyText(13, color: color, weight: FontWeight.w600)),
          ],
        ),
      );
}
