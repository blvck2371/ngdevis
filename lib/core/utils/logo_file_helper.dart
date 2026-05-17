import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Copie le logo choisi dans le dossier documents de l’app (chemin stable pour le PDF et après redémarrage).
class LogoFileHelper {
  static const String _baseName = 'company_logo';

  static Future<String> persistPickerImage(XFile xfile) async {
    final bytes = await xfile.readAsBytes();
    final dir = await getApplicationDocumentsDirectory();
    var ext = p.extension(xfile.path).toLowerCase();
    if (ext.isEmpty || ext.length > 6) ext = '.jpg';
    final destPath = p.join(dir.path, '$_baseName$ext');
    final dest = File(destPath);
    await dest.writeAsBytes(bytes, flush: true);
    return dest.path;
  }
}
