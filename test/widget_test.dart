// Test du tableau de bord NG Devis.

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:ngdevis/core/controllers/company_controller.dart';
import 'package:ngdevis/core/controllers/designation_controller.dart';
import 'package:ngdevis/core/controllers/devis_controller.dart';
import 'package:ngdevis/main.dart';

void main() {
  testWidgets('Dashboard affiche le titre et le menu', (WidgetTester tester) async {
    Get.testMode = true;
    Get.put(DesignationController());
    Get.put(DevisController());
    Get.put(CompanyController());

    await tester.pumpWidget(const NgDevisApp());
    await tester.pumpAndSettle();

    expect(find.text('NG Devis'), findsOneWidget);
    expect(find.text('Créer un devis'), findsOneWidget);
    expect(find.text('Historique des devis'), findsOneWidget);
    expect(find.text('Désignations (matériaux)'), findsOneWidget);
    expect(find.text('Paramètres entreprise'), findsOneWidget);
  });
}
