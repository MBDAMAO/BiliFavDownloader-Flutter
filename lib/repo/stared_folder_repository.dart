import '../objectbox.g.dart';
import '../models/stared_folder.dart';

class StaredFolderRepository {
  final Store store;
  final Box<StaredFolder> staredFolderBox;

  StaredFolderRepository(this.store)
      : staredFolderBox = store.box<StaredFolder>();

  // 获取所有收藏夹
  Future<List<StaredFolder>> findAllStaredFolder() async {
    return staredFolderBox.getAll();
  }

  // 按ID查询
  Future<StaredFolder?> findStaredFolderById(int id) async {
    return staredFolderBox.get(id);
  }

  // 按folderId查询
  Future<List<StaredFolder>> findStaredFolderByFolderId(
      int folderId,
      ) async {
    final query = staredFolderBox.query(StaredFolder_.folderId.equals(folderId)).build();
    final result = query.find();
    query.close();
    return result;
  }

  Future<void> insertStaredFolder(StaredFolder folder) async {
    await staredFolderBox.putAsync(folder);
  }

  Future<void> batchInsertStaredFolder(List<StaredFolder> folders) async {
    await staredFolderBox.putManyAsync(folders);
  }

  Future<bool> deleteStaredFolder(StaredFolder folder) async {
    return await staredFolderBox.removeAsync(folder.id);
  }

  // 按folderId删除
  Future<void> deleteStaredFolderByFolderId(int folderId) async {
    final query = staredFolderBox.query(StaredFolder_.folderId.equals(folderId)).build();
    await query.removeAsync();
    query.close();
  }
}