import 'dart:convert';
import 'dart:io';

class PorterStemmer {
  static String stem(String word) {
    word = word.toLowerCase().trim();
    if (word.length < 3) return word;

    // Step 1a
    if (word.endsWith("sses")) {
      word = word.substring(0, word.length - 2);
    } else if (word.endsWith("ies")) {
      word = word.substring(0, word.length - 2) + "i";
    } else if (word.endsWith("ss")) {
      // Do nothing
    } else if (word.endsWith("s") &&
        !word.endsWith("us") &&
        !word.endsWith("is") &&
        !word.endsWith("as")) {
      word = word.substring(0, word.length - 1);
    }

    // Step 1b
    if (word.endsWith("eed")) {
      final stem = word.substring(0, word.length - 3);
      if (_measure(stem) > 0) {
        word = stem + "ee";
      }
    } else if (word.endsWith("ing")) {
      final stem = word.substring(0, word.length - 3);
      if (_containsVowel(stem)) {
        word = _cleanupStep1b(stem);
      }
    } else if (word.endsWith("ed")) {
      final stem = word.substring(0, word.length - 2);
      if (_containsVowel(stem)) {
        word = _cleanupStep1b(stem);
      }
    }

    // Step 1c (y to i)
    if (word.endsWith("y") &&
        _containsVowel(word.substring(0, word.length - 1))) {
      word = word.substring(0, word.length - 1) + "i";
    }

    // Step 2
    if (word.endsWith("ational")) {
      word = _replaceSuffix(word, "ational", "ate");
    } else if (word.endsWith("tional")) {
      word = _replaceSuffix(word, "tional", "tion");
    } else if (word.endsWith("izer")) {
      word = _replaceSuffix(word, "izer", "ize");
    } else if (word.endsWith("alli")) {
      word = _replaceSuffix(word, "alli", "al");
    } else if (word.endsWith("entli")) {
      word = _replaceSuffix(word, "entli", "ent");
    } else if (word.endsWith("eli")) {
      word = _replaceSuffix(word, "eli", "e");
    } else if (word.endsWith("ousli")) {
      word = _replaceSuffix(word, "ousli", "ous");
    } else if (word.endsWith("alism")) {
      word = _replaceSuffix(word, "alism", "al");
    } else if (word.endsWith("ation")) {
      word = _replaceSuffix(word, "ation", "ate");
    } else if (word.endsWith("aliti")) {
      word = _replaceSuffix(word, "aliti", "al");
    } else if (word.endsWith("iviti")) {
      word = _replaceSuffix(word, "iviti", "ive");
    } else if (word.endsWith("biliti")) {
      word = _replaceSuffix(word, "biliti", "ble");
    }

    // Step 3
    if (word.endsWith("icate")) {
      word = _replaceSuffix(word, "icate", "ic");
    } else if (word.endsWith("ative")) {
      word = _replaceSuffix(word, "ative", "");
    } else if (word.endsWith("alize")) {
      word = _replaceSuffix(word, "alize", "al");
    } else if (word.endsWith("iciti")) {
      word = _replaceSuffix(word, "iciti", "ic");
    } else if (word.endsWith("ical")) {
      word = _replaceSuffix(word, "ical", "ic");
    } else if (word.endsWith("ful")) {
      word = _replaceSuffix(word, "ful", "");
    } else if (word.endsWith("ness")) {
      word = _replaceSuffix(word, "ness", "");
    }

    // Step 4
    if (word.endsWith("al") ||
        word.endsWith("ance") ||
        word.endsWith("ence") ||
        word.endsWith("er") ||
        word.endsWith("ic") ||
        word.endsWith("able") ||
        word.endsWith("ible") ||
        word.endsWith("ant") ||
        word.endsWith("ement") ||
        word.endsWith("ment") ||
        word.endsWith("ent")) {
      final suffix = _findSuffix(word, [
        "al",
        "ance",
        "ence",
        "er",
        "ic",
        "able",
        "ible",
        "ant",
        "ement",
        "ment",
        "ent",
      ]);
      final stem = word.substring(0, word.length - suffix.length);
      if (_measure(stem) > 1) {
        word = stem;
      }
    } else if (word.endsWith("ion")) {
      final stem = word.substring(0, word.length - 3);
      if ((stem.endsWith("s") || stem.endsWith("t")) && _measure(stem) > 1) {
        word = stem;
      }
    }

    // Step 5a
    if (word.endsWith("e")) {
      final stem = word.substring(0, word.length - 1);
      final m = _measure(stem);
      if (m > 1 || (m == 1 && !_cvc(stem))) {
        word = stem;
      }
    }

    // Step 5b
    if (word.endsWith("l") && _doubleConsonant(word) && _measure(word) > 1) {
      word = word.substring(0, word.length - 1);
    }

    return word;
  }

