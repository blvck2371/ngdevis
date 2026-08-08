import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Dernière page PDF : contrat générique enrichi + espaces de signature.
/// Design soft. Caractères compatibles Helvetica (Latin-1).
class PdfContractPage {
  static const PdfColor _ink = PdfColor.fromInt(0xFF3D4450);
  static const PdfColor _inkSoft = PdfColor.fromInt(0xFF6B7280);
  static const PdfColor _muted = PdfColor.fromInt(0xFF9AA3AF);
  static const PdfColor _line = PdfColor.fromInt(0xFFE8EBF0);
  static const PdfColor _wash = PdfColor.fromInt(0xFFF7F8FA);
  static const PdfColor _accent = PdfColor.fromInt(0xFF8B9BB4);
  static const PdfColor _accentSoft = PdfColor.fromInt(0xFFEEF2F7);

  /// Widgets à placer en fin de document (MultiPage-safe).
  static List<pw.Widget> buildWidgets({
    required String documentLabel,
    required String numero,
    required DateTime date,
    required String companyName,
    required String companyAdresse,
    required String companyTel,
    required String clientNom,
    required String clientSociete,
    required String clientAdresse,
    required String clientTel,
    String? objet,
    required String totalLabel,
    DateTime? validUntil,
  }) {
    final entreprise = _pdfSafe(
      companyName.trim().isEmpty
          ? "l'Entreprise prestataire"
          : companyName.trim(),
    );
    final client = _pdfSafe(_clientDisplay(clientNom, clientSociete));
    final dateStr = _formatDateFr(date);
    final validStr =
        validUntil != null ? _formatDateFr(validUntil) : null;
    final rawObjet = (objet ?? '').trim();
    final objetText = _pdfSafe(
      rawObjet.isEmpty
          ? 'les prestations, fournitures, services et/ou travaux décrits '
              'dans le $documentLabel N° $numero'
          : rawObjet,
    );
    final safeTotal = _pdfSafe(totalLabel);
    final safeNumero = _pdfSafe(numero);
    final safeLabel = _pdfSafe(documentLabel);

    return [
      _header(
        documentLabel: safeLabel,
        numero: safeNumero,
        dateStr: dateStr,
      ),
      pw.SizedBox(height: 12),
      _intro(
        entreprise: entreprise,
        client: client,
        documentLabel: safeLabel,
        numero: safeNumero,
        dateStr: dateStr,
      ),
      pw.SizedBox(height: 12),
      _partiesBlock(
        entreprise: entreprise,
        companyAdresse: _pdfSafe(companyAdresse),
        companyTel: _pdfSafe(companyTel),
        client: client,
        clientAdresse: _pdfSafe(clientAdresse),
        clientTel: _pdfSafe(clientTel),
      ),
      pw.SizedBox(height: 14),
      ..._articles(
        documentLabel: safeLabel,
        numero: safeNumero,
        entreprise: entreprise,
        client: client,
        objetText: objetText,
        totalLabel: safeTotal,
        validStr: validStr,
        dateStr: dateStr,
      ),
      pw.SizedBox(height: 16),
      pw.Center(
        child: pw.RichText(
          text: pw.TextSpan(
            children: [
              pw.TextSpan(
                text: 'Fait en deux exemplaires originaux, ',
                style: _body(italic: true, color: _muted),
              ),
              pw.TextSpan(
                text: 'le $dateStr',
                style: _body(italic: true, bold: true, color: _inkSoft),
              ),
              pw.TextSpan(
                text: '.',
                style: _body(italic: true, color: _muted),
              ),
            ],
          ),
        ),
      ),
      pw.SizedBox(height: 12),
      _signatureBlock(entreprise: entreprise, client: client),
    ];
  }

