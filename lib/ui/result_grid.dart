import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../engine/executor/value.dart';

class ResultGrid extends StatefulWidget {
  final List<String> columns;
  final List<List<DbValue>> rows;
  final String message;

  const ResultGrid({
    super.key,
    required this.columns,
    required this.rows,
    required this.message,
  });

  @override
  State<ResultGrid> createState() => _ResultGridState();
}

class _ResultGridState extends State<ResultGrid> {
  int _currentPage = 1;
  int _pageSize = 100;

  @override
  void didUpdateWidget(ResultGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset page index if data has changed
    if (oldWidget.rows != widget.rows || oldWidget.columns != widget.columns) {
      _currentPage = 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final columns = widget.columns;
    final rows = widget.rows;
    final message = widget.message;

    if (columns.isEmpty) {
      final isError = message.toLowerCase().startsWith('error');
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: isError
              ? Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E2E),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFF38BA8), width: 1.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, color: Color(0xFFF38BA8), size: 28),
                      const SizedBox(width: 16),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'EXECUTION ERROR',
                              style: TextStyle(
                                color: Color(0xFFF38BA8),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.1,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              message.replaceFirst(RegExp(r'^[Ee]rror:\s*'), ''),
                              style: const TextStyle(
                                color: Color(0xFFCDD6F4),
                                fontSize: 14,
                                fontFamily: 'Courier',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.copy, color: Color(0xFFF38BA8), size: 20),
                        tooltip: 'Copy Error',
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: message));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Error message copied to clipboard!'),
                              backgroundColor: Color(0xFF1E1E2E),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                )
              : Text(
                  message.isEmpty ? 'No results to display.' : message,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
        ),
      );
    }

    final totalRows = rows.length;
    final totalPages = (totalRows / _pageSize).ceil();
    final actualTotalPages = totalPages < 1 ? 1 : totalPages;

    // Guard page index bounds
    if (_currentPage > actualTotalPages) {
      _currentPage = actualTotalPages;
    }

    final startIndex = (totalRows == 0) ? 0 : (_currentPage - 1) * _pageSize;
    var endIndex = startIndex + _pageSize;
    if (endIndex > totalRows) {
      endIndex = totalRows;
    }

    final displayedRows = (totalRows == 0)
        ? <List<DbValue>>[]
        : rows.sublist(startIndex, endIndex);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (message.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E2E),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: const Color(0xFFA6E3A1).withAlpha(76)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline, color: Color(0xFFA6E3A1), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      message,
                      style: const TextStyle(
                        color: Color(0xFFA6E3A1),
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E2E),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF313244)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SingleChildScrollView(
                scrollDirection: Axis.vertical,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: WidgetStateProperty.all(const Color(0xFF181825)),
                    dataRowColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return const Color(0xFF45475A);
                      }
                      return const Color(0xFF1E1E2E);
                    }),
                    dividerThickness: 1.0,
                    columns: columns.map((colName) {
                      return DataColumn(
                        label: Text(
                          colName,
                          style: const TextStyle(
                            color: Color(0xFFCBA6F7),
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Courier',
                          ),
                        ),
                      );
                    }).toList(),
                    rows: displayedRows.map((row) {
                      return DataRow(
                        cells: row.map((cellVal) {
                          return DataCell(
                            Text(
                              cellVal.toString(),
                              style: TextStyle(
                                color: cellVal is DbNull
                                    ? Colors.grey
                                    : (cellVal is DbInt || cellVal is DbDouble
                                        ? const Color(0xFFF9E2AF)
                                        : const Color(0xFFCDD6F4)),
                                fontFamily: 'Courier',
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        ),
        // Pagination Bar
        if (totalRows > 0)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E2E),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF313244)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Info text
                Text(
                  'Showing ${totalRows == 0 ? 0 : startIndex + 1} to $endIndex of $totalRows rows',
                  style: const TextStyle(
                    color: Color(0xFFBAC2DE),
                    fontSize: 13,
                  ),
                ),
                // Controls
                Row(
                  children: [
                    const Text(
                      'Page Size: ',
                      style: TextStyle(color: Color(0xFFBAC2DE), fontSize: 13),
                    ),
                    const SizedBox(width: 4),
                    Theme(
                      data: Theme.of(context).copyWith(
                        canvasColor: const Color(0xFF181825),
                      ),
                      child: DropdownButton<int>(
                        value: _pageSize,
                        underline: const SizedBox(),
                        style: const TextStyle(
                          color: Color(0xFFCBA6F7),
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                        items: [10, 50, 100, 500, 1000].map((size) {
                          return DropdownMenuItem<int>(
                            value: size,
                            child: Text(size.toString()),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _pageSize = val;
                              _currentPage = 1;
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: const Icon(Icons.first_page, size: 20),
                      color: _currentPage > 1 ? const Color(0xFFCBA6F7) : Colors.grey.shade700,
                      onPressed: _currentPage > 1
                          ? () => setState(() => _currentPage = 1)
                          : null,
                      tooltip: 'First Page',
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_left, size: 20),
                      color: _currentPage > 1 ? const Color(0xFFCBA6F7) : Colors.grey.shade700,
                      onPressed: _currentPage > 1
                          ? () => setState(() => _currentPage--)
                          : null,
                      tooltip: 'Previous Page',
                    ),
                    Text(
                      'Page $_currentPage of $actualTotalPages',
                      style: const TextStyle(
                        color: Color(0xFFCDD6F4),
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right, size: 20),
                      color: _currentPage < actualTotalPages ? const Color(0xFFCBA6F7) : Colors.grey.shade700,
                      onPressed: _currentPage < actualTotalPages
                          ? () => setState(() => _currentPage++)
                          : null,
                      tooltip: 'Next Page',
                    ),
                    IconButton(
                      icon: const Icon(Icons.last_page, size: 20),
                      color: _currentPage < actualTotalPages ? const Color(0xFFCBA6F7) : Colors.grey.shade700,
                      onPressed: _currentPage < actualTotalPages
                          ? () => setState(() => _currentPage = actualTotalPages)
                          : null,
                      tooltip: 'Last Page',
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }
}
