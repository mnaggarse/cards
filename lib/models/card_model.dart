import 'tag.dart';

enum CardType { normal, quran }

class CardModel {
  final int? id;
  final String body;
  final CardType type;
  final int? categoryId;
  final List<Tag> tags;
  final DateTime createdAt;

  const CardModel({
    this.id,
    required this.body,
    required this.type,
    this.categoryId,
    this.tags = const [],
    required this.createdAt,
  });

  factory CardModel.fromMap(Map<String, dynamic> map, List<Tag> tags) =>
      CardModel(
        id: map['id'] as int?,
        body: map['body'] as String,
        type: map['type'] == 'quran' ? CardType.quran : CardType.normal,
        categoryId: map['category_id'] as int?,
        tags: tags,
        createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      );
}
