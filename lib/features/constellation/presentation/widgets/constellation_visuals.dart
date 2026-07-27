import '../../../../shared/domain/constellation.dart';

/// Ilustraciones de constelación del DISEÑADOR: se asignan de forma
/// determinista por número de ciclo, rotando el set completo (5 piezas).
/// El orden preserva lo ya visto: ciclo 1 sagitario, 2 tauro; aries y cáncer
/// (recuperadas de aura_preview, rótulo horneado recortado como serena)
/// entran a partir del ciclo 3. NO reordenar: cambiaría cielos ya vividos.
const _images = [
  'assets/images/constellation/sagitario.png',
  'assets/images/constellation/tauro.png',
  'assets/images/constellation/aries.png',
  'assets/images/constellation/cancer.png',
  'assets/images/constellation/serena.png',
];

extension ConstellationVisuals on Constellation {
  String get imageAsset => _images[(cycleNumber - 1) % _images.length];
}
