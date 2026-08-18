import 'package:flutter/material.dart';

class ConsoleOutput extends StatelessWidget {
  final List<String> logs;

  const ConsoleOutput({super.key, required this.logs});

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) {
      return const Center(
        child: Text(
          'Console output is empty.\n(Use DBMS_OUTPUT.PUT_LINE in PL/SQL)',
          style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF11111B),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF313244)),
      ),
      padding: const EdgeInsets.all(12),
      child: ListView.builder(
        itemCount: logs.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2.0),
            child: Text(
              logs[index],
              style: const TextStyle(
                color: Color(0xFFCDD6F4),
                fontFamily: 'Courier',
                fontSize: 14,
              ),
            ),
          );
        },
      ),
    );
  }
}
