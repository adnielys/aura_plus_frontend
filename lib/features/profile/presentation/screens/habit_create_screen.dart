import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/domain/enums.dart';
import '../../../check_in/presentation/providers/daily_flow_controller.dart';
import '../providers/habits_catalog_provider.dart';

/// Contexto opcional al crear (H4): desde el cambio ⇄ llega con el área fija
/// y la duración limitada al hueco; al guardar, sustituye directo.
typedef HabitCreateArgs = ({
  HabitArea? fixedArea,
  int? maxMinutes,
  int? swapSlot,
});

/// H2 · Crear tu microhábito (+ H3 confirmación en la misma pantalla).
///
/// Lo suyo es suyo desde el primer segundo: privado nace disponible y jamás
/// se revisa; compartido nace pending_review — usable por ella YA, visible
/// para otras solo si el admin lo publica. El rechazo no existe como evento.
class HabitCreateScreen extends ConsumerStatefulWidget {
  const HabitCreateScreen({super.key, this.args});

  final HabitCreateArgs? args;

  @override
  ConsumerState<HabitCreateScreen> createState() => _HabitCreateScreenState();
}

class _HabitCreateScreenState extends ConsumerState<HabitCreateScreen> {
  final _titleController = TextEditingController();
  late HabitArea _area;
  int _minutes = 5;
  bool _share = true; // como el mockup H2; apagado = privado para siempre
  bool _saving = false;
  bool _saved = false; // H3
  bool _savedShared = false;

  HabitArea? get _fixedArea => widget.args?.fixedArea;
  int get _maxMinutes => widget.args?.maxMinutes ?? 20;
  int? get _swapSlot => widget.args?.swapSlot;

  List<int> get _durations =>
      [5, 10, 15, 20].where((minutes) => minutes <= _maxMinutes).toList();

  @override
  void initState() {
    super.initState();
    _area = _fixedArea ?? HabitArea.self;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.length < 3 || _saving) return;
    setState(() => _saving = true);
    final router = GoRouter.of(context);

