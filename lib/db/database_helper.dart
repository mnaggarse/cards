import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/card_model.dart';
import '../models/category.dart';
import '../models/tag.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    _database ??= await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'cards.db');
    return await openDatabase(
      path,
      version: 1,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE categories (
        id   INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE
      )
    ''');
    await db.execute('''
      CREATE TABLE tags (
        id   INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE
      )
    ''');
    await db.execute('''
      CREATE TABLE cards (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        body        TEXT NOT NULL,
        type        TEXT NOT NULL CHECK(type IN ('normal','quran')),
        category_id INTEGER REFERENCES categories(id) ON DELETE SET NULL,
        created_at  INTEGER NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE card_tags (
        card_id INTEGER REFERENCES cards(id) ON DELETE CASCADE,
        tag_id  INTEGER REFERENCES tags(id)  ON DELETE CASCADE,
        PRIMARY KEY (card_id, tag_id)
      )
    ''');
  }

  // ─── Categories ────────────────────────────────────────────────────────────

  Future<int> insertCategory(String name) async {
    final db = await database;
    final id = await db.insert('categories', {
      'name': name,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
    if (id > 0) return id;
    // Already exists — fetch its real id
    final rows = await db.query(
      'categories',
      where: 'name = ?',
      whereArgs: [name],
      limit: 1,
    );
    return rows.first['id'] as int;
  }

  Future<List<Category>> getAllCategories() async {
    final db = await database;
    final rows = await db.query('categories', orderBy: 'id ASC');
    return rows.map((r) => Category.fromMap(r)).toList();
  }

  Future<void> deleteCategory(int id) async {
    final db = await database;
    await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  // ─── Tags ──────────────────────────────────────────────────────────────────

  Future<int> insertTag(String name) async {
    final db = await database;
    // Try insert first; sqflite returns -1 (or 0) on ConflictAlgorithm.ignore
    final id = await db.insert('tags', {
      'name': name,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
    if (id > 0) return id;
    // Already exists — fetch its real id
    final rows = await db.query(
      'tags',
      where: 'name = ?',
      whereArgs: [name],
      limit: 1,
    );
    return rows.first['id'] as int;
  }

  Future<List<Tag>> getAllTags() async {
    final db = await database;
    final rows = await db.query('tags', orderBy: 'id ASC');
    return rows.map((r) => Tag.fromMap(r)).toList();
  }

  Future<bool> updateTag(int id, String newName) async {
    final db = await database;
    final trimmed = newName.trim();
    if (trimmed.isEmpty) return false;

    // Check if another tag already has this name
    final existing = await db.query(
      'tags',
      where: 'LOWER(name) = LOWER(?) AND id != ?',
      whereArgs: [trimmed, id],
      limit: 1,
    );
    if (existing.isNotEmpty) {
      return false;
    }

    await db.update(
      'tags',
      {'name': trimmed},
      where: 'id = ?',
      whereArgs: [id],
    );
    return true;
  }

  // ─── Cards ─────────────────────────────────────────────────────────────────

  Future<int> insertCard(CardModel card, List<int> tagIds) async {
    final db = await database;
    int cardId = 0;
    await db.transaction((txn) async {
      cardId = await txn.insert('cards', {
        'body': card.body,
        'type': card.type.name,
        'category_id': card.categoryId,
        'created_at': card.createdAt.millisecondsSinceEpoch,
      });
      for (final tagId in tagIds) {
        await txn.insert('card_tags', {
          'card_id': cardId,
          'tag_id': tagId,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
    });
    return cardId;
  }

  Future<void> updateCard(CardModel card, List<int> tagIds) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.update(
        'cards',
        {
          'body': card.body,
          'type': card.type.name,
          'category_id': card.categoryId,
        },
        where: 'id = ?',
        whereArgs: [card.id],
      );
      // Replace all tags
      await txn.delete('card_tags', where: 'card_id = ?', whereArgs: [card.id]);
      for (final tagId in tagIds) {
        await txn.insert('card_tags', {
          'card_id': card.id,
          'tag_id': tagId,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
    });
  }

  Future<void> deleteCard(int id) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('card_tags', where: 'card_id = ?', whereArgs: [id]);
      await txn.delete('cards', where: 'id = ?', whereArgs: [id]);
    });
  }

  Future<List<CardModel>> getAllCards() async {
    final db = await database;
    return _queryCards(db, null, null);
  }

  Future<List<CardModel>> _queryCards(
    Database db,
    String? where,
    List<Object?>? whereArgs,
  ) async {
    final cardRows = await db.query(
      'cards',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'created_at DESC',
    );

    final List<CardModel> result = [];
    for (final row in cardRows) {
      final cardId = row['id'] as int;
      final tagRows = await db.rawQuery(
        '''
        SELECT t.id, t.name FROM tags t
        INNER JOIN card_tags ct ON ct.tag_id = t.id
        WHERE ct.card_id = ?
      ''',
        [cardId],
      );
      final tags = tagRows.map((r) => Tag.fromMap(r)).toList();
      result.add(CardModel.fromMap(row, tags));
    }
    return result;
  }

  // Prune tags that are no longer referenced by any card
  Future<void> pruneOrphanTags() async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.execute('''
        DELETE FROM card_tags WHERE card_id NOT IN (SELECT id FROM cards)
      ''');
      await txn.execute('''
        DELETE FROM tags WHERE id NOT IN (SELECT DISTINCT tag_id FROM card_tags)
      ''');
    });
  }

  // Prune categories that are no longer referenced by any card
  Future<void> pruneOrphanCategories() async {
    final db = await database;
    await db.execute('''
      DELETE FROM categories WHERE id NOT IN (
        SELECT DISTINCT category_id FROM cards WHERE category_id IS NOT NULL
      )
    ''');
  }
}
