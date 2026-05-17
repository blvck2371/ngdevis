import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../core/controllers/company_controller.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/logo_file_helper.dart';
import '../core/utils/app_routes.dart';
import '../core/utils/responsive.dart';
import '../core/widgets/app_bottom_nav.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<CompanyController>();
    final r = context.responsive;
    final bottomNavSpace = 92.0 + MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        title: const Text('Paramètres entreprise'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            r.horizontalPadding,
            16,
            r.horizontalPadding,
            24 + bottomNavSpace,
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
                                final path = await LogoFileHelper.persistPickerImage(picker);
                                c.setLogo(path);
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
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: c.slogan.value,
                  decoration: const InputDecoration(
                    labelText: 'Slogan (PDF, sous le logo)',
                    hintText: 'Optionnel — une ligne sous le nom / logo sur le devis',
                  ),
                  onChanged: (v) => c.slogan.value = v,
                  onFieldSubmitted: (_) => c.save(),
                ),
                SizedBox(height: r.sectionSpacing),
                Text(
                  'Documents',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                _SettingsTile(
                  icon: Icons.tag_rounded,
                  title: 'Numérotation',
                  subtitle: 'Préfixe, année, reset annuel, padding',
                  onTap: () => Get.toNamed(AppRoutes.numbering),
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
      bottomNavigationBar: const AppBottomNav(active: AppTab.settings),
    );
  }
}

/// Tuile cliquable réutilisable dans les sections de réglages.
class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = AppColors.of(context);
    return Material(
      color: p.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: p.outlineSoft, width: 0.7),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: p.accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(icon, color: p.accent, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 1),
                    Text(
                      subtitle,
                      style: TextStyle(color: p.inkMuted, fontSize: 12.5),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: p.inkMuted),
            ],
          ),
        ),
      ),
    );
  }
}
