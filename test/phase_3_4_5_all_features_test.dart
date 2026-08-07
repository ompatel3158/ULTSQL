import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:ultsql/ultsql.dart';
import 'package:http/http.dart' as http;

void expectVal(dynamic actual, dynamic expected, String message) {
  final actualStr = actual.toString();
  final expectedStr = expected.toString();
  if (actualStr != expectedStr) {
    throw Exception("FAIL [$message]: Expected '$expectedStr', but got '$actualStr'");
  }
}

void main() {
  test('Phase 3, 4 & 5 Complete Engine Capabilities Test', () async {
    final tempDir = await Directory.systemTemp.createTemp('ultsql_all_phases_test_');
    final db = Database(tempDir.path);
    final interpreter = Interpreter(db);

    try {
      // --- 1. SQL MACROS ---
      print("Testing SQL Macros (CREATE MACRO)...");
      final resMacro = await interpreter.executeScript("CREATE MACRO add_numbers(a, b) AS a + b");
      expectVal(resMacro.message.contains('created'), true, "Macro creation message");
      expectVal(db.getMacro('add_numbers') != null, true, "Macro registered in database");

      // --- 2. EVENT STREAMS ---
      print("Testing Event Streams (CREATE STREAM & EMIT TO)...");
      await interpreter.executeScript("CREATE STREAM user_events");
      
      final emittedEvents = <List<DbValue>>[];
      final streamSub = db.getStream("user_events").listen((events) {
        emittedEvents.add(events);
      });

      await interpreter.executeScript("EMIT TO user_events VALUES ('user_signed_up', 101)");
      await Future.delayed(const Duration(milliseconds: 100));

      expectVal(emittedEvents.length, 1, "Emitted events count");
      expectVal(emittedEvents[0][0], DbText('user_signed_up'), "Emitted event type");
      expectVal(emittedEvents[0][1], DbInt(101), "Emitted user ID");
      await streamSub.cancel();

      // --- 3. EMBEDDED REST & OPENAPI DAEMON ---
      print("Testing Embedded REST Daemon & OpenAPI Specification...");
      await interpreter.executeScript("CREATE TABLE api_products (id INT PRIMARY KEY, name TEXT)");
      await interpreter.executeScript("INSERT INTO api_products VALUES (1, 'Gaming Laptop')");

      final restServer = RestServer(db, port: 8989);
      await restServer.start();
      expectVal(restServer.isRunning, true, "REST Server running status");

      final openApiResp = await http.get(Uri.parse('http://localhost:8989/openapi.json'));
      expectVal(openApiResp.statusCode, 200, "OpenAPI status code");
      final openApiJson = jsonDecode(openApiResp.body);
      expectVal(openApiJson['openapi'], '3.0.0', "OpenAPI version");
      expectVal(openApiJson['paths'].containsKey('/api_products'), true, "OpenAPI schema table path");

      final tableResp = await http.get(Uri.parse('http://localhost:8989/api_products'));
      expectVal(tableResp.statusCode, 200, "REST GET table status");
      final tableJson = jsonDecode(tableResp.body);
      expectVal(tableJson['count'], 1, "REST GET row count");

      final postResp = await http.post(
        Uri.parse('http://localhost:8989/api_products'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'id': 2, 'name': 'Mechanical Keyboard'}),
      );
      expectVal(postResp.statusCode, 201, "REST POST status code");

      await restServer.stop();
      expectVal(restServer.isRunning, false, "REST Server stopped status");

      // --- 4. COPY-ON-WRITE DATABASE BRANCHING ---
      print("Testing Copy-on-Write Database Branching (db.createBranch, switchBranch)...");
      expectVal(db.currentBranch, 'main', "Default initial branch is main");
      expectVal(db.listBranches().contains('main'), true, "Branch list contains main");

      db.createBranch('dev_feature');
      expectVal(db.listBranches().contains('dev_feature'), true, "Branch dev_feature created");

      db.switchBranch('dev_feature');
      expectVal(db.currentBranch, 'dev_feature', "Active branch switched to dev_feature");

      db.mergeBranch('main');
      db.switchBranch('main');
      db.deleteBranch('dev_feature');
      expectVal(db.listBranches().contains('dev_feature'), false, "Branch dev_feature deleted");

      print("\nALL PHASE 3, 4 & 5 ENGINE TESTS PASSED CLEANLY!");
    } finally {
      db.close();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    }
  });
}
