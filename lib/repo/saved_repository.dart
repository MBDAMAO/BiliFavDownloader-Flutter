import '../objectbox.g.dart';
import '../models/saved.dart';

class SavedRepository {
  final Store store;
  final Box<Saved> savedBox;

  SavedRepository(this.store) : savedBox = store.box<Saved>();

  // 获取所有保存的记录
  Future<List<Saved>> findAllSaved() async {
    return savedBox.getAll();
  }

  // 按aid列表查询
  Future<List<Saved>> findSavedByAidList(List<int> aidList) async {
    if (aidList.isEmpty) {
      return [];
    }
    final query = savedBox.query(Saved_.aid.oneOf(aidList)).build();
    final result = query.find();
    query.close();
    return result;
  }

  // 按aid和cid精确查询
  Future<List<Saved>> findSavedByAidCid(int aid, int cid) async {
    final query =
        savedBox.query(Saved_.aid.equals(aid) & Saved_.cid.equals(cid)).build();
    final result = query.find();
    query.close();
    return result;
  }

  // 插入或替换（先删除同aid+cid的记录再插入）
  Future<void> insertSaved(Saved saved) async {
    store.runInTransaction(TxMode.write, () {
      final deleteQuery =
          savedBox
              .query(
                Saved_.aid.equals(saved.aid).and(Saved_.cid.equals(saved.cid)),
              )
              .build();
      deleteQuery.remove();
      deleteQuery.close();
      savedBox.put(saved);
    });
  }

  // 批量插入
  // 批量插入（处理重复项）
  Future<void> batchInsertSaved(List<Saved> savedList) async {
    if (savedList.isEmpty) return;

    await store.runInTransaction(TxMode.write, () async {
      for (final saved in savedList) {
        // 删除现有的相同 aid + cid 记录
        final deleteQuery =
            savedBox
                .query(
                  Saved_.aid
                      .equals(saved.aid)
                      .and(Saved_.cid.equals(saved.cid)),
                )
                .build();
        deleteQuery.remove();
        deleteQuery.close();
      }

      // 批量插入新记录
      savedBox.putMany(savedList);
    });
  }

  Future<void> batchInsertSavedOptimized(List<Saved> savedList) async {
    if (savedList.isEmpty) return;

    await store.runInTransaction(TxMode.write, () {
      // 收集所有需要删除的条件
      final duplicateIds = <int>[];

      for (final saved in savedList) {
        final query =
            savedBox
                .query(
                  Saved_.aid
                      .equals(saved.aid)
                      .and(Saved_.cid.equals(saved.cid)),
                )
                .build();

        final existingIds = query.findIds();
        duplicateIds.addAll(existingIds);
        query.close();
      }

      // 批量删除重复项
      if (duplicateIds.isNotEmpty) {
        savedBox.removeMany(duplicateIds);
      }

      // 批量插入新记录
      savedBox.putMany(savedList);
    });
  }

  // 仅插入不存在的记录（如果你不需要替换现有记录）
  Future<void> batchInsertNewOnly(List<Saved> savedList) async {
    if (savedList.isEmpty) return;

    final newSavedList = <Saved>[];

    for (final saved in savedList) {
      final query =
          savedBox
              .query(
                Saved_.aid.equals(saved.aid).and(Saved_.cid.equals(saved.cid)),
              )
              .build();

      final exists = query.count() > 0;
      query.close();

      if (!exists) {
        newSavedList.add(saved);
      }
    }

    if (newSavedList.isNotEmpty) {
      await savedBox.putManyAsync(newSavedList);
    }
  }

  // 更新（同插入，ObjectBox通过ID自动匹配）
  Future<void> updateSaved(Saved saved) async => insertSaved(saved);

  // 更新状态
  Future<void> updateSavedStatusById(int id, Status status) async {
    final saved = await savedBox.getAsync(id);
    if (saved != null) {
      saved.status = status;
      await savedBox.putAsync(saved);
    }
  }

  // 删除单个
  Future<bool> deleteSaved(Saved saved) async {
    return await savedBox.removeAsync(saved.id);
  }

  // 按aid删除
  Future<void> deleteSavedByAid(int aid) async {
    final query = savedBox.query(Saved_.aid.equals(aid)).build();
    await query.removeAsync();
    query.close();
  }

  // 清空全部
  Future<void> deleteAllSaved() async {
    await savedBox.removeAllAsync();
  }
}
