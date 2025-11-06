import '../objectbox.g.dart';
import '../models/download_cursor.dart';

class DownloadCursorRepository {
  final Store store;
  final Box<DownloadCursor> cursorBox;

  DownloadCursorRepository(this.store)
    : cursorBox = store.box<DownloadCursor>();

  // 查询指定文件夹的下载游标
  Future<DownloadCursor?> findCursorByFolderId(int folderId) async {
    final query =
        cursorBox.query(DownloadCursor_.folderId.equals(folderId)).build();
    final result = query.find();
    query.close();
    return result.isNotEmpty ? result.first : null;
  }

  // 插入或更新下载游标
  Future<void> insertOrUpdateCursor(DownloadCursor cursor) async {
    // 先删除旧记录
    final oldCursor = await findCursorByFolderId(cursor.folderId);
    if (oldCursor != null) {
      cursorBox.remove(oldCursor.id);
    }
    // 插入新记录
    cursorBox.put(cursor);
  }
}
