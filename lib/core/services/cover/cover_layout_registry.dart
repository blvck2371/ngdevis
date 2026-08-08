import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'cover_template.dart';
import 'cover_data.dart';
import 'cover_layout.dart';
import 'cover_layout_engine.dart';
import 'black_gold_luxe_layout.dart';
import 'corporate_navy_gold_layout.dart';
import 'minimalist_gold_layout.dart';
import 'navy_arabesque_layout.dart';
import 'navy_geometric_layout.dart';
import 'oriental_orange_layout.dart';
import 'prestige_emerald_layout.dart';
import 'studio_slate_layout.dart';

/// Registre central : associe chaque [CoverTemplate] à sa définition de layout.
abstract final class CoverLayoutRegistry {
  static PngCoverDefinition png(CoverTemplate template) {
    return switch (template) {
      CoverTemplate.orientalOrange => OrientalOrangeLayout.definition,
      CoverTemplate.corporateNavyGold => CorporateNavyGoldLayout.definition,
      CoverTemplate.blackGoldLuxe => BlackGoldLuxeLayout.definition,
      CoverTemplate.navyGeometric => NavyGeometricLayout.definition,
      CoverTemplate.navyArabesque => NavyArabesqueLayout.definition,
      CoverTemplate.minimalistGold => MinimalistGoldLayout.definition,
      _ => throw ArgumentError('Template PNG inconnu: $template'),
    };
  }

  static VectorCoverDefinition vector(CoverTemplate template) {
    return switch (template) {
      CoverTemplate.studioSlate => StudioSlateLayout.definition,
      CoverTemplate.prestigeEmerald => PrestigeEmeraldLayout.definition,
      _ => throw ArgumentError('Template vectoriel inconnu: $template'),
    };
  }

  static pw.Widget build({
    required CoverTemplate template,
    required CoverData data,
    required double w,
    required double h,
    pw.ImageProvider? logo,
    pw.MemoryImage? bg,
  }) {
    if (template.isVectorCover) {
      return VectorCoverBuilder.build(
        definition: vector(template),
        data: data,
        w: w,
        h: h,
        logo: logo,
        backgroundColor: template == CoverTemplate.studioSlate
            ? PdfColor.fromInt(0xFFF5F7FA)
            : PdfColors.white,
      );
    }

    return PngCoverBuilder.build(
      definition: png(template),
      data: data,
      w: w,
      h: h,
      logo: logo,
      bg: bg,
    );
  }
}
