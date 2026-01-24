// Web-only implementation
import 'dart:html' as html;

class WebStorage {
  Future<void> saveTours(String json) async {
    try {
      html.window.localStorage['walking_tours'] = json;
    } catch (_) {}
  }

  String? loadTours() {
    try {
      return html.window.localStorage['walking_tours'];
    } catch (_) {
      return null;
    }
  }

  void downloadTours(String json, String filename) {
    try {
      final blob = html.Blob([json], 'application/json');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..download = filename
        ..click();
      html.Url.revokeObjectUrl(url);
    } catch (_) {}
  }
}
