import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/section_hero.dart';
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
      ref.read(companionThreadProvider.notifier).addAura(reply.reply);
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
      // Papel cálido (no el gris del resto de la app): la conversación es un
      // espacio aparte, más íntimo.
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Botánica inferior, muy tenue: da aire al hilo cuando hay pocos
          // mensajes. La de arriba ya la aporta la cabecera estándar.
          Positioned(
            bottom: 90,
            left: -90,
            width: 280,
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.3,
                // Espejada, para que no se lea como la misma estampa repetida.
                child: Transform.flip(
                  flipX: true,
                  child: Image.asset(
                    'assets/images/care/card3.png',
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
                ),
              ),
            ),
          ),
          Column(
          children: [
            // Cabecera ESTÁNDAR (misma altura que Care, My circle y Profile),
            // fundida al papel cálido del chat en vez de al gris de la app.
            SectionHero(
              asset: 'assets/images/care/chat_hero.png',
              // Mismo patrón que Care · My circle · Profile: todo a la
              // IZQUIERDA — rótulo pequeño en la línea del chevron y el titular
              // debajo. Así el texto tampoco pisa la botánica de la derecha.
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new,
                              size: 17, color: AppColors.textPrimary),
                          tooltip: 'Back',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          visualDensity: VisualDensity.compact,
                          // Vuelve a DONDE se entró (Home, Care…): pop si hay
                          // pila — lo normal, porque al chat se entra con push.
                          // El go a Home solo es red de seguridad (deep link).
                          onPressed: () => context.canPop()
                              ? context.pop()
                              : context.go(AppRoutes.home),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'WITH',
                          style: TextStyle(
                            fontFamily: AppTypography.serif,
                            fontSize: 12,
                            letterSpacing: 4,
                            color: AppColors.primary.withValues(alpha: 0.75),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'AURA',
                            style: TextStyle(
                              fontFamily: AppTypography.serif,
                              fontSize: 32,
                              height: 1.1,
                              letterSpacing: 5,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('✦',
                                  style: TextStyle(
                                      fontSize: 12, color: Color(0xFFE2799E))),
                              const SizedBox(width: 6),
                              Text(
                                'A quiet space for you',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: _warmInk,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
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
            // El SafeArea superior lo pone la cabecera; aquí solo hace falta el
            // inferior, para que el campo no quede bajo la barra del sistema.
            SafeArea(
              top: false,
              child: Padding(
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
                            fontSize: 13.5, color: Color(0xFFC0AEB4)),
                        filled: true,
                        fillColor: Colors.white,
                        // Destello dentro del campo, como el maquetado.
                        prefixIcon: const Padding(
                          padding: EdgeInsets.only(left: 16, right: 10),
                          child: Text('✦',
                              style: TextStyle(
                                  fontSize: 15, color: Color(0xFFE2799E))),
                        ),
                        prefixIconConstraints:
                            const BoxConstraints(minWidth: 0, minHeight: 0),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(28),
                          borderSide: const BorderSide(
                              color: Color(0xFFF2DDE3), width: 1.5),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(28),
                          borderSide: const BorderSide(
                              color: Color(0xFFE8B9CB), width: 1.5),
                        ),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  DecoratedBox(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.primary, AppColors.primaryDark],
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: _sending ? null : _send,
                        child: const Padding(
                          padding: EdgeInsets.all(13),
                          child: Icon(Icons.arrow_upward,
                              size: 20, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ),
          ],
        ),
        ],
      ),
    );
  }
}

const Color _warmInk = Color(0xFFB08968);

/// Primer turno: lo dice la app, no el modelo — y no pide nada.
class _Opening extends StatelessWidget {
  const _Opening();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14, right: 48),
      padding: const EdgeInsets.fromLTRB(16, 11, 16, 13),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFF4E4E9)),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(18),
          topRight: Radius.circular(18),
          bottomRight: Radius.circular(18),
          bottomLeft: Radius.circular(4),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFC9A0AE).withValues(alpha: 0.13),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('✦',
                  style: TextStyle(fontSize: 12, color: Color(0xFFE2799E))),
              const SizedBox(width: 6),
              Text(
                'Aura',
                style: TextStyle(
                  fontFamily: AppTypography.serif,
                  fontSize: 13.5,
                  color: AppColors.primary.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            "I'm here. Whatever today was, it can be said out loud.",
            style: TextStyle(
              fontFamily: AppTypography.serif,
              fontSize: 14.5,
              height: 1.5,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.turn});

  final CompanionTurn turn;

  @override
  Widget build(BuildContext context) {
    final mine = turn.role == 'user';
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          bottom: 14,
          left: mine ? 48 : 0,
          right: mine ? 0 : 48,
        ),
        padding: EdgeInsets.fromLTRB(16, mine ? 13 : 11, 16, 13),
        decoration: BoxDecoration(
          color: mine ? null : Colors.white,
          // La suya: degradado carmesí. La de Aura: papel blanco con borde.
          gradient: mine
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primary, AppColors.primaryDark],
                )
              : null,
          border: mine ? null : Border.all(color: const Color(0xFFF4E4E9)),
          // Cola: la esquina inferior del lado de quien habla se recoge.
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(mine ? 18 : 4),
            bottomRight: Radius.circular(mine ? 4 : 18),
          ),
          boxShadow: [
            BoxShadow(
              color: (mine ? AppColors.primary : const Color(0xFFC9A0AE))
                  .withValues(alpha: 0.13),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Firma de Aura: nunca sobre lo que escribe ella.
            if (!mine) ...[
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('✦',
                      style:
                          TextStyle(fontSize: 12, color: Color(0xFFE2799E))),
                  const SizedBox(width: 6),
                  Text(
                    'Aura',
                    style: TextStyle(
                      fontFamily: AppTypography.serif,
                      fontSize: 13.5,
                      color: AppColors.primary.withValues(alpha: 0.85),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
            ],
            Text(
              turn.content,
              style: TextStyle(
                // La voz de Aura va en serif (como sus mensajes de cierre); la
                // de ella, en la tipografía de siempre.
                fontFamily: mine ? null : AppTypography.serif,
                fontSize: mine ? 14 : 14.5,
                height: 1.5,
                color: mine ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
