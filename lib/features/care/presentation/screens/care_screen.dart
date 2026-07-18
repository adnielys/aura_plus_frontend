import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../providers/care_providers.dart';
import '../widgets/care_widgets.dart';

/// Flujo care (A2/A4/A5/A6): UNA pantalla gobernada por el estado del
/// servidor. Sin pasos guardados en el cliente: lo que diga
/// `careCurrentReferralProvider` es la vista — así el estado nunca miente.
class CareScreen extends ConsumerStatefulWidget {
  const CareScreen({super.key});

  @override
  ConsumerState<CareScreen> createState() => _CareScreenState();
}

class _CareScreenState extends ConsumerState<CareScreen> {
  @override
  void initState() {
    super.initState();
    // Al entrar SIEMPRE se reconsulta (polling suave — jamás push): si el
    // profesional respondió, se ve aquí, en el momento en que ella lo abre.
    Future.microtask(() {
      if (mounted) ref.invalidate(careCurrentReferralProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final referral = ref.watch(careCurrentReferralProvider);

    return Scaffold(
      body: SafeArea(
        child: referral.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.careAccent),
          ),
          error: (_, _) => _ErrorRetry(
            onRetry: () => ref.invalidate(careCurrentReferralProvider),
          ),
          data: (current) => switch (resolveCareView(current)) {
            // D1: directorio libre · D3: mismo directorio con la petición
            // pendiente (badge 📤, resto en reposo). El estado de la solicitud
            // (D4) vive en su propia ruta: /care/request.
            CareView.directory => const _DirectoryView(pending: null),
            CareView.sent => _DirectoryView(pending: current),
            CareView.responseAccepted => _ResponseAcceptedView(referral: current!),
            CareView.responseDeclined => _ResponseDeclinedView(referral: current!),
            CareView.episode => _EpisodeView(referral: current!),
          },
        ),
      ),
    );
  }
}

// ── D1/D2/D3 · Directorio con buscador (y modo petición pendiente) ───────────
class _DirectoryView extends ConsumerStatefulWidget {
  const _DirectoryView({required this.pending});

  /// Petición pendiente (D3): su card lleva 📤 y el resto descansa con 🔒.
  final CareReferral? pending;

  @override
  ConsumerState<_DirectoryView> createState() => _DirectoryViewState();
}

class _DirectoryViewState extends ConsumerState<_DirectoryView> {
  final _searchController = TextEditingController();
  String _query = '';
  String? _tier; // null = Todas

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool get _locked => widget.pending != null;