  static int _measure(String stem) {
    int count = 0;
    bool vowel = false;
    for (int i = 0; i < stem.length; i++) {
      final isV = _isVowel(stem, i);
      if (isV && !vowel) {
        vowel = true;
      } else if (!isV && vowel) {
        vowel = false;
        count++;
      }
    }
    return count;
  }

  static bool _containsVowel(String stem) {
    for (int i = 0; i < stem.length; i++) {
      if (_isVowel(stem, i)) return true;
    }
    return false;
  }

  static bool _isVowel(String word, int index) {
    final char = word[index];
    if ("aeiou".contains(char)) return true;
    if (char == 'y' && index > 0 && !_isVowel(word, index - 1)) return true;
    return false;
  }

  static String _cleanupStep1b(String stem) {
    if (stem.endsWith("at") || stem.endsWith("bl") || stem.endsWith("iz")) {
      return stem + "e";
    }
    if (_doubleConsonant(stem) &&
        !stem.endsWith("l") &&
        !stem.endsWith("s") &&
        !stem.endsWith("z")) {
      return stem.substring(0, stem.length - 1);
    }
    if (_measure(stem) == 1 && _cvc(stem)) {
      return stem + "e";
    }
    return stem;
  }

  static bool _doubleConsonant(String word) {
    if (word.length < 2) return false;
    final c1 = word[word.length - 1];
    final c2 = word[word.length - 2];
    return c1 == c2 && !"aeiou".contains(c1);
  }

  static bool _cvc(String word) {
    if (word.length < 3) return false;
    final c1 = word[word.length - 1];
    return !_isVowel(word, word.length - 1) &&
        _isVowel(word, word.length - 2) &&
        !_isVowel(word, word.length - 3) &&
        c1 != 'w' &&
        c1 != 'x' &&
        c1 != 'y';
  }

  static String _replaceSuffix(String word, String suffix, String replacement) {
    final stem = word.substring(0, word.length - suffix.length);
    if (_measure(stem) > 0) {
      return stem + replacement;
    }
    return word;
  }

  static String _findSuffix(String word, List<String> suffixes) {
    for (final s in suffixes) {
      if (word.endsWith(s)) return s;
    }
    return "";
  }
}

