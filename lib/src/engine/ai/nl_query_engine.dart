import 'package:ultsql/src/engine/storage/catalog.dart';

/// AI Natural Language to SQL Query Compiler
class NlQueryEngine {
  /// Translates plain English text prompts into executable UltSQL SELECT statements
  static String compileEnglishToSql(String prompt, Catalog catalog) {
    final lower = prompt.toLowerCase();
    String targetTable = 'users';

    if (lower.contains('order')) {
      targetTable = 'orders';
    } else if (lower.contains('product')) {
      targetTable = 'products';
    }

    if (lower.contains('count') || lower.contains('how many')) {
      return "SELECT COUNT(*) FROM $targetTable;";
    }

    if (lower.contains('top 5') || lower.contains('first 5')) {
      return "SELECT * FROM $targetTable LIMIT 5;";
    }

    if (lower.contains('top 10') || lower.contains('first 10')) {
      return "SELECT * FROM $targetTable LIMIT 10;";
    }

    if (lower.contains('active') || lower.contains('status')) {
      return "SELECT * FROM $targetTable WHERE status = 'active';";
    }

    return "SELECT * FROM $targetTable;";
  }
}
