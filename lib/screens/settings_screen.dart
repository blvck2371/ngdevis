import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../core/controllers/company_controller.dart';
import '../core/utils/app_routes.dart';
import '../core/utils/responsive.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<CompanyController>();
    final r = context.responsive;
    return Scaffold(
      appBar: AppBar(title: const Text('Paramètres entreprise')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            r.horizontalPadding,
            16,
            r.horizontalPadding,
            24 + MediaQuery.of(context).padding.bottom,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: r.maxContentWidth),
            child: Obx(() => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Logo',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (c.logoPath.value.isNotEmpty && File(c.logoPath.value).existsSync())
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(c.logoPath.value),
                          width: 88,
                          height: 88,
                          fit: BoxFit.cover,
                        ),
                      )
                    else
                      Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.image, size: 40),
                      ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          FilledButton.icon(
                            onPressed: () async {
                              final picker = await ImagePicker().pickImage(source: ImageSource.gallery);
                              if (picker != null) {
                                c.setLogo(picker.path);
                                await c.save();
                              }
                            },
                            icon: const Icon(Icons.photo_library),
                            label: const Text('Choisir un logo'),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Le logo apparaîtra en tête de vos devis PDF.',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: r.sectionSpacing),
                Text(
                  'Coordonnées',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: c.nom.value,
                  decoration: const InputDecoration(
                    labelText: 'Nom entreprise',
                    hintText: 'Votre raison sociale',
                  ),
                  onChanged: (v) => c.nom.value = v,
                  onFieldSubmitted: (_) => c.save(),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: c.telephone.value,
                  decoration: const InputDecoration(
                    labelText: 'Téléphone',
                    hintText: 'Ex: 698 87 93 76',
                  ),
                  keyboardType: TextInputType.phone,
                  onChanged: (v) => c.telephone.value = v,
                  onFieldSubmitted: (_) => c.save(),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: c.adresse.value,
                  decoration: const InputDecoration(
                    labelText: 'Adresse',
                    hintText: 'Adresse de l\'entreprise',
                  ),
                  maxLines: 2,
                  onChanged: (v) => c.adresse.value = v,
                  onFieldSubmitted: (_) => c.save(),
                ),
                SizedBox(height: r.sectionSpacing),
                FilledButton.icon(
                  onPressed: () async {
                    Get.dialog(
                      const Center(
                        child: Card(
                          child: Padding(
                            padding: EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(),
                                SizedBox(height: 16),
                                Text('Enregistrement...'),
                              ],
                            ),
                          ),
                        ),
                      ),
                      barrierDismissible: false,
                    );
                    await c.save();
                    if (Get.isDialogOpen ?? false) Get.back();
                    Get.offNamedUntil(AppRoutes.dashboard, (route) => false);
                    Get.snackbar(
                      'Succès',
                      'Enregistrement effectué',
                      snackPosition: SnackPosition.BOTTOM,
                      margin: const EdgeInsets.all(16),
                      duration: const Duration(seconds: 2),
                    );
                  },
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Enregistrer les paramètres'),
                ),
              ],
            )),
          ),
        ),
      ),
    );
  }
}
