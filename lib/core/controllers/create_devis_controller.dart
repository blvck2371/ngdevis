import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../models/devis.dart';
import '../models/client.dart';
import '../models/devis_item.dart';
import '../models/section_devis.dart';
import '../models/designation.dart';
import 'devis_controller.dart';
import 'company_controller.dart';
import 'designation_controller.dart';

class CreateDevisController extends GetxController {
  final titreDevis = ''.obs;
  final noteNb = ''.obs;
  final numero = ''.obs;
  final nomEntreprise = ''.obs;
  final telEntreprise = ''.obs;
  final adresseEntreprise = ''.obs;
  final logoPath = ''.obs;

  final clientNom = ''.obs;
  final clientTel = ''.obs;
  final clientAdresse = ''.obs;

  final sections = <SectionDevis>[].obs;
  String? editingDevisId;

  @override
  void onInit() {
    super.onInit();
    _loadCompanyDefaults();
  }

  void _loadCompanyDefaults() {
    final company = Get.find<CompanyController>();
    nomEntreprise.value = company.nom.value;
    telEntreprise.value = company.telephone.value;
    adresseEntreprise.value = company.adresse.value;
    logoPath.value = company.logoPath.value;
  }

  void initForNew() {
    initForNewWithCategories(['Plomberie']);
  }

  /// Initialise un nouveau devis avec les catégories choisies (une section = une catégorie).
  void initForNewWithCategories(List<String> categories) {
    editingDevisId = null;
    titreDevis.value = '';
    noteNb.value = 'nous travaillons selon la norme DTU 60.1';
    numero.value = Get.find<DevisController>().nextNumero();
    _loadCompanyDefaults();
    clientNom.value = '';
    clientTel.value = '';
    clientAdresse.value = '';
    sections.clear();
    for (final cat in categories) {
      if (cat.trim().isNotEmpty) {
        sections.add(SectionDevis(titre: cat.trim()));
      }
    }
    if (sections.isEmpty) sections.add(SectionDevis(titre: ''));
  }

  void initForEdit(Devis d) {
    editingDevisId = d.id;
    titreDevis.value = d.titreDevis ?? '';
    noteNb.value = d.noteNb ?? '';
    numero.value = d.numero;
    nomEntreprise.value = d.nomEntreprise ?? '';
    telEntreprise.value = d.telEntreprise ?? '';
    adresseEntreprise.value = d.adresseEntreprise ?? '';
    logoPath.value = d.logoPath ?? '';
    clientNom.value = d.client?.nom ?? '';
    clientTel.value = d.client?.telephone ?? '';
    clientAdresse.value = d.client?.adresse ?? '';
    sections.assignAll(d.sections.map((s) => SectionDevis(
          titre: s.titre,
          items: s.items.map((i) => DevisItem(designation: i.designation, quantite: i.quantite, prixUnitaire: i.prixUnitaire, designationId: i.designationId)).toList(),
          mainOeuvrePercent: s.mainOeuvrePercent,
          mainOeuvreFixed: s.mainOeuvreFixed,
        )));
  }

  Future<void> pickLogo() async {
    final picker = ImagePicker();
    final x = await picker.pickImage(source: ImageSource.gallery);
    if (x != null) {
      logoPath.value = x.path;
    }
  }

  void addSection() {
    sections.add(SectionDevis(titre: 'Nouvelle section'));
    autoSave();
  }

  void removeSectionAt(int index) {
    if (sections.length > 1) {
      sections.removeAt(index);
      autoSave();
    }
  }

  void addItemToSection(int sectionIndex, {Designation? fromDesignation}) {
    if (sectionIndex < 0 || sectionIndex >= sections.length) return;
    final s = sections[sectionIndex];
    if (fromDesignation != null) {
      s.items.add(DevisItem(
        designation: fromDesignation.nom,
        quantite: 1,
        prixUnitaire: fromDesignation.prixUnitaire,
        designationId: fromDesignation.id,
      ));
    } else {
      s.items.add(DevisItem(designation: '', quantite: 1, prixUnitaire: 0));
    }
    sections.refresh();
  }