const Set<String> stopWords = {
  "a",
  "about",
  "above",
  "after",
  "again",
  "against",
  "all",
  "am",
  "an",
  "and",
  "any",
  "are",
  "aren't",
  "as",
  "at",
  "be",
  "because",
  "been",
  "before",
  "being",
  "below",
  "between",
  "both",
  "but",
  "by",
  "can't",
  "cannot",
  "could",
  "couldn't",
  "did",
  "didn't",
  "do",
  "does",
  "doesn't",
  "doing",
  "don't",
  "down",
  "during",
  "each",
  "few",
  "for",
  "from",
  "further",
  "had",
  "hadn't",
  "has",
  "hasn't",
  "have",
  "haven't",
  "having",
  "he",
  "he'd",
  "he'll",
  "he's",
  "her",
  "here",
  "here's",
  "hers",
  "herself",
  "him",
  "himself",
  "his",
  "how",
  "how's",
  "i",
  "i'd",
  "i'll",
  "i'm",
  "i've",
  "if",
  "in",
  "into",
  "is",
  "isn't",
  "it",
  "it's",
  "its",
  "itself",
  "let's",
  "me",
  "more",
  "most",
  "mustn't",
  "my",
  "myself",
  "no",
  "nor",
  "not",
  "of",
  "off",
  "on",
  "once",
  "only",
  "or",
  "other",
  "ought",
  "our",
  "ours",
  "ourselves",
  "out",
  "over",
  "own",
  "same",
  "shan't",
  "she",
  "she'd",
  "she'll",
  "she's",
  "should",
  "shouldn't",
  "so",
  "some",
  "such",
  "than",
  "that",
  "that's",
  "the",
  "their",
  "theirs",
  "them",
  "themselves",
  "then",
  "there",
  "there's",
  "these",
  "they",
  "they'd",
  "they'll",
  "they're",
  "they've",
  "this",
  "those",
  "through",
  "to",
  "too",
  "under",
  "until",
  "up",
  "very",
  "was",
  "wasn't",
  "we",
  "we'd",
  "we'll",
  "we're",
  "we've",
  "were",
  "weren't",
  "what",
  "what's",
  "when",
  "when's",
  "where",
  "where's",
  "which",
  "while",
  "who",
  "who's",
  "whom",
  "why",
  "why's",
  "with",
  "won't",
  "would",
  "wouldn't",
  "you",
  "you'd",
  "you'll",
  "you're",
  "you've",
  "your",
  "yours",
  "yourself",
  "yourselves",
};

List<String> tokenizeAndStem(String text) {
  final cleanText = text.replaceAll(RegExp(r'[^\w\s]'), ' ').toLowerCase();
  final tokens = cleanText.split(RegExp(r'\s+'));
  final List<String> stemmed = [];
  for (final t in tokens) {
    if (t.isEmpty) continue;
    if (stopWords.contains(t)) continue;
    final stemmedWord = PorterStemmer.stem(t);
    if (stemmedWord.isNotEmpty) {
      stemmed.add(stemmedWord);
    }
  }
  return stemmed;
}

class FtsPosting {
  final int pageId;
  final int slotId;
  FtsPosting(this.pageId, this.slotId);

  Map<String, dynamic> toJson() => {'p': pageId, 's': slotId};
  factory FtsPosting.fromJson(Map<String, dynamic> json) =>
      FtsPosting(json['p'], json['s']);
}

class FtsIndex {
  final String indexPath;
  final Map<String, List<FtsPosting>> index = {};

  FtsIndex({required this.indexPath});

  void initSync() {
    final file = File(indexPath);
    if (file.existsSync()) {
      try {
        final content = file.readAsStringSync();
        final Map<String, dynamic> data = json.decode(content);
        index.clear();
        data.forEach((term, postingsList) {
          final postings = (postingsList as List)
              .map((p) => FtsPosting.fromJson(p))
              .toList();
          index[term] = postings;
        });
      } catch (_) {}
    }
  }

  void saveSync() {
    final file = File(indexPath);
    if (!file.parent.existsSync()) {
      file.parent.createSync(recursive: true);
    }
    final data = <String, dynamic>{};
    index.forEach((term, postings) {
      data[term] = postings.map((p) => p.toJson()).toList();
    });
    file.writeAsStringSync(json.encode(data));
  }

  void addDocumentSync(String text, int pageId, int slotId) {
    final terms = tokenizeAndStem(text);
    for (final term in terms) {
      final list = index.putIfAbsent(term, () => []);
      if (!list.any((p) => p.pageId == pageId && p.slotId == slotId)) {
        list.add(FtsPosting(pageId, slotId));
      }
    }
    saveSync();
  }

  List<FtsPosting> searchSync(String query) {
    final terms = tokenizeAndStem(query);
    if (terms.isEmpty) return [];

    List<FtsPosting>? results;
    for (final term in terms) {
      final postings = index[term];
      if (postings == null || postings.isEmpty) {
        return [];
      }
      if (results == null) {
        results = List<FtsPosting>.from(postings);
      } else {
        results = results
            .where(
              (r) => postings.any(
                (p) => p.pageId == r.pageId && p.slotId == r.slotId,
              ),
            )
            .toList();
      }
    }
    return results ?? [];
  }
}
