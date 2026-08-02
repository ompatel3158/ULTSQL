import 'dart:typed_data';
import '../cache/page_cache.dart';
import '../executor/interpreter.dart';
import 'table_file.dart';
import 'catalog.dart';

class VacuumManager {
  final Database db;

  VacuumManager(this.db);

  void vacuumTable(String tableName, {bool full = false}) {
    final schema = db.catalog.getTableSchema(tableName);
    if (schema == null) {
      throw Exception("Table '$tableName' does not exist.");
    }

    if (schema.isColumnar) {
      return; // Vacuum not implemented for columnar
    }

    final tableFile = RowTableFile(
      cache: db.cache,
      tableName: tableName,
      dbDirectory: db.directory,
    );

    tableFile.flushActivePageSync();

    final pager = tableFile.pager;
    final pageCount = pager.getPageCountSync();
    
    final currentTxId = db.cache.currentMvccTx?.txId ?? db.cache.mvccTxManager.nextTxId;
    final activeTxIds = db.cache.mvccTxManager.activeTxIds;

    int totalDeadTuples = 0;
    int totalBytesFreed = 0;

    for (int pageId = 0; pageId < pageCount; pageId++) {
      final page = db.cache.pinPageSync(tableFile.filePath, pageId);
      final rowCount = SlottedPageHelper.getRowCount(page);
      
      List<Uint8List> liveRecords = [];
      int deadTuplesInPage = 0;
      
      for (int slotId = 0; slotId < rowCount; slotId++) {
        final recBytes = SlottedPageHelper.getRecord(page, slotId);
        if (recBytes != null) {
          bool isDead = false;
          if (recBytes.length >= 12) {
            final bd = ByteData.sublistView(recBytes);
            // final xmin = bd.getUint32(0);
            final xmax = bd.getUint32(4);
            
            // If xmax > 0 and xmax < current active tx, it's deleted and no longer visible
            if (xmax > 0 && xmax < currentTxId && !activeTxIds.contains(xmax)) {
              isDead = true;
            }
          }
          
          if (!isDead) {
            liveRecords.add(Uint8List.fromList(recBytes));
          } else {
            deadTuplesInPage++;
            totalBytesFreed += recBytes.length;
          }
        }
      }

      if (deadTuplesInPage > 0 || full) {
        // Defragment page
        final newPageData = Uint8List(4096);
        final newBd = ByteData.sublistView(newPageData);
        
        newBd.setUint8(0, 1); // pageType
        newBd.setUint16(1, liveRecords.length); // rowCount
        
        int currentFreeSpace = 4096;
        for (int i = 0; i < liveRecords.length; i++) {
          final rec = liveRecords[i];
          currentFreeSpace -= rec.length;
          
          // Copy record to end of page
          newPageData.setAll(currentFreeSpace, rec);
          
          // Set slot
          final slotOffset = 5 + i * 4;
          newBd.setUint16(slotOffset, currentFreeSpace);
          newBd.setUint16(slotOffset + 2, rec.length);
        }
        
        newBd.setUint16(3, currentFreeSpace); // freeSpaceOffset
        
        // Copy back to actual page
        page.data.setAll(0, newPageData);
        page.rowCount = liveRecords.length;
        page.freeSpaceOffset = currentFreeSpace;
        
        db.cache.unpinPageSync(tableFile.filePath, pageId, isDirty: true);
        totalDeadTuples += deadTuplesInPage;
      } else {
        db.cache.unpinPageSync(tableFile.filePath, pageId, isDirty: false);
      }
    }
    
    // In a full vacuum, we might truncate empty pages at the end, but let's keep it simple.
  }
}
