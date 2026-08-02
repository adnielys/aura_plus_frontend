import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../crisis/domain/crisis_resource.dart';
import '../../../crisis/presentation/widgets/resource_row.dart';
import '../providers/companion_provider.dart';

/// Conversación con Aura (SPEC_COMPANION_LLM · mockup aprobado jul 2026).
///
/// Aura habla en SERIF —la misma voz de los mensajes de cierre— y ella en la
/// tipografía normal: se lee como Aura, no como un chatbot. Sin indicadores
/// de "escribiendo" que generen espera ansiosa, sin contadores, sin racha.
/// Aura JAMÁS empieza la conversación: esta pantalla solo existe si ella la
/// abre.
class CompanionScreen extends ConsumerStatefulWidget {
  const CompanionScreen({super.key});

  @override
  ConsumerState<CompanionScreen> createState() => _CompanionScreenState();
}

class _CompanionScreenState extends ConsumerState<CompanionScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  bool _sending = false;
  String? _suggestedAction;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final history = await ref.read(companionHistoryProvider.future);
      if (mounted) ref.read(companionThreadProvider.notifier).seed(history);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() {
      _sending = true;
      _suggestedAction = null;
    });
    ref.read(companionThreadProvider.notifier).addMine(text);
    _controller.clear();
    _toBottom();

    final reply = await sendCompanionMessage(ref, text: text);
    if (!mounted) return;
    setState(() => _sending = false);
    if (reply == null) {
      // Sin red: se dice con calma y lo suyo queda en pantalla.
      ref.read(companionThreadProvider.notifier).addAura(
            "No te llegué a escuchar bien ahora mismo. Lo que escribiste "
            'sigue aquí; puedes intentarlo en un momento.',
          );
    } else {
      ref
          .read(companionThreadProvider.notifier)
          .addAura(reply.reply, resources: reply.resources);
      setState(() => _suggestedAction = reply.suggestedAction);
    }
    _toBottom();
  }

  void _toBottom() {
    Future.delayed(const Duration(milliseconds: 80), () {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// El chip de invitación (lo decide el SERVIDOR). Nunca imperativo.
  ({String label, String route})? get _actionChip => switch (_suggestedAction) {
        'check_in' => (label: 'Log your day?', route: AppRoutes.checkIn),
        'view_recommendation' => (
            label: 'See your gesture for today?',
            route: AppRoutes.home,
          ),
        _ => null,
      };

  @override
  Widget build(BuildContext context) {
    final turns = ref.watch(companionThreadProvider);
    final chip = _actionChip;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
              child: Row(
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => context.go(AppRoutes.home),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                      child: Icon(Icons.arrow_back_ios_new,
                          size: 15, color: AppColors.textSecondary),
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'WITH AURA',
                      textAlign: TextAlign.center,
                      style: AppTypography.eyebrow,
                    ),
                  ),
                  const SizedBox(width: 20),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                children: [
                  if (turns.isEmpty) const _Opening(),
                  for (final turn in turns) _Bubble(turn: turn),
                  if (_sending)
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Text(
                        'Aura is reading…',
                        style: TextStyle(
                            fontSize: 11.5, color: AppColors.textSecondary),
                      ),
                    ),
                  if (chip != null) ...[
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => context.go(chip.route),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 13, vertical: 7),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFDF2F6),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFF0C3D3)),
                          ),
                          child: Text(
                            chip.label,
                            style: const TextStyle(
                                fontSize: 11.5, color: Color(0xFF993556)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      maxLines: 4,
                      minLines: 1,
                      textCapitalization: TextCapitalization.sentences,
                      style: const TextStyle(
                          fontSize: 13.5, color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        isDense: true,
                        hintText: 'Write to Aura…',
                        hintStyle: const TextStyle(
                            fontSize: 13, color: Color(0xFFB9AFC2)),
                        filled: true,
                        fillColor: AppColors.surface,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide:
                              const BorderSide(color: AppColors.border, width: 1.5),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide: const BorderSide(
                              color: Color(0xFFF0C3D3), width: 1.5),
                        ),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Material(
                    color: AppColors.primary,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _sending ? null : _send,
                      child: const Padding(
                        padding: EdgeInsets.all(11),
                        child: Icon(Icons.arrow_upward,
                            size: 19, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Primer turno: lo dice la app, no el modelo — y no pide nada.
class _Opening extends StatelessWidget {
  const _Opening();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF4EFF6),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
          bottomRight: Radius.circular(16),
          bottomLeft: Radius.circular(5),
        ),
      ),
      child: const Text(
        "I'm here. Whatever today was, it can be said out loud.",
        style: TextStyle(
          fontFamily: AppTypography.serif,
          fontSize: 14,
          height: 1.5,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}

/// Parte la plantilla de crisis en (antes, después) de la línea de recursos.
///
/// La línea se localiza por el PRIMER número: no se adivina con expresiones
/// regulares sobre texto de seguridad. Si no se encuentra —plantilla nueva,
/// idioma raro—, todo el texto va antes y las filas se añaden debajo: nunca
/// se pierde una palabra.
(String, String) _splitAroundResources(
  String content,
  List<CrisisResource> resources,
) {
  const newline = '\n';
  final lines = content.split(newline);
  final index = lines.indexWhere(
    (line) => resources.any((r) => line.contains(r.phone)),
  );
  if (index == -1) return (content.trim(), '');
  return (
    lines.sublist(0, index).join(newline).trim(),
    lines.sublist(index + 1).join(newline).trim(),
  );
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.turn});

  final CompanionTurn turn;

  @override
  Widget build(BuildContext context) {
    final mine = turn.role == 'user';
    return Container(
      margin: EdgeInsets.only(bottom: 10, left: mine ? 48 : 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: mine ? AppColors.primary : const Color(0xFFF4EFF6),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(mine ? 16 : 5),
          bottomRight: Radius.circular(mine ? 5 : 16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            // Con recursos, el texto se parte por la línea de teléfonos y
            // esta se sustituye por filas llamables. Sin ellos se pinta
            // entero — el número sigue estando escrito (degradación sin
            // pérdida, SPEC_RECURSOS_CRISIS §4.2).
            turn.resources.isEmpty
                ? turn.content
                : _splitAroundResources(turn.content, turn.resources).$1,
            style: TextStyle(
              // La voz de Aura va en serif (como sus mensajes de cierre); la
              // de ella, en la tipografía de siempre.
              fontFamily: mine ? null : AppTypography.serif,
              fontSize: mine ? 13.5 : 14,
              height: 1.5,
              color: mine ? Colors.white : AppColors.textPrimary,
            ),
          ),
          if (turn.resources.isNotEmpty) ...[
            const SizedBox(height: 12),
            for (final resource in turn.resources)
              ResourceRow(resource: resource),
            const SizedBox(height: 4),
            Text(
              _splitAroundResources(turn.content, turn.resources).$2,
              style: const TextStyle(
                fontFamily: AppTypography.serif,
                fontSize: 14,
                height: 1.5,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