    final CatalogHabit habit;
    try {
      habit = await createHabit(
        ref,
        title: title,
        area: _area,
        durationMinutes: _minutes,
        share: _share,
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('No se pudo guardar. Inténtalo de nuevo.')),
        );
        setState(() => _saving = false);
      }
      return;
    }

    // Desde el cambio ⇄ (H4): sustituye directo, sin pasos extra.
    final slot = _swapSlot;
    if (slot != null) {
      final error = await ref
          .read(dailyFlowProvider.notifier)
          .swapHabit(slot: slot, habitId: habit.id);
      if (!mounted) return;
      if (error == null) {
        router.go(AppRoutes.home);
      } else {
        // El gesto ya es suyo igualmente; el hueco no se pudo (el servidor manda).
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(SnackBar(
              content: Text('Tu gesto quedó guardado, pero: $error')));
        router.go(AppRoutes.home);
      }
      return;
    }

    if (mounted) {
      setState(() {
        _saving = false;
        _saved = true;
        _savedShared = _share;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _saved ? _confirmation(context) : _form(context),
      ),
    );
  }

  // ── H3 · confirmación ──────────────────────────────────────────────────────
  Widget _confirmation(BuildContext context) {
    final serif = Theme.of(context).textTheme.headlineMedium!.copyWith(
          fontSize: 20,
          height: 1.4,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(),
          const Center(
            child: Text('✓',
                style: TextStyle(fontSize: 36, color: Color(0xFF2E9E5B))),
          ),
          const SizedBox(height: 10),
          Text.rich(
            TextSpan(children: [
              TextSpan(text: 'Ya está en tu lista.\n', style: serif),
              TextSpan(
                text: 'Tuyo desde este momento.',
                style: serif.copyWith(
                    fontStyle: FontStyle.italic, color: AppColors.primary),
              ),
            ]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          const Text(
            'Puedes elegirlo hoy mismo al cambiar un hábito con ⇄.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
          ),
          if (_savedShared) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: const Text(
                'Como pediste compartirlo: lo revisamos con calma y, si suena '
                'positivo, aparecerá en el banco común para otras mamás. '
                'Si no se publica, no pasa nada: sigue siendo tuyo, intacto.',
                style: TextStyle(
                    fontSize: 11.5,
                    height: 1.6,
                    color: AppColors.textSecondary),
              ),
            ),
          ],
          const Spacer(),
          FilledButton(
            onPressed: () => context.go(AppRoutes.habits),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.entryAccent,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26)),
            ),
            child: const Text('Volver al catálogo',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ── H2 · formulario ────────────────────────────────────────────────────────
  Widget _form(BuildContext context) {
    final serif = Theme.of(context).textTheme.headlineMedium!.copyWith(
          fontSize: 20,
          height: 1.35,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        );
    final fromSwap = _swapSlot != null;

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => context.pop(),
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.arrow_back_ios_new,
                    size: 14, color: AppColors.textSecondary),
                SizedBox(width: 6),
                Text('Volver',
                    style: TextStyle(
                        fontSize: 13, color: AppColors.textSecondary)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        const Text('TU MICROHÁBITO', style: AppTypography.sectionLabel),
        const SizedBox(height: 10),
        Text.rich(
          TextSpan(children: [
            TextSpan(text: 'Un momento pequeño ', style: serif),
            TextSpan(
              text: 'que sea tuyo.',
              style: serif.copyWith(
                  fontStyle: FontStyle.italic, color: AppColors.primary),
            ),
          ]),
        ),
        if (fromSwap) ...[
          const SizedBox(height: 6),
          Text(
            'Para el hueco de hoy: área ${_area.label} · hasta $_maxMinutes min.',
            style: const TextStyle(
                fontSize: 11.5, color: AppColors.textSecondary),
          ),
        ],
        const SizedBox(height: 14),
        _fieldShell(
          label: 'QUÉ VAS A REGALARTE',
          child: TextField(
            controller: _titleController,
            maxLength: 80,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary),
            decoration: const InputDecoration(
              isDense: true,
              counterText: '',
              border: InputBorder.none,
              hintText: 'Escuchar una canción que me guste entera…',
              hintStyle:
                  TextStyle(fontSize: 13, color: Color(0xFFB9AFC2)),
            ),
            onChanged: (_) => setState(() {}),
          ),
          hint: 'Escríbelo en positivo y pequeño: algo que SÍ haces, '
              'no algo que dejas de hacer.',
        ),
        const SizedBox(height: 10),
        _fieldShell(
          label: 'ÁREA',
          child: Wrap(
            spacing: 7,
            children: [
              for (final area in HabitArea.values)
                ChoiceChip(
                  label: Text(area.label),
                  selected: _area == area,
                  onSelected: _fixedArea != null
                      ? null // desde el ⇄ el área es la del hueco
                      : (_) => setState(() => _area = area),
                  showCheckmark: false,
                  selectedColor: const Color(0xFFFCE3EC),
                  backgroundColor: AppColors.surface,
                  labelStyle: TextStyle(
                    fontSize: 11.5,
                    fontWeight:
                        _area == area ? FontWeight.w700 : FontWeight.w400,
                    color: _area == area
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                  side: BorderSide(
                    color: _area == area
                        ? const Color(0xFFF0C3D3)
                        : AppColors.border,
                    width: 1.5,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        _fieldShell(
          label: 'CUÁNTO TE TOMA',
          child: Wrap(
            spacing: 7,
            children: [
              for (final minutes in _durations)
                ChoiceChip(
                  label: Text('$minutes min'),
                  selected: _minutes == minutes,
                  onSelected: (_) => setState(() => _minutes = minutes),
                  showCheckmark: false,
                  selectedColor: const Color(0xFFFCE3EC),
                  backgroundColor: AppColors.surface,
                  labelStyle: TextStyle(
                    fontSize: 11.5,
                    fontWeight: _minutes == minutes
                        ? FontWeight.w700
                        : FontWeight.w400,
                    color: _minutes == minutes
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                  side: BorderSide(
                    color: _minutes == minutes
                        ? const Color(0xFFF0C3D3)
                        : AppColors.border,
                    width: 1.5,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: const Color(0xFFFBF8FD),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Switch(
                value: _share,
                activeThumbColor: Colors.white,
                activeTrackColor: AppColors.primary,
                onChanged: (value) => setState(() => _share = value),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Compartirlo con otras mamás',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary),
                    ),
                    const SizedBox(height: 3),
                    Text.rich(
                      const TextSpan(children: [
                        TextSpan(
                          text: 'Irá al banco común cuando pase una revisión '
                              '(validamos que suene en positivo). ',
                        ),
                        TextSpan(
                          text: 'Para ti queda disponible desde YA, '
                              'pase lo que pase.',
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary),
                        ),
                      ]),
                      style: const TextStyle(
                          fontSize: 11,
                          height: 1.5,
                          color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        FilledButton(
          onPressed:
              _titleController.text.trim().length < 3 || _saving ? null : _save,
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.entryAccent,
            disabledBackgroundColor: const Color(0xFFF2A9C4),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
          ),
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : Text(
                  fromSwap ? 'Guardar y usarlo hoy' : 'Guardar mi microhábito',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, color: Colors.white),
                ),
        ),
      ],
    );
  }

  Widget _fieldShell({
    required String label,
    required Widget child,
    String? hint,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(13, 11, 13, 11),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          child,
          if (hint != null) ...[
            const SizedBox(height: 4),
            Text(hint,
                style: const TextStyle(
                    fontSize: 10,
                    height: 1.5,
                    color: Color(0xFFA79FAD))),
          ],
        ],
      ),
    );
  }
}
