import 'dart:convert';
import 'dart:io';

class TrigramPosting {
  final int pageId;
  final int slotId;

  const TrigramPosting(this.pageId, this.slotId);

  Map<String, dynamic> toJson() => {'p': pageId, 's': slotId};

  factory TrigramPosting.fromJson(Map<String, dynamic> json) =>
      TrigramPosting(json['p'] as int, json['s'] as int);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrigramPosting &&
          runtimeType == other.runtimeType &&
          pageId == other.pageId &&
          slotId == other.slotId;

  @override
  int get hashCode => pageId.hashCode ^ slotId.hashCode;
}

/// Inverted Trigram (3-gram) Index for Substring and Wildcard Matching (LIKE '%query%')
class TrigramIndex {
  final String indexPath;
  final bool autoSave;
  final Map<String, List<TrigramPosting>> index = {};
  static final Map<String, Map<String, List<TrigramPosting>>> _memoryRegistry =
      {};

  TrigramIndex({required this.indexPath, this.autoSave = true});

  /// Extracts all 3-character n-grams from the given text
  static Set<String> extractTrigrams(String text) {
    if (text.isEmpty) return {};
    final lower = text.toLowerCase();
    // Standard trigram padding: two spaces prefix, one space suffix
    final padded = '  $lower ';
    final trigrams = <String>{};
    for (int i = 0; i <= padded.length - 3; i++) {
      trigrams.add(padded.substring(i, i + 3));
    }
    return trigrams;
  }

  /// Extracts trigrams for query patterns without wildcards (%)
  static Set<String> extractQueryTrigrams(String pattern) {
    final lower = pattern.toLowerCase();
    // Split by wildcards to find contiguous literal substrings
    final segments = lower.split(RegExp(r'[%_]')).where((s) => s.length >= 3);
    final trigrams = <String>{};
    for (final seg in segments) {
      for (int i = 0; i <= seg.length - 3; i++) {
        trigrams.add(seg.substring(i, i + 3));
      }
    }
    return trigrams;
  }

  void initSync() {
    if (indexPath.startsWith(':memory:')) {
      final cached = _memoryRegistry[indexPath];
      if (cached != null) {
        index.clear();
        cached.forEach((tri, postings) {
          index[tri] = List.of(postings);
        });
      }
      return;
    }
    if (identical(0, 0.0)) return;
    final file = File(indexPath);
    if (file.existsSync()) {
      try {
        final content = file.readAsStringSync();
        final Map<String, dynamic> data = json.decode(content);
        index.clear();
        data.forEach((tri, postingsList) {
          final postings = (postingsList as List)
              .map((p) => TrigramPosting.fromJson(p as Map<String, dynamic>))
              .toList();
          index[tri] = postings;
        });
      } catch (_) {}
    }
  }

  void saveSync() {
    if (indexPath.startsWith(':memory:')) {
      final copy = <String, List<TrigramPosting>>{};
      index.forEach((tri, postings) {
        copy[tri] = List.of(postings);
      });
      _memoryRegistry[indexPath] = copy;
      return;
    }
    if (identical(0, 0.0)) return;
    final file = File(indexPath);
    if (!file.parent.existsSync()) {
      file.parent.createSync(recursive: true);
    }
    final data = <String, dynamic>{};
    index.forEach((tri, postings) {
      data[tri] = postings.map((p) => p.toJson()).toList();
    });
    file.writeAsStringSync(json.encode(data));
  }

  void addDocumentSync(String text, int pageId, int slotId) {
    final trigrams = extractTrigrams(text);
    final posting = TrigramPosting(pageId, slotId);
    for (final tri in trigrams) {
      final list = index.putIfAbsent(tri, () => []);
      if (!list.contains(posting)) {
        list.add(posting);
      }
    }
    if (autoSave) saveSync();
  }

  void removeDocumentSync(int pageId, int slotId) {
    final posting = TrigramPosting(pageId, slotId);
    bool changed = false;
    for (final list in index.values) {
      if (list.remove(posting)) {
        changed = true;
      }
    }
    if (changed && autoSave) saveSync();
  }

  /// Searches for candidate postings matching the query pattern.
  /// If no 3-character substring is present in the pattern, returns null (cannot filter with trigrams).
  List<TrigramPosting>? searchSync(String pattern) {
    final queryTrigrams = extractQueryTrigrams(pattern);
    if (queryTrigrams.isEmpty) return null;

    List<TrigramPosting>? candidates;
    for (final tri in queryTrigrams) {
      final postings = index[tri];
      if (postings == null || postings.isEmpty) {
        return []; // Trigram not found anywhere in index => 0 matches
      }
      if (candidates == null) {
        candidates = List<TrigramPosting>.from(postings);
      } else {
        final postingSet = postings.toSet();
        candidates = candidates.where((c) => postingSet.contains(c)).toList();
        if (candidates.isEmpty) return [];
      }
    }
    return candidates ?? [];
  }
}
