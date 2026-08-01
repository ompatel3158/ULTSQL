import 'package:flutter_test/flutter_test.dart';
import 'package:ultsql/engine/parser/ast.dart';
import 'package:ultsql/engine/executor/value.dart';
import 'package:ultsql/engine/executor/jit_compiler.dart';
import 'package:ultsql/engine/executor/plan_nodes.dart';

void main() {
  test('Expression JIT Compiler achieves >= 3x speedup over interpreter', () {
    // 1. Build an expression: (x * 10 + y) > 50 AND label = 'shoes'
    // Inside AST: BinaryExpr('AND', BinaryExpr('>', BinaryExpr('+', BinaryExpr('*', VariableExpr('x'), LiteralExpr(10)), VariableExpr('y')), LiteralExpr(50)), BinaryExpr('=', VariableExpr('label'), LiteralExpr('shoes')))
    final expr = BinaryExpr(
      '=',
      BinaryExpr(
        '+',
        BinaryExpr('*', VariableExpr(['x']), LiteralExpr(10)),
        VariableExpr(['y']),
      ),
      LiteralExpr(65),
    );

    final rowContext = {
      'x': DbInt(6),
      'y': DbInt(5),
      'label': DbText('shoes'),
    };

    const iterations = 100000;

    // 2. Benchmark Interpreter (Recursive AST evaluation)
    final interpreterStopwatch = Stopwatch()..start();
    for (int i = 0; i < iterations; i++) {
      final res = evaluateExpression(expr, rowContext);
      if (res is! DbInt || res.value != 1) {
        fail('Interpreter returned wrong value');
      }
    }
    interpreterStopwatch.stop();
    final interpreterTime = interpreterStopwatch.elapsedMilliseconds;

    // 3. Benchmark JIT Compiler (Native Dart Closure evaluation)
    final jitClosure = JitCompiler.compile(expr);
    
    // First run to resolve keys
    jitClosure(rowContext);

    final jitStopwatch = Stopwatch()..start();
    for (int i = 0; i < iterations; i++) {
      final res = jitClosure(rowContext);
      if (res is! DbInt || res.value != 1) {
        fail('JIT returned wrong value');
      }
    }
    jitStopwatch.stop();
    final jitTime = jitStopwatch.elapsedMilliseconds;

    print('JIT Benchmark results:');
    print('  AST Interpreter: ${interpreterTime}ms');
    print('  JIT Compiler:    ${jitTime}ms');
    final speedup = interpreterTime / (jitTime == 0 ? 1 : jitTime);
    print('  Calculated Speedup: ${speedup.toStringAsFixed(2)}x');

    expect(speedup, greaterThanOrEqualTo(3.0), reason: "JIT compiler must be at least 3x faster than AST interpreter.");
  });

  test('JIT Compiler handles logical AND/OR expressions', () {
    final expr = BinaryExpr(
      'and',
      BinaryExpr('>', VariableExpr(['age']), LiteralExpr(20)),
      BinaryExpr('or',
        BinaryExpr('=', VariableExpr(['name']), LiteralExpr('Bob')),
        BinaryExpr('=', VariableExpr(['name']), LiteralExpr('Alice')),
      ),
    );

    final contextAlice = {
      'age': DbInt(25),
      'name': DbText('Alice'),
    };
    final contextBob = {
      'age': DbInt(18),
      'name': DbText('Bob'),
    };

    final closure = JitCompiler.compile(expr);
    expect((closure(contextAlice) as DbInt).value, 1);
    expect((closure(contextBob) as DbInt).value, 0); // age not > 20
  });
}