  void _showOneAtATime() {
    final name = widget.pending?.providerName == null
        ? 'esa persona'
        : shortProviderName(widget.pending!.providerName!);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(
          'Una persona a la vez: tu petición a $name sigue en sus manos.',
        ),
      ));
  }

  @override
  Widget build(BuildContext context) {
    final directory = ref.watch(careDirectoryProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      children: [
        const CareBackRow(),
        const SizedBox(height: 6),
        const Text('PERSONAS QUE PUEDEN ACOMPAÑARTE',
            style: AppTypography.sectionLabel),
        const SizedBox(height: 10),
        if (_locked) ...[
          CareLockBanner(
            name: widget.pending?.providerName == null
                ? 'esa persona'
                : shortProviderName(widget.pending!.providerName!),
          ),
          const SizedBox(height: 10),
        ] else ...[
          Text.rich(
            TextSpan(children: [
              TextSpan(
                text: 'Elige con quién dar ',
                style: _serif(context),
              ),
              TextSpan(
                text: 'el primer paso.',
                style: _serifAccent(context),
              ),
            ]),
          ),
          const SizedBox(height: 14),
        ],
        CareSearchField(
          controller: _searchController,
          enabled: !_locked,
          onChanged: (value) => setState(() => _query = value),
          onClear: () {
            _searchController.clear();
            setState(() => _query = '');
          },
        ),
        const SizedBox(height: 10),
        CareTierChips(
          selected: _tier,
          enabled: !_locked,
          onSelected: (tier) => setState(() => _tier = tier),
        ),
        const SizedBox(height: 12),
        ...directory.when(
          loading: () => const [
            Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(color: AppColors.careAccent),
              ),
            ),
          ],
          error: (_, _) => [
            _ErrorRetry(onRetry: () => ref.invalidate(careDirectoryProvider)),
          ],
          data: (providers) => _directoryList(context, providers),
        ),
        const SizedBox(height: 20),
        if (_locked)
          CarePrimaryButton(
            label: 'Ver mi solicitud',
            crimson: true,
            onPressed: () => context.go(AppRoutes.careRequest),
          )
        else
          const Center(
            child: Text(
              'Sigo aquí contigo — esto solo añade\nuna persona más a tu lado.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
            ),
          ),
      ],
    );
  }

  List<Widget> _directoryList(
      BuildContext context, List<CareProviderInfo> providers) {
    // En modo pendiente no se filtra: el directorio descansa tal cual.
    final visible = _locked
        ? providers
        : filterProviders(providers, query: _query, tier: _tier);
    final support = visible.where((p) => p.tier == 'support').toList();
    final clinical = visible.where((p) => p.tier == 'clinical').toList();
    return [
      if (support.isNotEmpty) ...[
        const CareTierLabel(tier: 'support'),
        const SizedBox(height: 8),
        for (final provider in support) _providerTile(context, provider),
      ],
      if (clinical.isNotEmpty) ...[
        const SizedBox(height: 10),
        const CareTierLabel(tier: 'clinical'),
        const SizedBox(height: 8),
        for (final provider in clinical) _providerTile(context, provider),
      ],
      if (visible.isEmpty && _query.trim().isNotEmpty)
        // Nunca un vacío sin salida (D2).
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: const Text(
            'No encontré a nadie así.\n'
            'Prueba con menos letras — o borra la búsqueda y mira por nivel.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 12.5, height: 1.6, color: AppColors.textSecondary),
          ),
        )
      else if (visible.isEmpty)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 18),
          child: Text(
            'El directorio se está formando. Vuelve pronto — sin prisa.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
        ),
    ];
  }

  Widget _providerTile(BuildContext context, CareProviderInfo provider) {
    final isRequested =
        _locked && provider.id == widget.pending?.providerId;
    final isResting = _locked && !isRequested;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Opacity(
        opacity: isResting ? 0.45 : 1,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: isRequested
              ? () => context.go(AppRoutes.careRequest)
              : isResting
                  ? _showOneAtATime
                  : () => context.go(AppRoutes.careConsent, extra: provider),
          child: CareProviderCard(
            name: provider.fullName,
            meta: providerMetaLine(provider),
            tier: provider.tier,
            highlighted: isRequested,
            trailing: isRequested
                ? const CareSentBadge()
                : isResting
                    ? const Icon(Icons.lock_outline,
                        size: 16, color: Color(0xFFB9AFC2))
                    : const Icon(Icons.chevron_right,
                        size: 20, color: AppColors.textSecondary),
          ),
        ),
      ),
    );
  }
}

// ── A5 · Respuesta recibida: aceptó ─────────────────────────────────────────
class _ResponseAcceptedView extends ConsumerStatefulWidget {
  const _ResponseAcceptedView({required this.referral});

  final CareReferral referral;

  @override
  ConsumerState<_ResponseAcceptedView> createState() =>
      _ResponseAcceptedViewState();
}

class _ResponseAcceptedViewState extends ConsumerState<_ResponseAcceptedView> {
  bool _saving = false;

