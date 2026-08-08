import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../models/devis.dart';
import '../models/devis_status.dart';
import '../models/facture.dart';
import '../models/client.dart';
import '../models/devis_item.dart';
import '../models/section_devis.dart';
import '../models/designation.dart';
import 'devis_controller.dart';
import 'company_controller.dart';
import 'designation_controller.dart';
import '../utils/logo_file_helper.dart';

enum DeletedEntryType { section, item }

class DeletedEntry {
  final String id;
  final DeletedEntryType type;
  final DateTime deletedAt;
  final int sectionIndex;
  final int? itemIndex;
  final String sectionTitle;
  final SectionDevis? sectionSnapshot;
  final DevisItem? itemSnapshot;

  DeletedEntry.section({
    required this.id,
    required this.deletedAt,
    required this.sectionIndex,
    required this.sectionTitle,
    required this.sectionSnapshot,
  })  : type = DeletedEntryType.section,
        itemIndex = null,
        itemSnapshot = null;

  DeletedEntry.item({
    required this.id,
    required this.deletedAt,
    required this.sectionIndex,
    required this.itemIndex,
    required this.sectionTitle,
    required this.itemSnapshot,
  })  : type = DeletedEntryType.item,
        sectionSnapshot = null;
}

class CreateDevisController extends GetxController {
  static const _maxDeletedEntries = 30;
  final titreDevis = ''.obs;
  final noteNb = ''.obs;
  final numero = ''.obs;
  final nomEntreprise = ''.obs;
  final telEntreprise = ''.obs;
  final adresseEntreprise = ''.obs;
  final logoPath = ''.obs;

  final clientNom = ''.obs;
  final clientSociete = ''.obs;
  final clientTel = ''.obs;
  final clientAdresse = ''.obs;
  final clientEmail = ''.obs;
  final useManualMainOeuvre = false.obs;
  final manualMainOeuvre = 0.0.obs;

  final sections = <SectionDevis>[].obs;
  final deletedEntries = <DeletedEntry>[].obs;
  String? editingDevisId;

  /// Date du document (jour du devis, stats et graphiques). À l’import JSON ou
  /// depuis l’historique, égal au champ [Devis.date] du fichier ou de la copie Hive.
  /// Tant que l’entrée n’existe pas dans Hive (`getById` null), c’est elle qui prime.
  DateTime _documentDate = DateTime.now();

  /// Cycle de vie commercial — conservé à l’édition (évite reset brouillon à chaque save).
  DevisStatus _status = DevisStatus.brouillon;
  DateTime? _validUntil;
  DateTime? _sentAt;
  DateTime? _acceptedAt;
  DateTime? _refusedAt;
  DateTime? _convertedAt;
  String? _convertedFactureId;
  String? _internalNotes;
  String? _clientId;

  void _resetLifecycleFields() {
    _status = DevisStatus.brouillon;
    _validUntil = null;
    _sentAt = null;
    _acceptedAt = null;
    _refusedAt = null;
    _convertedAt = null;
    _convertedFactureId = null;
    _internalNotes = null;
    _clientId = null;
  }

  void _copyLifecycleFrom(Devis d) {
    _status = d.status;
    _validUntil = d.validUntil;
    _sentAt = d.sentAt;
    _acceptedAt = d.acceptedAt;
    _refusedAt = d.refusedAt;
    _convertedAt = d.convertedAt;
    _convertedFactureId = d.convertedFactureId;
    _internalNotes = d.internalNotes;
    _clientId = d.client?.id;
  }

  DateTime _effectiveDocumentDate() => _documentDate;

