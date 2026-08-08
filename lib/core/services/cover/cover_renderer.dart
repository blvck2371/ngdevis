import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'cover_data.dart';
import 'cover_template.dart';
import 'cover_layout_registry.dart';

export 'cover_data.dart';

/// Chargeur d'images PNG des templates (mémoïsé).
class CoverImageLoader {
  static final Map<String, pw.MemoryImage?> _cache = {};

  static Future<pw.MemoryImage?> load(String assetPath) async {
    if (_cache.containsKey(assetPath)) return _cache[assetPath];
    try {
      final data = await rootBundle.load(assetPath);
      final img = pw.MemoryImage(data.buffer.asUint8List());
      _cache[assetPath] = img;
      return img;
    } catch (_) {
      _cache[assetPath] = null;
      return null;
    }
  }
}

/// Renderer principal : délègue au registre de layouts par template.
class CoverRenderer {
  static Future<pw.Widget> buildForFormat({
    required CoverTemplate template,
    required PdfPageFormat pageFormat,
    required CoverData data,
    pw.ImageProvider? logo,
  }) async {
    if (template == CoverTemplate.classic) {
      return pw.Container(color: PdfColors.white);
    }

    final w = pageFormat.width;
    final h = pageFormat.height;

    if (template.isVectorCover) {
      return CoverLayoutRegistry.build(
        template: template,
        data: data,
        w: w,
        h: h,
        logo: logo,
      );
    }

    final bg = await CoverImageLoader.load(template.assetPath!);
    return CoverLayoutRegistry.build(
      template: template,
      data: data,
      w: w,
      h: h,
      logo: logo,
      bg: bg,
    );
  }
}
