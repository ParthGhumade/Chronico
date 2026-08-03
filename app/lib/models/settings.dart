import 'dart:convert';

class CustomField {
  final String id;
  final String name;
  final String value;

  CustomField({
    required this.id,
    required this.name,
    required this.value,
  });

  CustomField copyWith({
    String? id,
    String? name,
    String? value,
  }) {
    return CustomField(
      id: id ?? this.id,
      name: name ?? this.name,
      value: value ?? this.value,
    );
  }
}

class InstitutionalSettings {
  final String schoolName;
  final String address;
  final String principalName;
  final String defaultSignatory;
  final List<CustomField> customFields;

  InstitutionalSettings({
    required this.schoolName,
    required this.address,
    required this.principalName,
    required this.defaultSignatory,
    required this.customFields,
  });

  InstitutionalSettings copyWith({
    String? schoolName,
    String? address,
    String? principalName,
    String? defaultSignatory,
    List<CustomField>? customFields,
  }) {
    return InstitutionalSettings(
      schoolName: schoolName ?? this.schoolName,
      address: address ?? this.address,
      principalName: principalName ?? this.principalName,
      defaultSignatory: defaultSignatory ?? this.defaultSignatory,
      customFields: customFields ?? this.customFields,
    );
  }

  Map<String, String> toPresetsMap() {
    final customFieldsJson = jsonEncode(
      customFields.map((f) => {'id': f.id, 'name': f.name, 'value': f.value}).toList(),
    );
    return {
      'school_name': schoolName,
      'address': address,
      'principal_name': principalName,
      'default_signatory': defaultSignatory,
      'custom_fields': customFieldsJson,
    };
  }

  factory InstitutionalSettings.fromPresetsMap(Map<String, String> presets) {
    List<CustomField> custom = [];
    if (presets.containsKey('custom_fields') && presets['custom_fields']!.isNotEmpty) {
      try {
        final List parsed = jsonDecode(presets['custom_fields']!);
        custom = parsed.map((item) => CustomField(
          id: item['id']?.toString() ?? '',
          name: item['name']?.toString() ?? '',
          value: item['value']?.toString() ?? '',
        )).toList();
      } catch (_) {}
    }

    return InstitutionalSettings(
      schoolName: presets['school_name'] ?? 'Springfield Elementary School',
      address: presets['address'] ?? '742 Evergreen Terrace, Springfield, State, 12345',
      principalName: presets['principal_name'] ?? 'Seymour Skinner',
      defaultSignatory: presets['default_signatory'] ?? 'Gary Chalmers',
      customFields: custom.isNotEmpty
          ? custom
          : [
              CustomField(id: '1', name: 'U-DISE Code', value: '27210509902'),
              CustomField(id: '2', name: 'Affiliation No.', value: 'CBSE-110482'),
            ],
    );
  }
}