  /// Ajoute une ligne depuis la modale. Catégorie = titre de la section (ex: Plomberie, Maçonnerie).
  /// Si la désignation n'existait pas en base, elle est créée et enregistrée dans les désignations sous sa catégorie.
  Future<bool> addItemFromModal(int sectionIndex, String designationNom, double quantite, double prixUnitaire, [String? category]) async {
    if (sectionIndex < 0 || sectionIndex >= sections.length) return false;
    final s = sections[sectionIndex];
    final titreTrim = s.titre.trim();
    final categorie = category ?? (titreTrim.isEmpty ? '' : titreTrim);
    final dc = Get.find<DesignationController>();
    final (d, wasCreated) = await dc.ensureDesignation(designationNom, prixUnitaire, categorie);
    s.items.add(DevisItem(
      designation: d.nom,
      quantite: quantite,
      prixUnitaire: prixUnitaire,
      designationId: d.id,
    ));
    sections.refresh();
    autoSave();
    return wasCreated;
  }

  void removeItemFromSection(int sectionIndex, int itemIndex) {
    if (sectionIndex < 0 || sectionIndex >= sections.length) return;
    final s = sections[sectionIndex];
    if (itemIndex >= 0 && itemIndex < s.items.length) {
      s.items.removeAt(itemIndex);
      sections.refresh();
      autoSave();
    }
  }

  /// Réordonne une ligne (glisser-déposer) : ancien index → index de destination (après dépôt).
  void reorderItem(int sectionIndex, int oldIndex, int newIndex) {
    if (sectionIndex < 0 || sectionIndex >= sections.length) return;
    final s = sections[sectionIndex];
    if (oldIndex < 0 || oldIndex >= s.items.length) return;
    if (oldIndex == newIndex) return;
    final item = s.items.removeAt(oldIndex);
    final insertAt = newIndex.clamp(0, s.items.length);
    s.items.insert(insertAt, item);
    sections.refresh();
    autoSave();
  }

  void updateItemInSection(int sectionIndex, int itemIndex, DevisItem item) {
    if (sectionIndex < 0 || sectionIndex >= sections.length) return;
    final s = sections[sectionIndex];
    if (itemIndex >= 0 && itemIndex < s.items.length) {
      s.items[itemIndex] = item;
      sections.refresh();
    }
  }

  /// Définit le pourcentage de main d'œuvre (ex. 15 pour 15%) appliqué au total matériel de la section.
  void setSectionMainOeuvrePercent(int sectionIndex, double percent) {
    if (sectionIndex >= 0 && sectionIndex < sections.length) {
      final s = sections[sectionIndex];
      s.mainOeuvrePercent = percent.clamp(0.0, 100.0);
      s.mainOeuvreFixed = 0;
      sections.refresh();
    }
  }

  /// Enregistre le devis et met à jour les paramètres entreprise. Retourne null si le devis est vide (aucune ligne).
  Future<Devis?> save() async {
    final hasAnyLine = sections.any((s) => s.items.isNotEmpty);
    if (!hasAnyLine) return null;

    final client = (clientNom.value.trim().isNotEmpty || clientTel.value.trim().isNotEmpty)
        ? Client(
            id: const Uuid().v4(),
            nom: clientNom.value.trim(),
            telephone: clientTel.value.trim(),
            adresse: clientAdresse.value.trim(),
          )
        : null;

    final devis = Devis(
      id: editingDevisId ?? const Uuid().v4(),
      numero: numero.value.trim().isEmpty ? Get.find<DevisController>().nextNumero() : numero.value.trim(),
      date: editingDevisId != null ? (Get.find<DevisController>().getById(editingDevisId!)?.date ?? DateTime.now()) : DateTime.now(),
      client: client,
      sections: sections.toList(),
      titreDevis: titreDevis.value.trim().isEmpty ? null : titreDevis.value.trim(),
      noteNb: noteNb.value.trim().isEmpty ? null : noteNb.value.trim(),
      logoPath: logoPath.value.trim().isEmpty ? null : logoPath.value.trim(),
      nomEntreprise: nomEntreprise.value.trim().isEmpty ? null : nomEntreprise.value.trim(),
      telEntreprise: telEntreprise.value.trim().isEmpty ? null : telEntreprise.value.trim(),
      adresseEntreprise: adresseEntreprise.value.trim().isEmpty ? null : adresseEntreprise.value.trim(),
    );

    await Get.find<DevisController>().saveDevis(devis);

    // Mettre à jour les paramètres entreprise pour la prochaine fois
    final company = Get.find<CompanyController>();
    company.nom.value = nomEntreprise.value;
    company.telephone.value = telEntreprise.value;
    company.adresse.value = adresseEntreprise.value;
    company.logoPath.value = logoPath.value;
    await company.save();

    return devis;
  }

