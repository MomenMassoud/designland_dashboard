import 'dart:convert';
import 'package:appflowy_editor/appflowy_editor.dart';
import 'package:flutter/foundation.dart';

class AppFlowyHelper {
  static Map<String, dynamic>? normalizeAppFlowyJson(dynamic value) {
    if (value is! Map) return null;

    dynamic current = value;
    int safetyCounter = 0;

    while (current is Map && safetyCounter < 20) {
      safetyCounter++;
      final map = Map<String, dynamic>.from(current);

      if (map['type'] == 'page') {
        return {'document': map};
      }

      if (map.containsKey('document')) {
        final nested = map['document'];

        if (nested is Map) {
          current = nested;
          continue;
        }

        if (nested is String) {
          try {
            current = jsonDecode(nested);
            continue;
          } catch (_) {
            return null;
          }
        }
      }
      return null;
    }
    return null;
  }

  static Document createDocumentFromString(String text) {
    return Document(
      root: pageNode(
        children: [
          paragraphNode(text: text),
        ],
      ),
    );
  }

  static Document getAppFlowyDocument(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return createDocumentFromString('');
    }

    try {
      dynamic parsed = jsonDecode(trimmed);
      while (parsed is String) {
        final inner = parsed.trim();
        if (inner.isEmpty) break;
        parsed = jsonDecode(inner);
      }

      final normalized = normalizeAppFlowyJson(parsed);
      if (normalized != null) {
        return Document.fromJson(normalized);
      }
    } catch (e, stackTrace) {
      debugPrint("Error parsing AppFlowy document: $e");
      debugPrint(stackTrace.toString());
    }

    return createDocumentFromString(text);
  }
}