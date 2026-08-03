import 'package:flutter/material.dart';
import '../models/settings.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  final AppState appState;

  const SettingsScreen({
    super.key,
    required this.appState,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _schoolNameController;
  late TextEditingController _addressController;
  late TextEditingController _principalController;
  late TextEditingController _signatoryController;

  @override
  void initState() {
    super.initState();
    final s = widget.appState.settings;
    _schoolNameController = TextEditingController(text: s.schoolName);
    _addressController = TextEditingController(text: s.address);
    _principalController = TextEditingController(text: s.principalName);
    _signatoryController = TextEditingController(text: s.defaultSignatory);
  }

  @override
  void dispose() {
    _schoolNameController.dispose();
    _addressController.dispose();
    _principalController.dispose();
    _signatoryController.dispose();
    super.dispose();
  }

  void _saveSettings() {
    widget.appState.updateSettings(
      schoolName: _schoolNameController.text.trim(),
      address: _addressController.text.trim(),
      principalName: _principalController.text.trim(),
      defaultSignatory: _signatoryController.text.trim(),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Institutional Settings updated successfully!'),
        backgroundColor: ChronicoColors.primaryContainer,
      ),
    );
  }

  void _showAddCustomFieldDialog() {
    final nameCtrl = TextEditingController();
    final valCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ChronicoColors.surfaceContainerHigh,
        title: const Text('Add Custom Institutional Field', style: TextStyle(color: ChronicoColors.onSurface)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              style: const TextStyle(color: ChronicoColors.onSurface),
              decoration: const InputDecoration(
                labelText: 'Field Name',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: valCtrl,
              style: const TextStyle(color: ChronicoColors.onSurface),
              decoration: const InputDecoration(
                labelText: 'Field Value',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.trim().isNotEmpty) {
                widget.appState.addCustomField(nameCtrl.text.trim(), valCtrl.text.trim());
              }
              Navigator.pop(ctx);
            },
            child: const Text('Add Field'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteCustomField(BuildContext context, CustomField field) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ChronicoColors.surfaceContainerHigh,
        title: const Text('Delete Custom Field', style: TextStyle(color: ChronicoColors.onSurface)),
        content: Text(
          'Are you sure you want to delete the custom field "${field.name}"?',
          style: const TextStyle(color: ChronicoColors.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: ChronicoColors.error,
              foregroundColor: Colors.black,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              widget.appState.removeCustomField(field.id);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Custom field deleted.')),
              );
            },
            child: const Text('Delete', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 768;
    final settings = widget.appState.settings;

    return Scaffold(
      backgroundColor: ChronicoColors.background,
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isDesktop ? 32 : 16,
          vertical: 24,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Institutional Settings',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: ChronicoColors.onSurface,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Configure institution profile, header metadata, and official signatures for report generation.',
                  style: TextStyle(fontSize: 14, color: ChronicoColors.onSurfaceVariant),
                ),
                const SizedBox(height: 24),

                // Main Form Card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: ChronicoColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: ChronicoColors.outlineVariant),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // School Name
                      const Text(
                        'Institution / School Name',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: ChronicoColors.onSurfaceVariant),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _schoolNameController,
                        style: const TextStyle(color: ChronicoColors.onSurface, fontSize: 16),
                        decoration: const InputDecoration(
                          hintText: 'e.g., Springfield Elementary School',
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Registered Address
                      const Text(
                        'Registered Address',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: ChronicoColors.onSurfaceVariant),
                      ),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _addressController,
                        maxLines: 3,
                        style: const TextStyle(color: ChronicoColors.onSurface, fontSize: 16),
                        decoration: const InputDecoration(
                          hintText: 'Full institutional address...',
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Principal & Signatory Row
                      LayoutBuilder(
                        builder: (ctx, constraints) {
                          if (constraints.maxWidth >= 600) {
                            return Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Principal / Headmaster',
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: ChronicoColors.onSurfaceVariant),
                                      ),
                                      const SizedBox(height: 6),
                                      TextField(
                                        controller: _principalController,
                                        style: const TextStyle(color: ChronicoColors.onSurface, fontSize: 16),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Default Signatory / Superintendent',
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: ChronicoColors.onSurfaceVariant),
                                      ),
                                      const SizedBox(height: 6),
                                      TextField(
                                        controller: _signatoryController,
                                        style: const TextStyle(color: ChronicoColors.onSurface, fontSize: 16),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          } else {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Principal / Headmaster',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: ChronicoColors.onSurfaceVariant),
                                ),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: _principalController,
                                  style: const TextStyle(color: ChronicoColors.onSurface, fontSize: 16),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Default Signatory / Superintendent',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: ChronicoColors.onSurfaceVariant),
                                ),
                                const SizedBox(height: 6),
                                TextField(
                                  controller: _signatoryController,
                                  style: const TextStyle(color: ChronicoColors.onSurface, fontSize: 16),
                                ),
                              ],
                            );
                          }
                        },
                      ),

                      const SizedBox(height: 28),

                      // Custom Fields Manager Section
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Text(
                              'Custom Fields',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: ChronicoColors.onSurface,
                              ),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _showAddCustomFieldDialog,
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Add Field'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      if (settings.customFields.isEmpty)
                        const Text(
                          'No custom metadata fields added yet.',
                          style: TextStyle(fontSize: 13, color: ChronicoColors.onSurfaceVariant),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: settings.customFields.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (ctx, index) {
                            final field = settings.customFields[index];
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: ChronicoColors.surfaceContainerHigh,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: ChronicoColors.outlineVariant),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      field.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: ChronicoColors.onSurface,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      field.value,
                                      style: const TextStyle(
                                        color: ChronicoColors.primary,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 18, color: ChronicoColors.error),
                                    onPressed: () => _confirmDeleteCustomField(context, field),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Save Action Button
                Align(
                  alignment: Alignment.centerRight,
                  child: SizedBox(
                    width: isDesktop ? 220 : double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _saveSettings,
                      icon: const Icon(Icons.save),
                      label: const Text('Save Settings'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ChronicoColors.primaryContainer,
                        foregroundColor: ChronicoColors.onPrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
