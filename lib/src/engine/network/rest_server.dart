import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../executor/interpreter.dart';

/// Embedded REST & OpenAPI server daemon for UltSQL database instances.
class RestServer {
  final Database db;
  final String host;
  final int port;
  HttpServer? _server;
  late Interpreter _interpreter;

  RestServer(this.db, {this.host = '0.0.0.0', this.port = 8080}) {
    _interpreter = Interpreter(db);
  }

  bool get isRunning => _server != null;

  Future<int> start({bool autoPort = true}) async {
    int boundPort = port;
    int attempts = 0;
    while (attempts < 50) {
      try {
        _server = await HttpServer.bind(host, boundPort);
        _server!.listen(_handleRequest);
        return boundPort;
      } catch (e) {
        if (!autoPort) rethrow;
        boundPort++;
        attempts++;
      }
    }
    throw SocketException(
      "Failed to bind REST server on $host starting at port $port after 50 attempts.",
    );
  }

  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
  }

  void _handleRequest(HttpRequest request) async {
    final path = request.uri.path.trim();
    final method = request.method.toUpperCase();

    // CORS headers
    request.response.headers.add('Access-Control-Allow-Origin', '*');
    request.response.headers.add(
      'Access-Control-Allow-Methods',
      'GET, POST, DELETE, OPTIONS',
    );
    request.response.headers.add(
      'Access-Control-Allow-Headers',
      'Content-Type',
    );

    if (method == 'OPTIONS') {
      request.response.statusCode = HttpStatus.ok;
      await request.response.close();
      return;
    }

    try {
      if (path == '/openapi.json' && method == 'GET') {
        final openApiSpec = _generateOpenApiSpec();
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode(openApiSpec));
        await request.response.close();
        return;
      }

      final segments = path.split('/').where((s) => s.isNotEmpty).toList();
      if (segments.isEmpty) {
        request.response.headers.contentType = ContentType.json;
        request.response.write(
          jsonEncode({
            'engine': 'UltSQL REST Daemon',
            'status': 'online',
            'openapi':
                'http://${request.headers.host ?? "localhost:$port"}/openapi.json',
            'tables': db.catalog.tables.keys.toList(),
          }),
        );
        await request.response.close();
        return;
      }

      final tableName = segments[0].toLowerCase();

      if (method == 'POST' && !db.catalog.tables.containsKey(tableName)) {
        final content = await utf8.decoder.bind(request).join();
        final body = jsonDecode(content);
        if (body is Map<String, dynamic>) {
          final colDefs = body.entries
              .map((e) {
                final val = e.value;
                if (val is int) return '${e.key} INT';
                if (val is double) return '${e.key} DOUBLE';
                if (val is bool) return '${e.key} BOOLEAN';
                return '${e.key} TEXT';
              })
              .join(', ');
          await _interpreter.executeScript(
            "CREATE TABLE IF NOT EXISTS $tableName ($colDefs)",
          );

          final cols = body.keys.join(', ');
          final vals = body.values
              .map((v) => v is String ? "'$v'" : v.toString())
              .join(', ');
          final res = await _interpreter.executeScript(
            "INSERT INTO $tableName ($cols) VALUES ($vals)",
          );
          request.response.statusCode = HttpStatus.created;
          request.response.headers.contentType = ContentType.json;
          request.response.write(jsonEncode({'message': res.message}));
          await request.response.close();
          return;
        }
      }

      if (!db.catalog.tables.containsKey(tableName)) {
        request.response.statusCode = HttpStatus.notFound;
        request.response.headers.contentType = ContentType.json;
        request.response.write(
          jsonEncode({'error': "Table '$tableName' not found."}),
        );
        await request.response.close();
        return;
      }

      if (method == 'GET') {
        final res = await _interpreter.executeScript(
          "SELECT * FROM $tableName",
        );
        final jsonRows = res.rows
            .map((r) => r.map((v) => v.value).toList())
            .toList();
        request.response.headers.contentType = ContentType.json;
        request.response.write(
          jsonEncode({
            'table': tableName,
            'columns': res.columns,
            'count': jsonRows.length,
            'rows': jsonRows,
          }),
        );
      } else if (method == 'POST') {
        final content = await utf8.decoder.bind(request).join();
        final body = jsonDecode(content);
        if (body is Map<String, dynamic>) {
          final cols = body.keys.join(', ');
          final vals = body.values
              .map((v) => v is String ? "'$v'" : v.toString())
              .join(', ');
          final res = await _interpreter.executeScript(
            "INSERT INTO $tableName ($cols) VALUES ($vals)",
          );
          request.response.statusCode = HttpStatus.created;
          request.response.headers.contentType = ContentType.json;
          request.response.write(jsonEncode({'message': res.message}));
        } else {
          request.response.statusCode = HttpStatus.badRequest;
          request.response.write(
            jsonEncode({'error': 'Invalid JSON object payload.'}),
          );
        }
      } else if (method == 'DELETE') {
        final res = await _interpreter.executeScript(
          "TRUNCATE TABLE $tableName",
        );
        request.response.headers.contentType = ContentType.json;
        request.response.write(jsonEncode({'message': res.message}));
      } else {
        request.response.statusCode = HttpStatus.methodNotAllowed;
      }
    } catch (e) {
      request.response.statusCode = HttpStatus.internalServerError;
      request.response.headers.contentType = ContentType.json;
      request.response.write(jsonEncode({'error': e.toString()}));
    } finally {
      await request.response.close();
    }
  }

  Map<String, dynamic> _generateOpenApiSpec() {
    final paths = <String, dynamic>{};
    for (final table in db.catalog.tables.values) {
      paths['/${table.name}'] = {
        'get': {
          'summary': 'Retrieve all records from ${table.name}',
          'responses': {
            '200': {'description': 'Successful query response'},
          },
        },
        'post': {
          'summary': 'Insert record into ${table.name}',
          'requestBody': {
            'content': {
              'application/json': {
                'schema': {
                  'type': 'object',
                  'properties': {
                    for (int i = 0; i < table.columnNames.length; i++)
                      table.columnNames[i]: {'type': 'string'},
                  },
                },
              },
            },
          },
          'responses': {
            '201': {'description': 'Record inserted successfully'},
          },
        },
        'delete': {
          'summary': 'Truncate ${table.name}',
          'responses': {
            '200': {'description': 'Table truncated'},
          },
        },
      };
    }

    return {
      'openapi': '3.0.0',
      'info': {
        'title': 'UltSQL REST Daemon API',
        'version': '1.0.13',
        'description':
            'Auto-generated OpenAPI documentation from UltSQL database catalog.',
      },
      'paths': paths,
    };
  }
}
