import '../objectbox.g.dart';
import '../models/search_history.dart';

class SearchHistoryRepository {
  final Store store;
  final Box<SearchHistory> searchHistoryBox;

  SearchHistoryRepository(this.store)
    : searchHistoryBox = store.box<SearchHistory>();

  Future<List<SearchHistory>> getAll() async {
    return searchHistoryBox.getAll();
  }

  Future<void> add(SearchHistory history) async {
    searchHistoryBox.put(history);
  }

  Future<void> delete(int id) async {
    searchHistoryBox.remove(id);
  }

  Future<void> deleteAll() async {
    searchHistoryBox.removeAll();
  }
}
