import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../providers/constellation_provider.dart';
import '../providers/cycle_closing_provider.dart';
import '../widgets/constellation_visuals.dart';

/// CycleCloseFlow (SPEC_CONTENIDO_EMOCIONAL_V2 §1): contemplar → significado
/// (+ reflexión opcional) → transición. Nunca bloqueante ("Ahora no" pospone
/// sin ack). Reglas de tono heredadas: sin días vacíos, sin "X de 28", misma
/// calidez para 1 estrella que para 40 (GUARD_CYCLE_01).
class CycleCloseScreen extends ConsumerStatefulWidget {
  const CycleCloseScreen({super.key, required this.closing});

  final CycleClosing closing;

  @override
  ConsumerState<CycleCloseScreen> createState() => _CycleCloseScreenState();
}

class _CycleCloseScreenState extends ConsumerState<CycleCloseScreen> {
  final _controller = PageController();
  String? _anchor;
  bool _acking = false;

  static const _anchors = [
    ('self_moments', 'My moments for me'),
    ('my_people', 'My people'),
    ('small_daily', 'The small things of each day'),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() => _controller.nextPage(
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutCubic,
      );

  /// "Ahora no": pospone sin ack — reaparecerá en el próximo arranque.
  void _postpone() {
    ref.read(cycleClosePostponedProvider.notifier).state = true;
    context.go(AppRoutes.constellation);
  }

  /// Chip de reflexión: manda el anchor (opcional) y avanza. "Prefiero solo
  /// cerrar" avanza con la MISMA animación: saltar no es la opción mala.
  void _reflect(String? anchor) {
    setState(() => _anchor = anchor);
    if (anchor != null) {
      sendCycleReflection(
        ref,
        constellationId: widget.closing.constellation.id,
        anchor: anchor,
      );
    }
    _next();
  }

  Future<void> _openNewSky() async {
    if (_acking) return;
    setState(() => _acking = true);
    await ackCycleClosing(
      ref,
      constellationId: widget.closing.constellation.id,
    );
    if (!mounted) return;
    // El rollover ya ocurrió en el servidor: refrescar el cielo nuevo.
    ref.invalidate(cycleClosingProvider);
    ref.invalidate(currentConstellationProvider);
    ref.invalidate(allConstellationsProvider);
    context.go(AppRoutes.constellation);
  }

  @override
  Widget build(BuildContext context) {
    final closing = widget.closing;
    final serif = Theme.of(context).textTheme.headlineMedium!;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF2A0A22), Color(0xFF1E081A), Color(0xFF140610)],
          ),
        ),
        child: SafeArea(
          child: PageView(
            controller: _controller,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _momentOne(serif, closing),
              _momentTwo(serif, closing),
              _momentThree(serif, closing),
            ],
          ),
        ),
      ),
    );
  }

  /// Momento 1 — Contemplar: la constelación cerrada, sin contadores.
  Widget _momentOne(TextStyle serif, CycleClosing closing) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 30, 28, 24),
      child: Column(
        children: [
          const Text('YOUR SKY', style: AppTypography.eyebrow),
          const Spacer(),
          Image.asset(
            closing.constellation.imageAsset,
            height: 280,
            fit: BoxFit.contain,
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(50),
              border: Border.all(color: Colors.white38),
            ),
            child: Text(
              '${closing.constellation.name} Constellation',
              style: const TextStyle(
                fontFamily: AppTypography.serif,
                fontStyle: FontStyle.italic,
                fontSize: 16,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 22),
          Text(
            closing.intro,
            textAlign: TextAlign.center,
            style: serif.copyWith(
              fontSize: 20,
              fontStyle: FontStyle.italic,
              color: Colors.white,
              height: 1.45,
            ),
          ),
          const Spacer(),
          _whiteCta('Continue', _next),
          TextButton(
            onPressed: _postpone,
            child: Text(
              'Not now',
              style: TextStyle(
                fontWeight: FontWeight.w400,
                color: Colors.white.withValues(alpha: 0.55),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Momento 2 — Significado + reflexión opcional de un toque.
  Widget _momentTwo(TextStyle serif, CycleClosing closing) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 30, 28, 24),
      child: Column(
        children: [
          const Spacer(),
          Text(
            closing.meaning,
            textAlign: TextAlign.center,
            style: serif.copyWith(
              fontSize: 23,
              fontStyle: FontStyle.italic,
              color: Colors.white,
              height: 1.5,
            ),
          ),
          const Spacer(),
          Text(
            'What sustained you most this cycle?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              for (final (anchor, label) in _anchors)
                _reflectChip(label, () => _reflect(anchor)),
              _reflectChip("I'd rather just close", () => _reflect(null)),
            ],
          ),
          const SizedBox(height: 26),
        ],
      ),
    );
  }

  /// Momento 3 — Transición: abrir el cielo nuevo (ack idempotente).
  Widget _momentThree(TextStyle serif, CycleClosing closing) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 30, 28, 24),
      child: Column(
        children: [
          const Spacer(),
          const Text('✦', style: TextStyle(fontSize: 34, color: Colors.white)),
          const SizedBox(height: 18),
          Text(
            closing.transition,
            textAlign: TextAlign.center,
            style: serif.copyWith(
              fontSize: 23,
              fontStyle: FontStyle.italic,
              color: Colors.white,
              height: 1.5,
            ),
          ),
          const Spacer(),
          _whiteCta(
            'Open my new sky',
            _acking ? null : _openNewSky,
            loading: _acking,
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _whiteCta(String label, VoidCallback? onTap, {bool loading = false}) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: onTap,
          child: Center(
            child: loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    '$label   ✦',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _reflectChip(String label, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(50),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: _anchor != null && label == _labelFor(_anchor!)
              ? Colors.white
              : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(50),
          border: Border.all(color: Colors.white30),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: _anchor != null && label == _labelFor(_anchor!)
                ? AppColors.primary
                : Colors.white,
          ),
        ),
      ),
    );
  }

  String _labelFor(String anchor) =>
      _anchors.firstWhere((a) => a.$1 == anchor).$2;
}