  double get total => sections.fold(0.0, (sum, s) => sum + s.totalSection);

  /// Construit le devis actuel à partir du formulaire (pour aperçu PDF sans sauvegarde).
  Devis buildCurrentDevis() {
    final client = (clientNom.value.trim().isNotEmpty || clientTel.value.trim().isNotEmpty)
        ? Client(
            id: const Uuid().v4(),
            nom: clientNom.value.trim(),
            telephone: clientTel.value.trim(),
            adresse: clientAdresse.value.trim(),
          )
        : null;
    return Devis(
      id: editingDevisId ?? const Uuid().v4(),
      numero: numero.value.trim().isEmpty ? Get.find<DevisController>().nextNumero() : numero.value.trim(),
      date: DateTime.now(),
      client: client,
      sections: sections.toList(),
      titreDevis: titreDevis.value.trim().isEmpty ? null : titreDevis.value.trim(),
      noteNb: noteNb.value.trim().isEmpty ? null : noteNb.value.trim(),
      logoPath: logoPath.value.trim().isEmpty ? null : logoPath.value.trim(),
      nomEntreprise: nomEntreprise.value.trim().isEmpty ? null : nomEntreprise.value.trim(),
      telEntreprise: telEntreprise.value.trim().isEmpty ? null : telEntreprise.value.trim(),
      adresseEntreprise: adresseEntreprise.value.trim().isEmpty ? null : adresseEntreprise.value.trim(),
    );
  }

  /// Sauvegarde automatique du devis dans l’historique (sans mettre à jour les paramètres entreprise).
  /// Ne fait rien si le devis ne contient aucune ligne (aucun enregistrement).
  Future<void> autoSave() async {
    final hasAnyLine = sections.any((s) => s.items.isNotEmpty);
    if (!hasAnyLine) return;

    final client = (clientNom.value.trim().isNotEmpty || clientTel.value.trim().isNotEmpty)
        ? Client(
            id: const Uuid().v4(),
            nom: clientNom.value.trim(),
            telephone: clientTel.value.trim(),
            adresse: clientAdresse.value.trim(),
          )
        : null;
    final id = editingDevisId ?? const Uuid().v4();
    final date = editingDevisId != null
        ? (Get.find<DevisController>().getById(editingDevisId!)?.date ?? DateTime.now())
        : DateTime.now();
    final devis = Devis(
      id: id,
      numero: numero.value.trim().isEmpty ? Get.find<DevisController>().nextNumero() : numero.value.trim(),
      date: date,
      client: client,
      sections: sections.toList(),
      titreDevis: titreDevis.value.trim().isEmpty ? null : titreDevis.value.trim(),
      noteNb: noteNb.value.trim().isEmpty ? null : noteNb.value.trim(),
      logoPath: logoPath.value.trim().isEmpty ? null : logoPath.value.trim(),
      nomEntreprise: nomEntreprise.value.trim().isEmpty ? null : nomEntreprise.value.trim(),
      telEntreprise: telEntreprise.value.trim().isEmpty ? null : telEntreprise.value.trim(),
      adresseEntreprise: adresseEntreprise.value.trim().isEmpty ? null : adresseEntreprise.value.trim(),
    );
    await Get.find<DevisController>().saveDevis(devis);
    if (editingDevisId == null) editingDevisId = devis.id;
  }
}
