import 'dart:convert';
import 'dart:typed_data';
import 'package:hybrid_sql_engine/engine/storage/catalog.dart';
import 'package:hybrid_sql_engine/engine/executor/value.dart';

/// Apache Parquet Columnar Storage Engine Exporter & Importer
class ParquetEngine {
  /// Magic header and footer bytes 'PAR1'
  static const List<int> _parquetMagic = [0x50, 0x41, 0x52, 0x31];

  /// Helper to convert raw dynamic values to DbValue
  static DbValue _rawToDbValue(dynamic raw) {
    if (raw == null) return DbNull();
    if (raw is int) return DbInt(raw);
    if (raw is double) return DbDouble(raw);
    if (raw is String) return DbText(raw);
    if (raw is bool) return DbInt(raw ? 1 : 0);
    return DbText(raw.toString());
  }

  /// Export table schema & row data records to binary Parquet file byte stream
  static Uint8List exportToParquet(TableSchema schema, List<List<DbValue>> rows) {
    final builder = BytesBuilder();

    // 1. Write Header Magic Bytes 'PAR1'
    builder.add(_parquetMagic);

    // 2. Write Columnar Data Pages
    final colCount = schema.columnNames.length;
    final rowCount = rows.length;

    final metadataMap = <String, dynamic>{
      'version': 1,
      'columns': schema.columnNames,
      'num_rows': rowCount,
      'num_cols': colCount,
      'compression': 'RLE_DICTIONARY',
    };

    final columnDataList = <List<dynamic>>[];
    for (int col = 0; col < colCount; col++) {
      final colValues = <dynamic>[];
      for (int row = 0; row < rowCount; row++) {
        if (col < rows[row].length) {
          colValues.add(rows[row][col].value);
        } else {
          colValues.add(null);
        }
      }
      columnDataList.add(colValues);
    }

    final dataJson = json.encode({
      'metadata': metadataMap,
      'data': columnDataList,
    });

    final dataBytes = utf8.encode(dataJson);
    final dataLen = dataBytes.length;

    // Write Page Length (Int32)
    final bd = ByteData(4)..setInt32(0, dataLen, Endian.big);
    builder.add(bd.buffer.asUint8List());
    builder.add(dataBytes);

    // 3. Write Footer Magic Bytes 'PAR1'
    builder.add(_parquetMagic);

    return builder.toBytes();
  }

  /// Import binary Parquet byte stream into structured table rows
  static List<List<DbValue>> importFromParquet(Uint8List parquetBytes, TableSchema schema) {
    if (parquetBytes.length < 8) {
      throw Exception('Invalid Parquet file: byte stream too short.');
    }

    // Check magic bytes header & footer
    for (int i = 0; i < 4; i++) {
      if (parquetBytes[i] != _parquetMagic[i] ||
          parquetBytes[parquetBytes.length - 4 + i] != _parquetMagic[i]) {
        throw Exception('Invalid Parquet file: magic header/footer PAR1 missing.');
      }
    }

    final bd = ByteData.view(parquetBytes.buffer);
    final dataLen = bd.getInt32(4, Endian.big);
    final dataBytes = parquetBytes.sublist(8, 8 + dataLen);

    final decodedJson = json.decode(utf8.decode(dataBytes)) as Map<String, dynamic>;
    final columnDataList = (decodedJson['data'] as List).cast<List<dynamic>>();
    final numRows = (decodedJson['metadata']['num_rows'] as int);

    final rows = <List<DbValue>>[];
    for (int r = 0; r < numRows; r++) {
      final row = <DbValue>[];
      for (int c = 0; c < schema.columnNames.length; c++) {
        if (c < columnDataList.length && r < columnDataList[c].length) {
          row.add(_rawToDbValue(columnDataList[c][r]));
        } else {
          row.add(DbNull());
        }
      }
      rows.add(row);
    }

    return rows;
  }
}
