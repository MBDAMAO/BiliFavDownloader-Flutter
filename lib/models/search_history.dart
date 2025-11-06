import 'package:objectbox/objectbox.dart';

@Entity()
class SearchHistory {
  @Id()
  int id;

  @Unique(onConflict: ConflictStrategy.replace)
  String keyword;

  @Property(type: PropertyType.date)
  DateTime time;

  SearchHistory({required this.id, required this.keyword, required this.time});
}
