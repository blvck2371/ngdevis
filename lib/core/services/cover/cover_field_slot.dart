import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Position d'un **seul** champ texte sur un template (PNG 1055×1491 px ou PDF A4).
///
/// Modifiez [left], [top], [width] et [fontPt] pour caler le texte sur le gabarit.
/// Toutes les valeurs sont en **pixels du fichier PNG** (coin haut-gauche).
class CoverFieldSlot {
  final double left;
  final double top;
  final double? width;
  final double fontPt;
  final bool bold;
  final bool italic;
  final bool uppercase;
  final PdfColor color;
  final PdfColor? maskColor;
  final double maskHeight;
  final int maxLines;

  /// Libellé devant la valeur (ex. « Nom » pour le style cahier Oriental Orange).
  final String? labelPrefix;
  final PdfColor? labelColor;
  final bool dottedUnderline;

  /// Afficher « — » quand la valeur est vide (lignes client sur certains templates).
  final bool showPlaceholder;

  final pw.TextAlign? textAlign;
  final double? letterSpacing;
  final double lineHeight;

  const CoverFieldSlot({
    required this.left,
    required this.top,
    this.width,
    this.fontPt = 10.5,
    this.bold = false,
    this.italic = false,
    this.uppercase = false,
    this.color = PdfColors.black,
    this.maskColor,
    this.maskHeight = 14,
    this.maxLines = 1,
    this.labelPrefix,
    this.labelColor,
    this.dottedUnderline = false,
    this.showPlaceholder = false,
    this.textAlign,
    this.letterSpacing,
    this.lineHeight = 1.05,
  });
}