  static pw.Widget _header({
    required String documentLabel,
    required String numero,
    required String dateStr,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: pw.BoxDecoration(
        color: _wash,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        children: [
          pw.Text(
            "Contrat d'acceptation et conditions générales",
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(
              fontSize: 13.5,
              fontWeight: pw.FontWeight.bold,
              color: _ink,
              letterSpacing: 0.2,
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Container(width: 36, height: 1.4, color: _accent),
          pw.SizedBox(height: 7),
          pw.RichText(
            textAlign: pw.TextAlign.center,
            text: pw.TextSpan(
              children: [
                pw.TextSpan(
                  text: documentLabel,
                  style: _body(bold: true, color: _ink),
                ),
                pw.TextSpan(text: ' N° ', style: _body(color: _inkSoft)),
                pw.TextSpan(
                  text: numero,
                  style: _body(bold: true, color: _ink),
                ),
                pw.TextSpan(text: '   |   ', style: _body(color: _muted)),
                pw.TextSpan(
                  text: dateStr,
                  style: _body(bold: true, color: _inkSoft),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _intro({
    required String entreprise,
    required String client,
    required String documentLabel,
    required String numero,
    required String dateStr,
  }) {
    return pw.RichText(
      textAlign: pw.TextAlign.justify,
      text: pw.TextSpan(
        children: [
          pw.TextSpan(
            text:
                'Entre les soussignés, il a été convenu et arrêté le présent contrat '
                'd\'acceptation, destiné à formaliser de manière claire, complète et '
                'opposable l\'accord intervenu entre ',
            style: _body(),
          ),
          pw.TextSpan(text: entreprise, style: _body(bold: true)),
          pw.TextSpan(text: ' et ', style: _body()),
          pw.TextSpan(text: client, style: _body(bold: true)),
          pw.TextSpan(
            text:
                ', sur la base du $documentLabel N° ',
            style: _body(),
          ),
          pw.TextSpan(text: numero, style: _body(bold: true)),
          pw.TextSpan(text: ' en date du ', style: _body()),
          pw.TextSpan(text: dateStr, style: _body(bold: true)),
          pw.TextSpan(
            text:
                '. Ce contrat s\'applique indifféremment aux prestations de services, '
                'fournitures, livraisons, travaux, études, locations ou interventions '
                'mixtes décrites dans le document annexé.',
            style: _body(),
          ),
        ],
      ),
    );
  }

  static pw.Widget _partiesBlock({
    required String entreprise,
    required String companyAdresse,
    required String companyTel,
    required String client,
    required String clientAdresse,
    required String clientTel,
  }) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: _partyCard(
            title: 'L\'ENTREPRISE',
            name: entreprise,
            adresse: companyAdresse,
            tel: companyTel,
          ),
        ),
        pw.SizedBox(width: 10),
        pw.Expanded(
          child: _partyCard(
            title: 'LE CLIENT',
            name: client,
            adresse: clientAdresse,
            tel: clientTel,
          ),
        ),
      ],
    );
  }

  static pw.Widget _partyCard({
    required String title,
    required String name,
    required String adresse,
    required String tel,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.fromLTRB(11, 9, 11, 10),
      decoration: pw.BoxDecoration(
        color: _accentSoft,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 7.5,
              fontWeight: pw.FontWeight.bold,
              color: _accent,
              letterSpacing: 0.7,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            name,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: _ink,
            ),
          ),
          if (adresse.trim().isNotEmpty) ...[
            pw.SizedBox(height: 3),
            pw.Text(
              adresse.trim(),
              style: pw.TextStyle(fontSize: 8, color: _inkSoft, height: 1.25),
            ),
          ],
          if (tel.trim().isNotEmpty) ...[
            pw.SizedBox(height: 2),
            pw.RichText(
              text: pw.TextSpan(
                children: [
                  pw.TextSpan(text: 'Tél. ', style: _body(bold: true, size: 8)),
                  pw.TextSpan(
                    text: tel.trim(),
                    style: _body(size: 8, color: _inkSoft),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  static List<pw.Widget> _articles({
    required String documentLabel,
    required String numero,
    required String entreprise,
    required String client,
    required String objetText,
    required String totalLabel,
    String? validStr,
    required String dateStr,
  }) {
    final items = <_Article>[
      _Article(
        'Article 1 - Objet du contrat',
        [
          _Seg('Le présent contrat a pour objet de définir les conditions '
              'dans lesquelles '),
          _Seg(entreprise, bold: true),
          _Seg(' (ci-après "l\'Entreprise") s\'engage envers '),
          _Seg(client, bold: true),
          _Seg(' (ci-après "le Client") à réaliser, fournir ou exécuter '),
          _Seg(objetText, bold: true),
          _Seg(', tels que détaillés dans le '),
          _Seg(documentLabel, bold: true),
          _Seg(' N° '),
          _Seg(numero, bold: true),
          _Seg(', lequel constitue l\'annexe technique et financière '
              'indissociable du présent contrat.'),
        ],
      ),
      _Article(
        'Article 2 - Documents contractuels et priorité',
        [
          _Seg('Les documents suivants forment le contrat, par ordre '
              'décroissant de priorité : (1) le présent contrat d\'acceptation ; '
              '(2) le '),
          _Seg(documentLabel, bold: true),
          _Seg(' N° '),
          _Seg(numero, bold: true),
          _Seg(' et ses annexes (désignations, quantités, unités, prix '
              'unitaires, totaux, notes) ; (3) tout avenant, ordre de service '
              'ou devis complémentaire signé par les deux parties. '
              'En cas de contradiction, le document de rang supérieur prévaut. '
              'Les échanges oraux n\'ont de valeur que s\'ils sont confirmés '
              'par écrit.'),
        ],
      ),
      _Article(
        'Article 3 - Acceptation de l\'offre',
        [
          _Seg('En signant le présent contrat, '),
          _Seg(client, bold: true),
          _Seg(' déclare avoir pris connaissance de l\'intégralité du '),
          _Seg(documentLabel, bold: true),
          _Seg(' N° '),
          _Seg(numero, bold: true),
          _Seg(' et l\'accepter sans réserve, y compris les prix, quantités, '
              'unités, conditions particulières et notes y figurant'
              '${validStr != null ? '. L\'offre demeure valable jusqu\'au ' : '. '}'),
          if (validStr != null) _Seg(validStr, bold: true),
          if (validStr != null) _Seg('.'),
          _Seg(' Toute réserve doit être formulée par écrit avant signature ; '
              'à défaut, elle est réputée absente.'),
        ],
      ),
      _Article(
        'Article 4 - Prix, taxes et révision',
        [
          _Seg('Le montant total convenu s\'élève à '),
          _Seg(totalLabel, bold: true),
          _Seg(', sauf mention contraire expressément portée sur le '),
          _Seg(documentLabel, bold: true),
          _Seg('. Ce montant couvre les éléments clairement décrits au '
              'document annexé. Toute prestation supplémentaire, variation '
              'de quantité, modification de spécification ou contrainte '
              'nouvelle non prévue initialement donnera lieu à un avenant '
              'ou un devis complémentaire accepté par écrit avant exécution. '
              'Les prix sont fermes pour la durée de validité de l\'offre, '
              'sauf clause de révision écrite.'),
        ],
      ),
      _Article(
        'Article 5 - Modalités de paiement',
        [
          _Seg(client, bold: true),
          _Seg(' s\'engage à régler le montant dû selon les échéances et '
              'modalités indiquées sur le document ou convenues par écrit '
              '(acompte, situations, solde, virement, espèces, mobile money '
              'ou tout autre moyen accepté). En cas de retard de paiement, '
              ),
          _Seg(entreprise, bold: true),
          _Seg(' pourra, après information écrite, suspendre l\'exécution, '
              'retenir les livrables et appliquer les pénalités et frais '
              'd\'usage, sans préjudice de toute autre voie de droit. '
              'Le paiement partiel n\'emporte ni novation ni renonciation.'),
        ],
      ),
      _Article(
        'Article 6 - Exécution, délais et obligations des parties',
        [
          _Seg(entreprise, bold: true),
          _Seg(' s\'engage à exécuter les prestations avec diligence, '
              'compétence et selon les règles de l\'art applicables au '
              'domaine concerné. Les délais mentionnés sont indicatifs '
              'sauf délai ferme expressément écrit. Ils pourront être '
              'prolongés en cas de force majeure, d\'aléa technique '
              'imprévisible, ou de retard imputable au Client '
              '(accès, décisions, fournitures, autorisations, paiements). '),
          _Seg(client, bold: true),
          _Seg(' s\'engage à fournir en temps utile toutes informations, '
              'accès, documents et validations nécessaires à la bonne '
              'exécution.'),
        ],
      ),
      _Article(
        'Article 7 - Modifications en cours d\'exécution',
        [
          _Seg('Toute demande de modification portant sur l\'objet, les '
              'quantités, les délais, les spécifications techniques ou les '
              'prix devra être formulée par écrit. '),
          _Seg(entreprise, bold: true),
          _Seg(' adressera alors une proposition d\'avenant indiquant '
              'l\'impact éventuel sur le coût et le planning. Aucune '
              'modification n\'est opposable tant qu\'elle n\'a pas été '
              'acceptée par écrit par les deux parties.'),
        ],
      ),
      _Article(
        'Article 8 - Réception, réserves et garanties',
        [
          _Seg('À l\'achèvement ou à la livraison, '),
          _Seg(client, bold: true),
          _Seg(' dispose d\'un délai raisonnable pour vérifier la conformité '
              'et formuler ses réserves motivées par écrit. Passé ce délai '
              'sans réserve, les prestations sont réputées acceptées. '
              'Les réserves n\'autorisent pas à différer le paiement des '
              'parties non contestées. Les garanties légales applicables '
              'aux fournitures et travaux demeurent dues lorsqu\'elles '
              's\'imposent. '),
          _Seg(entreprise, bold: true),
          _Seg(' s\'engage à remédier dans un délai raisonnable aux défauts '
              'qui lui sont imputables et dûment constatés.'),
        ],
      ),
      _Article(
        'Article 9 - Responsabilité et limitation',
        [
          _Seg('La responsabilité de '),
          _Seg(entreprise, bold: true),
          _Seg(' est engagée uniquement en cas de faute prouvée dans '
              'l\'exécution de sa mission. Sauf dol ou faute lourde, cette '
              'responsabilité est limitée au montant total du présent contrat '
              '('),
          _Seg(totalLabel, bold: true),
          _Seg('). Aucune partie ne pourra être tenue des dommages indirects, '
              'perte d\'exploitation, manque à gagner ou préjudice d\'image, '
              'sauf disposition légale impérative contraire.'),
        ],
      ),
      _Article(
        'Article 10 - Résiliation',
        [
          _Seg('En cas de manquement grave d\'une partie à ses obligations, '
              'non réparé dans un délai de quinze (15) jours suivant mise '
              'en demeure écrite, l\'autre partie pourra résilier le contrat '
              'de plein droit. En cas de résiliation, les sommes dues au '
              'titre des prestations déjà réalisées, fournitures livrées ou '
              'frais engagés avec l\'accord du Client restent immédiatement '
              'exigibles. La résiliation ne prive pas les parties de leurs '
              'droits à dommages et intérêts.'),
        ],
      ),
      _Article(
        'Article 11 - Confidentialité et propriété',
        [
          _Seg('Chaque partie s\'engage à conserver confidentielles les '
              'informations techniques, commerciales et financières reçues '
              'à l\'occasion du contrat, sauf obligation légale ou accord '
              'écrit. Les documents, plans, études et livrables fournis par '),
          _Seg(entreprise, bold: true),
          _Seg(' demeurent sa propriété intellectuelle jusqu\'au paiement '
              'intégral, sauf convention contraire écrite. Après paiement '
              'complet, le Client obtient les droits d\'usage nécessaires '
              'à l\'utilisation prévue des livrables.'),
        ],
      ),
      _Article(
        'Article 12 - Droit applicable et litiges',
        [
          _Seg('Le présent contrat est régi par le droit applicable au lieu '
              'd\'exécution des prestations. Les parties s\'efforceront de '
              'régler tout différend à l\'amiable. À défaut d\'accord dans '
              'un délai raisonnable, le litige sera porté devant les '
              'juridictions compétentes de ce lieu. '
              'En signant ci-dessous, '),
          _Seg(client, bold: true),
          _Seg(' et '),
          _Seg(entreprise, bold: true),
          _Seg(' reconnaissent avoir lu, compris et accepté l\'ensemble des '
              'clauses du présent contrat ainsi que le '),
          _Seg(documentLabel, bold: true),
          _Seg(' N° '),
          _Seg(numero, bold: true),
          _Seg(' en date du '),
          _Seg(dateStr, bold: true),
          _Seg('.'),
        ],
      ),
    ];

    return [
      for (final article in items) ...[
        pw.SizedBox(height: 8),
        pw.Text(
          article.title,
          style: pw.TextStyle(
            fontSize: 9.2,
            fontWeight: pw.FontWeight.bold,
            color: _ink,
          ),
        ),
        pw.SizedBox(height: 3),
        pw.RichText(
          textAlign: pw.TextAlign.justify,
          text: pw.TextSpan(
            children: [
              for (final seg in article.segments)
                pw.TextSpan(
                  text: seg.text,
                  style: _body(bold: seg.bold, size: 8),
                ),
            ],
          ),
        ),
      ],
    ];
  }

  static pw.Widget _signatureBlock({
    required String entreprise,
    required String client,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.fromLTRB(12, 11, 12, 10),
      decoration: pw.BoxDecoration(
        color: _wash,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pw.Text(
            'Signatures des parties',
            textAlign: pw.TextAlign.center,
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: _inkSoft,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: _signatureBox(
                  role: 'Pour le Client',
                  name: client,
                  hint: 'Lu et approuvé - Signature',
                ),
              ),
              pw.SizedBox(width: 14),
              pw.Container(width: 1, height: 112, color: _line),
              pw.SizedBox(width: 14),
              pw.Expanded(
                child: _signatureBox(
                  role: "Pour l'Entreprise",
                  name: entreprise,
                  hint: 'Signature et cachet',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _signatureBox({
    required String role,
    required String name,
    required String hint,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Text(
          role,
          style: pw.TextStyle(
            fontSize: 9,
            fontWeight: pw.FontWeight.bold,
            color: _inkSoft,
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          name,
          style: pw.TextStyle(
            fontSize: 8.5,
            fontWeight: pw.FontWeight.bold,
            color: _ink,
          ),
          maxLines: 2,
        ),
        pw.SizedBox(height: 7),
        pw.Container(
          height: 58,
          decoration: pw.BoxDecoration(
            color: PdfColors.white,
            borderRadius: pw.BorderRadius.circular(6),
            border: pw.Border.all(color: _line, width: 0.8),
          ),
          alignment: pw.Alignment.bottomCenter,
          padding: const pw.EdgeInsets.only(bottom: 6),
          child: pw.Text(
            hint,
            style: pw.TextStyle(
              fontSize: 7,
              color: _muted,
              fontStyle: pw.FontStyle.italic,
            ),
          ),
        ),
        pw.SizedBox(height: 7),
        pw.Text(
          'Nom : ................................',
          style: pw.TextStyle(fontSize: 7.5, color: _muted),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          'Date : .... / .... / ........',
          style: pw.TextStyle(fontSize: 7.5, color: _muted),
        ),
      ],
    );
  }

  static pw.TextStyle _body({
    bool bold = false,
    bool italic = false,
    double size = 8.2,
    PdfColor? color,
  }) {
    return pw.TextStyle(
      fontSize: size,
      fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
      fontStyle: italic ? pw.FontStyle.italic : pw.FontStyle.normal,
      color: color ?? _ink,
      height: 1.32,
    );
  }

  static String _clientDisplay(String nom, String societe) {
    final n = nom.trim();
    final s = societe.trim();
    if (n.isNotEmpty && s.isNotEmpty) return '$n ($s)';
    if (n.isNotEmpty) return n;
    if (s.isNotEmpty) return s;
    return 'le Client';
  }

  static String _pdfSafe(String input) {
    return input
        .replaceAll('’', "'")
        .replaceAll('‘', "'")
        .replaceAll('“', '"')
        .replaceAll('”', '"')
        .replaceAll('–', '-')
        .replaceAll('—', '-')
        .replaceAll('…', '...')
        .replaceAll('·', '|')
        .replaceAll('«', '"')
        .replaceAll('»', '"')
        .replaceAll('€', 'EUR')
        .replaceAllMapped(
          RegExp(r'[^\x09\x0A\x0D\x20-\x7E\xA0-\xFF]'),
          (_) => '',
        );
  }

  static String _formatDateFr(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}

class _Article {
  final String title;
  final List<_Seg> segments;
  const _Article(this.title, this.segments);
}

class _Seg {
  final String text;
  final bool bold;
  const _Seg(this.text, {this.bold = false});
}
