import 'dart:async';
import 'dart:html' as html;

Future<String?> pickImageFile() async {
  final input = html.FileUploadInputElement();
  input.accept = 'image/*';
  input.multiple = false;
  input.click();
  await input.onChange.first;
  if (input.files == null || input.files!.isEmpty) return null;
  final file = input.files!.first;
  final reader = html.FileReader();
  reader.readAsDataUrl(file);
  await reader.onLoad.first;
  return reader.result as String?;
}