  /// "Ya me puse en contacto": SU máquina avanza offered→accepted→connected.
  /// Lo marca ELLA — el sistema jamás la conecta solo.
  Future<void> _markContacted() async {
    setState(() => _saving = true);
    try {
      await advanceCareReferral(ref,
          referralId: widget.referral.id, status: 'accepted');
      await advanceCareReferral(ref,
          referralId: widget.referral.id, status: 'connected');
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo guardar. Inténtalo de nuevo.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final referral = widget.referral;
    final fullName = referral.providerName ?? 'Tu persona de apoyo';
    final name = shortProviderName(fullName);
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      children: [
        const CareBackRow(),
        const SizedBox(height: 6),
        const Text('TU EPISODIO DE APOYO', style: AppTypography.sectionLabel),
        const SizedBox(height: 10),
        CareProviderCard(
          name: fullName,
          meta: 'Aceptó tu petición ✦',
          metaColor: AppColors.careAccent,
          tier: 'support',
        ),
        const SizedBox(height: 16),
        Text.rich(
          TextSpan(children: [
            TextSpan(text: '$name dijo que sí. ', style: _serif(context)),
            TextSpan(
              text: 'Cuando tú quieras.',
              style: _serifAccent(context),
            ),
          ]),
        ),
        const SizedBox(height: 14),
        CareContactCard(
          contact: referral.providerContact,
          note: 'Escríbele cuando te venga bien. '
              'Sin prisa: el primer paso ya lo diste.',
        ),
        const SizedBox(height: 14),
        CarePrimaryButton(
          label: 'Ya me puse en contacto',
          outlined: true,
          busy: _saving,
          onPressed: _markContacted,
        ),
        const SizedBox(height: 8),
        Center(
          child: TextButton(
            onPressed: () => context.go(AppRoutes.home),
            child: const Text(
              'Volver a mi espacio',
              style: TextStyle(
                  fontWeight: FontWeight.w400, color: AppColors.textSecondary),
            ),
          ),
        ),
      ],
    );
  }
}

// ── A5b · Respuesta recibida: no puede ahora ─────────────────────────────────
class _ResponseDeclinedView extends ConsumerStatefulWidget {
  const _ResponseDeclinedView({required this.referral});

  final CareReferral referral;

  @override
  ConsumerState<_ResponseDeclinedView> createState() =>
      _ResponseDeclinedViewState();
}

class _ResponseDeclinedViewState extends ConsumerState<_ResponseDeclinedView> {
  bool _saving = false;

