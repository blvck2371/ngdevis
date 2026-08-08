import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'cover_data.dart';
import 'cover_field_slot.dart';

/// API minimale exposée aux fichiers `layouts/` pour le rendu custom.
abstract class CoverLayoutContext {
  double get pageW;
  double dim(double px);
  double pt(double designPt);

  pw.Widget place(
    double leftPx,
    double topPx, {
    double? widthPx,
    double? heightPx,
    required pw.Widget child,
  });

  pw.Widget? logo(CoverLogoConfig config, pw.ImageProvider? image);
  List<pw.Widget> field(CoverFieldBinding binding, CoverData data);
  List<pw.Widget> placeSlot(CoverFieldSlot slot, String text);
}

/// Rectangle de masquage (efface le texte placeholder du PNG).
class CoverMaskRect {
  final double left;
  final double top;
  final double width;
  final double height;
  final PdfColor color;

  const CoverMaskRect({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required this.color,
  });
}

/// Emplacement du logo sur le gabarit PNG.
class CoverLogoConfig {
  final double left;
  final double top;
  final double width;
  final double maxHeight;
  final CoverMaskRect? mask;

  const CoverLogoConfig({
    required this.left,
    required this.top,
    required this.width,
    required this.maxHeight,
    this.mask,
  });
}

/// Lie un [CoverFieldSlot] à une valeur de [CoverData].
class CoverFieldBinding {
  final CoverFieldSlot slot;
  final String? Function(CoverData data) value;
  final String Function(String text)? format;
  final bool skipIfEmpty;

  const CoverFieldBinding({
    required this.slot,
    required this.value,
    this.format,
    this.skipIfEmpty = true,
  });
}

/// Définition complète d'une couverture PNG (1055×1491 px).
class PngCoverDefinition {
  final List<CoverMaskRect> masks;
  final CoverLogoConfig? logo;
  final List<CoverFieldBinding> fields;
  final List<pw.Widget> Function(
    CoverLayoutContext layout,
    CoverData data,
    pw.ImageProvider? logo,
  )? extras;

  const PngCoverDefinition({
    this.masks = const [],
    this.logo,
    this.fields = const [],
    this.extras,
  });
}

/// Définition d'une couverture vectorielle (coordonnées en points PDF A4).
class VectorCoverDefinition {
  final List<CoverFieldBinding> fields;
  final List<pw.Widget> Function(
    CoverLayoutContext layout,
    CoverData data,
    pw.ImageProvider? logo,
  ) buildDecorations;

  const VectorCoverDefinition({
    this.fields = const [],
    required this.buildDecorations,
  });
}