  /// Si `true`, le document en cours sera enregistré **directement comme facture**.
  /// Le devis intermédiaire est alors marqué `accepté` puis converti.
  final asInvoice = false.obs;

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
    asInvoice.value = false;
  }

  /// Initialise un nouveau devis avec les catégories choisies (une section = une catégorie).
  void initForNewWithCategories(List<String> categories) {
    editingDevisId = null;
    _documentDate = DateTime.now();
    _resetLifecycleFields();
    asInvoice.value = false;
    titreDevis.value = '';
    noteNb.value = 'nous travaillons selon la norme DTU 60.1';
    numero.value = Get.find<DevisController>().previewNextNumeroPro();
    _loadCompanyDefaults();
    clientNom.value = '';
    clientSociete.value = '';
    clientTel.value = '';
    clientAdresse.value = '';
    clientEmail.value = '';
    useManualMainOeuvre.value = false;
    manualMainOeuvre.value = 0;
    sections.clear();
    deletedEntries.clear();
    for (final cat in categories) {
      if (cat.trim().isNotEmpty) {
        sections.add(SectionDevis(titre: cat.trim()));
      }
    }
    if (sections.isEmpty) sections.add(SectionDevis(titre: ''));
  }

  /// Nouveau devis après saisie client (écran intermédiaire).
  void initForNewWithCategoriesAndClient(
    List<String> categories, {
    String clientNom = '',
    String clientSociete = '',
    String clientTel = '',
    String clientAdresse = '',
    String clientEmail = '',
    bool asInvoice = false,
  }) {
    initForNewWithCategories(categories);
    this.clientNom.value = clientNom;
    this.clientSociete.value = clientSociete;
    this.clientTel.value = clientTel;
    this.clientAdresse.value = clientAdresse;
    this.clientEmail.value = clientEmail;
    this.asInvoice.value = asInvoice;
  }

  void initForEdit(Devis d) {
    editingDevisId = d.id;
    _documentDate = d.date;
    _copyLifecycleFrom(d);
    titreDevis.value = d.titreDevis ?? '';
    noteNb.value = d.noteNb ?? '';
    numero.value = d.numero;
    nomEntreprise.value = d.nomEntreprise ?? '';
    telEntreprise.value = d.telEntreprise ?? '';
    adresseEntreprise.value = d.adresseEntreprise ?? '';
    logoPath.value = d.logoPath ?? '';
    clientNom.value = d.client?.nom ?? '';
    clientSociete.value = d.client?.societe ?? '';
    clientTel.value = d.client?.telephone ?? '';
    clientAdresse.value = d.client?.adresse ?? '';
    clientEmail.value = d.client?.email ?? '';
    useManualMainOeuvre.value = d.useManualMainOeuvre;
    manualMainOeuvre.value = d.manualMainOeuvre;
    sections.assignAll(d.sections.map((s) => SectionDevis(
          titre: s.titre,
          items: s.items.map((i) => DevisItem(
            designation: i.designation,
            quantite: i.quantite,
            prixUnitaire: i.prixUnitaire,
            designationId: i.designationId,
            unite: i.unite,
          )).toList(),
          mainOeuvrePercent: s.mainOeuvrePercent,
          mainOeuvreFixed: s.mainOeuvreFixed,
        )));
    deletedEntries.assignAll(_decodeDeletedEntries(d.deletedHistory));
  }

  Future<void> pickLogo() async {
    final picker = ImagePicker();
    final x = await picker.pickImage(source: ImageSource.gallery);
    if (x != null) {
      logoPath.value = await LogoFileHelper.persistPickerImage(x);
    }
  }

  void addSection() {
    sections.add(SectionDevis(titre: 'Nouvelle section'));
    autoSave();
  }

  void removeSectionAt(int index) {
    if (sections.length > 1) {
      final removed = _cloneSection(sections[index]);
      _pushDeletedEntry(
        DeletedEntry.section(
          id: const Uuid().v4(),
          deletedAt: DateTime.now(),
          sectionIndex: index,
          sectionTitle: removed.titre,
          sectionSnapshot: removed,
        ),
      );
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
        unite: fromDesignation.uniteDefaut,
      ));
    } else {
      s.items.add(DevisItem(designation: '', quantite: 1, prixUnitaire: 0));
    }
    sections.refresh();
  }

  /// Ajoute une ligne depuis la modale. Catégorie = titre de la section (ex: Plomberie, Maçonnerie).
  /// Si la désignation n'existait pas en base, elle est créée et enregistrée dans les désignations sous sa catégorie,
  /// avec l'unité [unite] comme unité par défaut.
  Future<bool> addItemFromModal(
    int sectionIndex,
    String designationNom,
    double quantite,
    double prixUnitaire, [
    String? category,
    String? unite,
  ]) async {
    if (sectionIndex < 0 || sectionIndex >= sections.length) return false;
    final s = sections[sectionIndex];
    final titreTrim = s.titre.trim();
    final categorie = category ?? (titreTrim.isEmpty ? '' : titreTrim);
    final dc = Get.find<DesignationController>();
    final (d, wasCreated) = await dc.ensureDesignation(
      designationNom,
      prixUnitaire,
      categorie,
      unite,
    );
    s.items.add(DevisItem(
      designation: d.nom,
      quantite: quantite,
      prixUnitaire: prixUnitaire,
      designationId: d.id,
      unite: unite ?? d.uniteDefaut,
    ));
    sections.refresh();
    autoSave();
    return wasCreated;
  }

  void removeItemFromSection(int sectionIndex, int itemIndex) {
    if (sectionIndex < 0 || sectionIndex >= sections.length) return;
    final s = sections[sectionIndex];
    if (itemIndex >= 0 && itemIndex < s.items.length) {
      final removed = _cloneItem(s.items[itemIndex]);
      _pushDeletedEntry(
        DeletedEntry.item(
          id: const Uuid().v4(),
          deletedAt: DateTime.now(),
          sectionIndex: sectionIndex,
          itemIndex: itemIndex,
          sectionTitle: s.titre,
          itemSnapshot: removed,
        ),
      );
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

  void restoreDeletedEntry(String id) {
    final historyIndex = deletedEntries.indexWhere((e) => e.id == id);
    if (historyIndex < 0) return;
    final entry = deletedEntries.removeAt(historyIndex);

    if (entry.type == DeletedEntryType.section) {
      final snapshot = entry.sectionSnapshot;
      if (snapshot == null) return;
      final insertAt = entry.sectionIndex.clamp(0, sections.length);
      sections.insert(insertAt, _cloneSection(snapshot));
      sections.refresh();
      autoSave();
      return;
    }

    final item = entry.itemSnapshot;
    if (item == null) return;
    if (sections.isEmpty) {
      sections.add(SectionDevis(titre: entry.sectionTitle.trim().isEmpty ? 'Section restaurée' : entry.sectionTitle.trim()));
    }
    final sectionTarget = entry.sectionIndex.clamp(0, sections.length - 1);
    final section = sections[sectionTarget];
    final insertAt = (entry.itemIndex ?? section.items.length).clamp(0, section.items.length);
    section.items.insert(insertAt, _cloneItem(item));
    sections.refresh();
    autoSave();
  }

  void clearDeletedHistory() {
    deletedEntries.clear();
  }

  void setUseManualMainOeuvre(bool enabled) {
    useManualMainOeuvre.value = enabled;
    autoSave();
  }

  void setManualMainOeuvreFromInput(String raw) {
    final parsed = double.tryParse(raw.replaceAll(',', '.')) ?? 0;
    final safe = parsed < 0 ? 0.0 : parsed;
    manualMainOeuvre.value = safe;
    autoSave();
  }

  /// Définit le pourcentage de main d'œuvre (ex. 15 pour 15%) appliqué au total matériel de la section.
  void setSectionMainOeuvrePercent(int sectionIndex, double percent) {
    if (sectionIndex >= 0 && sectionIndex < sections.length) {
      final s = sections[sectionIndex];
      s.mainOeuvrePercent = percent.clamp(0.0, 100.0).toDouble();
      s.mainOeuvreFixed = 0;
      sections.refresh();
    }
  }

  bool _hasClientInfo() {
    return clientNom.value.trim().isNotEmpty ||
        clientSociete.value.trim().isNotEmpty ||
        clientTel.value.trim().isNotEmpty ||
        clientAdresse.value.trim().isNotEmpty ||
        clientEmail.value.trim().isNotEmpty;
  }

  Client? _buildClient() {
    if (!_hasClientInfo()) return null;
    return Client(
      id: _clientId ?? const Uuid().v4(),
      nom: clientNom.value.trim(),
      societe: clientSociete.value.trim(),
      telephone: clientTel.value.trim(),
      adresse: clientAdresse.value.trim(),
      email: clientEmail.value.trim(),
    );
  }

  Devis _assembleDevis({required String id, required String numeroVal}) {
    return Devis(
      id: id,
      numero: numeroVal,
      date: _effectiveDocumentDate(),
      client: _buildClient(),
      sections: sections.toList(),
      titreDevis: titreDevis.value.trim().isEmpty ? null : titreDevis.value.trim(),
      noteNb: noteNb.value.trim().isEmpty ? null : noteNb.value.trim(),
      logoPath: logoPath.value.trim().isEmpty ? null : logoPath.value.trim(),
      nomEntreprise: nomEntreprise.value.trim().isEmpty ? null : nomEntreprise.value.trim(),
      telEntreprise: telEntreprise.value.trim().isEmpty ? null : telEntreprise.value.trim(),
      adresseEntreprise: adresseEntreprise.value.trim().isEmpty ? null : adresseEntreprise.value.trim(),
      deletedHistory: _encodeDeletedEntries(),
      useManualMainOeuvre: useManualMainOeuvre.value,
      manualMainOeuvre: manualMainOeuvre.value,
      status: _status,
      validUntil: _validUntil,
      sentAt: _sentAt,
      acceptedAt: _acceptedAt,
      refusedAt: _refusedAt,
      convertedAt: _convertedAt,
      convertedFactureId: _convertedFactureId,
      internalNotes: _internalNotes,
    );
  }

  String _resolveNumero() {
    return numero.value.trim().isEmpty
        ? Get.find<DevisController>().previewNextNumeroPro()
        : numero.value.trim();
  }

  bool _isPersistedDevis() {
    final id = editingDevisId;
    if (id == null || id.isEmpty) return false;
    return Get.find<DevisController>().getById(id) != null;
  }

  /// Vérifie les champs obligatoires avant enregistrement.
  String? validateForSave() {
    if (nomEntreprise.value.trim().isEmpty) {
      return 'Renseignez le nom de l\'entreprise (onglet Entreprise).';
    }
    if (!_hasClientInfo()) {
      return 'Renseignez au moins le nom du client.';
    }
    return null;
  }

  Future<String> _numeroForSave() async {
    if (_isPersistedDevis()) return _resolveNumero();
    final committed = await Get.find<DevisController>().commitNextNumeroPro();
    numero.value = committed;
    return committed;
  }

  /// Enregistre le devis et met à jour les paramètres entreprise. Retourne null si le devis est vide (aucune ligne).
  Future<Devis?> save() async {
    final hasAnyLine = sections.any((s) => s.items.isNotEmpty);
    if (!hasAnyLine) return null;

    final validationError = validateForSave();
    if (validationError != null) {
      Get.snackbar('Enregistrement impossible', validationError);
      return null;
    }

    final devis = _assembleDevis(
      id: editingDevisId ?? const Uuid().v4(),
      numeroVal: await _numeroForSave(),
    );

    await Get.find<DevisController>().saveDevis(devis);
    editingDevisId = devis.id;
    _clientId = devis.client?.id;

    // Mettre à jour les paramètres entreprise pour la prochaine fois
    final company = Get.find<CompanyController>();
    company.nom.value = nomEntreprise.value;
    company.telephone.value = telEntreprise.value;
    company.adresse.value = adresseEntreprise.value;
    company.logoPath.value = logoPath.value;
    await company.save();

    return devis;
  }

  /// Enregistre le document **directement comme facture**.
  ///
  /// Le devis sous‑jacent est conservé (statut `converti`) pour la traçabilité,
  /// puis converti immédiatement en `Facture` via [DevisController.convertToFacture].
  /// Pratique pour les ventes / prestations déjà réalisées où l'on n'a pas besoin
  /// d'étape d'envoi + acceptation.
  Future<Facture?> saveAsFacture({
    DateTime? dueDate,
    String paymentTerms = '',
  }) async {
    final hasAnyLine = sections.any((s) => s.items.isNotEmpty);
    if (!hasAnyLine) return null;

    final saved = await save();
    if (saved == null) return null;

    final devisCtrl = Get.find<DevisController>();
    final facture = await devisCtrl.convertToFacture(
      saved.id,
      dueDate: dueDate,
      paymentTerms: paymentTerms,
    );
    return facture;
  }

  double get total => sections.fold(0.0, (sum, s) => sum + s.totalSection);
  double get totalGeneral => total + (useManualMainOeuvre.value ? manualMainOeuvre.value : 0);

  /// Construit le devis actuel à partir du formulaire (pour aperçu PDF sans sauvegarde).
  Devis buildCurrentDevis() {
    return _assembleDevis(
      id: editingDevisId ?? const Uuid().v4(),
      numeroVal: _resolveNumero(),
    );
  }

  /// Sauvegarde automatique du devis dans l’historique (sans mettre à jour les paramètres entreprise).
  /// Ne fait rien si le devis ne contient aucune ligne (aucun enregistrement).
  Future<void> autoSave() async {
    final hasAnyLine = sections.any((s) => s.items.isNotEmpty);
    if (!hasAnyLine && editingDevisId == null) return;

    final id = editingDevisId ?? const Uuid().v4();
    final numeroVal = await _numeroForSave();
    final devis = _assembleDevis(id: id, numeroVal: numeroVal);
    await Get.find<DevisController>().saveDevis(devis);
    editingDevisId ??= devis.id;
    if (devis.client != null) _clientId = devis.client!.id;
  }

  void _pushDeletedEntry(DeletedEntry entry) {
    deletedEntries.insert(0, entry);
    if (deletedEntries.length > _maxDeletedEntries) {
      deletedEntries.removeRange(_maxDeletedEntries, deletedEntries.length);
    }
  }

  DevisItem _cloneItem(DevisItem i) => DevisItem(
        designation: i.designation,
        quantite: i.quantite,
        prixUnitaire: i.prixUnitaire,
        designationId: i.designationId,
        unite: i.unite,
      );

  SectionDevis _cloneSection(SectionDevis s) => SectionDevis(
        titre: s.titre,
        items: s.items.map(_cloneItem).toList(),
        mainOeuvrePercent: s.mainOeuvrePercent,
        mainOeuvreFixed: s.mainOeuvreFixed,
      );

  List<Map<String, dynamic>> _encodeDeletedEntries() {
    return deletedEntries.map((e) {
      if (e.type == DeletedEntryType.section) {
        return {
          'id': e.id,
          'type': 'section',
          'deletedAt': e.deletedAt.toIso8601String(),
          'sectionIndex': e.sectionIndex,
          'sectionTitle': e.sectionTitle,
          'sectionSnapshot': e.sectionSnapshot?.toJson(),
        };
      }
      return {
        'id': e.id,
        'type': 'item',
        'deletedAt': e.deletedAt.toIso8601String(),
        'sectionIndex': e.sectionIndex,
        'itemIndex': e.itemIndex,
        'sectionTitle': e.sectionTitle,
        'itemSnapshot': e.itemSnapshot?.toJson(),
      };
    }).toList();
  }

  List<DeletedEntry> _decodeDeletedEntries(List<Map<String, dynamic>> raw) {
    final out = <DeletedEntry>[];
    for (final entry in raw) {
      final type = entry['type'] as String?;
      final id = (entry['id'] as String?) ?? const Uuid().v4();
      final deletedAtRaw = entry['deletedAt'] as String?;
      final deletedAt = deletedAtRaw == null ? DateTime.now() : DateTime.tryParse(deletedAtRaw) ?? DateTime.now();
      final sectionIndex = (entry['sectionIndex'] as num?)?.toInt() ?? 0;
      final sectionTitle = (entry['sectionTitle'] as String?) ?? '';

      if (type == 'section') {
        final snapshotRaw = entry['sectionSnapshot'];
        if (snapshotRaw is! Map) continue;
        out.add(
          DeletedEntry.section(
            id: id,
            deletedAt: deletedAt,
            sectionIndex: sectionIndex,
            sectionTitle: sectionTitle,
            sectionSnapshot: SectionDevis.fromJson(Map<String, dynamic>.from(snapshotRaw)),
          ),
        );
        continue;
      }

      if (type == 'item') {
        final itemRaw = entry['itemSnapshot'];
        if (itemRaw is! Map) continue;
        out.add(
          DeletedEntry.item(
            id: id,
            deletedAt: deletedAt,
            sectionIndex: sectionIndex,
            itemIndex: (entry['itemIndex'] as num?)?.toInt(),
            sectionTitle: sectionTitle,
            itemSnapshot: DevisItem.fromJson(Map<String, dynamic>.from(itemRaw)),
          ),
        );
      }
    }
    return out;
  }
}