  /// "Ver otras personas": cierra esta petición (declined, terminal) y el
  /// mismo estado del servidor la devuelve al directorio.
  Future<void> _backToDirectory() async {
    setState(() => _saving = true);
    try {
      await advanceCareReferral(ref,
          referralId: widget.referral.id, status: 'declined');
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo guardar. Inténtalo de nuevo.')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.referral.providerName == null
        ? 'Esa persona'
        : shortProviderName(widget.referral.providerName!);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: EdgeInsets.only(top: 12),
              child: CareBackRow(),
            ),
          ),
          const Spacer(),
          Text.rich(
            TextSpan(children: [
              TextSpan(
                  text: '$name no puede acompañarte\nen este momento. ',
                  style: _serif(context)),
              TextSpan(
                text: 'No dice nada de ti.',
                style: _serifAccent(context),
              ),
            ]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          const Text(
            'Hay más personas en el directorio, cuando quieras. '
            'Sin prisa — tu espacio sigue aquí.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 13.5, height: 1.55, color: AppColors.textSecondary),
          ),
          const Spacer(),
          CarePrimaryButton(
            label: 'Ver otras personas',
            busy: _saving,
            onPressed: _backToDirectory,
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: () => context.go(AppRoutes.home),
              child: const Text(
                'Volver a mi espacio',
                style: TextStyle(
                    fontWeight: FontWeight.w400,
                    color: AppColors.textSecondary),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ── A6 · Episodio en curso + cierre (B-3) ────────────────────────────────────
class _EpisodeView extends ConsumerStatefulWidget {
  const _EpisodeView({required this.referral});

  final CareReferral referral;

  @override
  ConsumerState<_EpisodeView> createState() => _EpisodeViewState();
}

class _EpisodeViewState extends ConsumerState<_EpisodeView> {
  String? _outcome; // voluntario: null = no decir nada, con idéntica dignidad
  bool _saving = false;

  Future<void> _closeChapter() async {
    // Capturado ANTES de los await: el invalidate reconstruye CareScreen y
    // este subárbol puede desmontarse con el diálogo aún abierto — la vuelta
    // al perfil no depende de seguir montados.
    final router = GoRouter.of(context);
    setState(() => _saving = true);
    String? closingMessage;
    try {
      closingMessage = await advanceCareReferral(
        ref,
        referralId: widget.referral.id,
        status: 'closed',
        closeOutcome: _outcome,
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo cerrar. Inténtalo de nuevo.')),
        );
      }
      if (mounted) setState(() => _saving = false);
      return;
    }
    // Mensaje CARE_CLOSE del servidor (neutral al resultado), y de vuelta al
    // perfil: la fila CUIDADO regresa a su estado base. Sin confeti (no es
    // un logro gamificado, es una despedida serena). El diálogo vive en el
    // navigator raíz: sobrevive aunque este subárbol se reconstruya.
    final message = closingMessage;
    if (message != null && mounted) {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => Dialog(
          backgroundColor: AppColors.surface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 26, 24, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: AppTypography.serif,
                    fontStyle: FontStyle.italic,
                    fontSize: 17,
                    height: 1.5,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 14),
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text(
                    'Gracias',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.careAccent),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    router.go(AppRoutes.profile);
  }

  @override
  Widget build(BuildContext context) {
    final referral = widget.referral;
    final name = referral.providerName ?? 'Tu persona de apoyo';
    final connected = referral.status == 'connected';

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      children: [
        const CareBackRow(),
        const SizedBox(height: 6),
        const Text('TU EPISODIO DE APOYO', style: AppTypography.sectionLabel),
        const SizedBox(height: 10),
        CareProviderCard(
          name: name,
          meta: connected ? 'Conectadas' : 'A tu lado',
          tier: 'support',
        ),
        const SizedBox(height: 12),
        // Pasos: SOLO lo andado — nunca cuánto falta (GUARD_TONE del care).
        CareSteps(connected: connected),
        const SizedBox(height: 12),
        CareContactCard(
          contact: referral.providerContact,
          note: 'Su contacto sigue aquí, siempre a mano.',
        ),
        const SizedBox(height: 26),
        Text('¿Quieres cerrar este capítulo?',
            style: _serif(context).copyWith(fontSize: 18)),
        const SizedBox(height: 6),
        const Text(
          'Solo si tú lo decides. Puedes contarme cómo fue — o no. '
          'Las dos cosas están bien.',
          style: TextStyle(
              fontSize: 12.5, height: 1.5, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (value, label) in const [
              ('helped', 'Me ayudó'),
              ('not_for_me', 'No era para mí'),
              ('prefer_not_say', 'Prefiero no decir'),
            ])
              ChoiceChip(
                label: Text(label),
                selected: _outcome == value,
                onSelected: (selected) =>
                    setState(() => _outcome = selected ? value : null),
                selectedColor: AppColors.careSurface,
                backgroundColor: AppColors.surface,
                labelStyle: TextStyle(
                  fontSize: 12.5,
                  color: _outcome == value
                      ? AppColors.careAccent
                      : AppColors.textPrimary,
                  fontWeight:
                      _outcome == value ? FontWeight.w700 : FontWeight.w400,
                ),
                side: BorderSide(
                  color: _outcome == value
                      ? AppColors.careBorder
                      : AppColors.border,
                ),
                showCheckmark: false,
              ),
          ],
        ),
        const SizedBox(height: 14),
        CarePrimaryButton(
          label: 'Cerrar este capítulo',
          crimson: true,
          busy: _saving,
          onPressed: _closeChapter,
        ),
      ],
    );
  }
}

// ── comunes ──────────────────────────────────────────────────────────────────
// Tipografía del mockup: base serif w600 SIN itálica; el acento va en
// itálica carmesí (h2.serif i del maquetado).
TextStyle _serif(BuildContext context) =>
    Theme.of(context).textTheme.headlineMedium!.copyWith(
          fontSize: 20,
          height: 1.35,
          fontWeight: FontWeight.w600,
          fontStyle: FontStyle.normal,
          color: AppColors.textPrimary,
        );

TextStyle _serifAccent(BuildContext context) => _serif(context).copyWith(
      fontStyle: FontStyle.italic,
      color: AppColors.primary,
    );

class _ErrorRetry extends StatelessWidget {
  const _ErrorRetry({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'No se pudo cargar. Sin prisa.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onRetry,
            child: const Text('Reintentar',
                style: TextStyle(color: AppColors.careAccent)),
          ),
        ],
      ),
    );
  }
}
