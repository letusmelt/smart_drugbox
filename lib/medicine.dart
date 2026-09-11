import 'dart:typed_data';

class Medicine {
  String name, dose, frequency, method, specification, sourceText, warnings;
  Uint8List? photo;
  Medicine(
    this.name,
    this.dose,
    this.frequency,
    this.method, {
    this.specification = '待确认',
    this.sourceText = '',
    this.warnings = '',
    this.photo,
  });
  Medicine copy() => Medicine(
    name,
    dose,
    frequency,
    method,
    specification: specification,
    sourceText: sourceText,
    warnings: warnings,
    photo: photo,
  );
}
