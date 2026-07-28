import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:hybrid_sql_engine/engine/ult_sql_engine.dart';
import 'package:hybrid_sql_engine/engine/storage/catalog.dart';
import 'package:hybrid_sql_engine/engine/cache/engine_config.dart';

void main() {
  test('EngineConfig and SET ENGINE_OPTION runtime toggles', () async {
    final config = EngineConfig.defaultConfig();
    expect(config.enableAutovacuum, isTrue);
    expect(config.enableBlockCompression, isTrue);
    expect(config.enableAuditLogging, isTrue);

    final engine = await UltSqlEngine.openMemory();
    engine.db.config.enableAutovacuum = false;
    expect(engine.db.config.enableAutovacuum, isFalse);

    engine.db.config.enableAutovacuum = true;
    expect(engine.db.config.enableAutovacuum, isTrue);

    final qres = await engine.query("SET ENGINE_OPTION 'autovacuum' = OFF;");
    expect(qres.message, contains('autovacuum set to OFF'));
    expect(engine.db.config.enableAutovacuum, isFalse);

    await engine.close();
  });

  test('100-bucket ColumnHistogram builds and calculates selectivity', () {
    final values = List<double>.generate(1000, (i) => i.toDouble());
    final histogram = ColumnHistogram();
    histogram.buildFromValues(values);

    expect(histogram.buckets.length, greaterThan(0));
    final selectivity = histogram.calculateSelectivity(500.0);
    expect(selectivity, greaterThan(0.0));
    expect(selectivity, lessThanOrEqualTo(1.0));
  });

  test('PGWire server SSLRequest negotiation reflects TLS toggle', () async {
    final engine = await UltSqlEngine.openMemory();
    engine.db.config.enableTlsEncryption = true;
    
    final port = await engine.startServer(port: 5437);
    expect(port, equals(5437));

    final socket = await Socket.connect('127.0.0.1', 5437);
    
    // Send SSLRequest
    final sslBuf = BytesBuilder();
    sslBuf.add([0, 0, 0, 8]); // Length
    sslBuf.add([0, 3, 0, 0]); // Protocol fallback code
    final sslBytes = sslBuf.takeBytes();
    ByteData.view(sslBytes.buffer).setInt32(4, 80877103, Endian.big);
    
    socket.add(sslBytes);

    final completer = Completer<int>();
    socket.listen((data) {
      if (data.isNotEmpty && !completer.isCompleted) {
        completer.complete(data[0]);
      }
    });

    final respCode = await completer.future.timeout(Duration(seconds: 5), onTimeout: () => 0);
    expect(respCode, equals(83)); // 83 = 'S' (SSL Supported)

    socket.destroy();
    await engine.close();
  });
}
