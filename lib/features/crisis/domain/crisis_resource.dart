/// Un recurso de ayuda inmediata (contrato `CrisisResource`).
///
/// Entidad pura: sin Dio, sin Flutter. `kind` distingue una línea de ESCUCHA
/// de una emergencia médica — no son lo mismo y la UI no las pinta igual: el
/// 112 va en segundo plano para no competir con quien atiende a alguien que
/// solo necesita hablar.
class CrisisResource {
  const CrisisResource({
    required this.name,
    required this.phone,
    required this.kind,
    this.note,
  });

  final String name;

  /// Marcable tal cual: solo dígitos, espacios y '+'.
  final String phone;
  final String? note;
  final CrisisResourceKind kind;

  factory CrisisResource.fromJson(Map<dynamic, dynamic> json) => CrisisResource(
        name: json['name'] as String,
        phone: json['phone'] as String,
        note: json['note'] as String?,
        kind: CrisisResourceKind.fromWire(json['kind'] as String? ?? 'listening'),
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'phone': phone,
        'note': ?note,
        'kind': kind.wireValue,
      };
}

enum CrisisResourceKind {
  listening('listening'),
  emergency('emergency');

  const CrisisResourceKind(this.wireValue);

  final String wireValue;

  /// Tolerante: un tipo nuevo del servidor se pinta como línea de escucha
  /// antes que romper la pantalla. Aquí, no mostrar nada es lo peor posible.
  static CrisisResourceKind fromWire(String value) => values.firstWhere(
        (e) => e.wireValue == value,
        orElse: () => CrisisResourceKind.listening,
      );
}

/// Lo que se pinta en la pantalla de ayuda: dos frases y los recursos.
class CrisisHelp {
  const CrisisHelp({
    required this.intro,
    required this.resources,
    required this.closing,
  });

  final String intro;
  final List<CrisisResource> resources;
  final String closing;

  factory CrisisHelp.fromJson(Map<dynamic, dynamic> json) => CrisisHelp(
        intro: (json['intro'] as String?) ?? '',
        resources: [
          for (final r in (json['resources'] as List? ?? const []))
            CrisisResource.fromJson(r as Map),
        ],
        closing: (json['closing'] as String?) ?? '',
      );

  Map<String, dynamic> toJson() => {
        'intro': intro,
        'resources': [for (final r in resources) r.toJson()],
        'closing': closing,
      };
}
