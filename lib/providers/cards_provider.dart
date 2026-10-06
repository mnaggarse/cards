import 'package:flutter/foundation.dart' hide Category;
import '../db/database_helper.dart';
import '../models/card_model.dart';
import '../models/category.dart';
import '../models/tag.dart';

enum CardSortOrder { date, alphabetical, length }

class CardsProvider extends ChangeNotifier {
  final _db = DatabaseHelper.instance;

  List<CardModel> _allCards = [];
  List<Category> _categories = [];
  List<Tag> _allTags = [];
  String _searchQuery = '';
  Set<int> _selectedTagIds = {};
  CardSortOrder _sortOrder = CardSortOrder.date;

  // ─── Multi-selection ───────────────────────────────────────────────────────
  Set<int> _selectedIds = {};
  Set<int> get selectedIds => Set.unmodifiable(_selectedIds);
  bool get selectionMode => _selectedIds.isNotEmpty;

  void toggleSelection(int cardId) {
    if (_selectedIds.contains(cardId)) {
      _selectedIds.remove(cardId);
    } else {
      _selectedIds.add(cardId);
    }
    notifyListeners();
  }

  void clearSelection() {
    _selectedIds = {};
    notifyListeners();
  }

  Future<void> deleteSelectedCards() async {
    final ids = List.of(_selectedIds);
    for (final id in ids) {
      await _db.deleteCard(id);
    }
    await _db.pruneOrphanTags();
    await _db.pruneOrphanCategories();
    _selectedIds = {};
    await loadAll();
  }

  // ─── Public getters ────────────────────────────────────────────────────────

  /// Tab 0 = "الكل", Tab i = _categories[i-1]
  List<Category> get categories => _categories;

  List<Tag> get allTags => _allTags;

  String get searchQuery => _searchQuery;

  Set<int> get selectedTagIds => _selectedTagIds;

  bool get isFiltering => _selectedTagIds.isNotEmpty;

  bool get isSearching => _searchQuery.trim().isNotEmpty;

  CardSortOrder get sortOrder => _sortOrder;

  // ─── Sort ──────────────────────────────────────────────────────────────────

  void setSortOrder(CardSortOrder order) {
    _sortOrder = order;
    notifyListeners();
  }

  /// Returns cards for a given tab index (0 = All).
  List<CardModel> cardsForTab(int tabIndex) {
    List<CardModel> cards;
    if (tabIndex == 0) {
      cards = List.of(_allCards);
    } else {
      final category = _categories[tabIndex - 1];
      cards = _allCards.where((c) => c.categoryId == category.id).toList();
    }

    // Apply tag filter (AND — card must have ALL selected tags)
    if (_selectedTagIds.isNotEmpty) {
      cards = cards.where((c) {
        final cardTagIds = c.tags.map((t) => t.id!).toSet();
        return _selectedTagIds.every((id) => cardTagIds.contains(id));
      }).toList();
    }

    // Apply search query
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      cards = cards.where((c) => c.body.toLowerCase().contains(q)).toList();
    }

    // Apply sort
    switch (_sortOrder) {
      case CardSortOrder.date:
        cards.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case CardSortOrder.alphabetical:
        cards.sort((a, b) => a.body.compareTo(b.body));
      case CardSortOrder.length:
        cards.sort((a, b) => a.body.length.compareTo(b.body.length));
    }

    return cards;
  }

  /// Number of matching cards in a given tab (used for search badge).
  int matchCountForTab(int tabIndex) {
    if (!isSearching && !isFiltering) return 0;
    return cardsForTab(tabIndex).length;
  }

  // ─── Load ──────────────────────────────────────────────────────────────────

  Future<void> loadAll() async {
    await _db.pruneOrphanTags();
    await _db.pruneOrphanCategories();
    _categories = await _db.getAllCategories();
    _allTags = await _db.getAllTags();
    _allCards = await _db.getAllCards();
    final existingTagIds = _allTags.map((t) => t.id!).toSet();
    _selectedTagIds = _selectedTagIds.intersection(existingTagIds);
    notifyListeners();
  }

  // ─── Search ────────────────────────────────────────────────────────────────

  void setSearch(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  // ─── Tag filter ────────────────────────────────────────────────────────────

  void setTagFilter(Set<int> tagIds) {
    _selectedTagIds = tagIds;
    notifyListeners();
  }

  void clearTagFilter() {
    _selectedTagIds = {};
    notifyListeners();
  }

  Future<bool> updateTag(int id, String newName) async {
    final success = await _db.updateTag(id, newName);
    if (success) {
      await loadAll();
    }
    return success;
  }

  // ─── Card CRUD ─────────────────────────────────────────────────────────────

  Future<void> addCard({
    required String body,
    required CardType type,
    required String? categoryName,
    required List<String> tagNames,
  }) async {
    int? categoryId;
    if (categoryName != null && categoryName.trim().isNotEmpty) {
      categoryId = await _db.insertCategory(categoryName.trim());
    }

    final tagIds = <int>[];
    for (final name in tagNames) {
      if (name.trim().isNotEmpty) {
        tagIds.add(await _db.insertTag(name.trim()));
      }
    }

    final card = CardModel(
      body: body.trim(),
      type: type,
      categoryId: categoryId,
      createdAt: DateTime.now(),
    );

    await _db.insertCard(card, tagIds);
    await loadAll();
  }

  Future<void> updateCard({
    required int id,
    required String body,
    required CardType type,
    required String? categoryName,
    required List<String> tagNames,
  }) async {
    int? categoryId;
    if (categoryName != null && categoryName.trim().isNotEmpty) {
      categoryId = await _db.insertCategory(categoryName.trim());
    }

    final tagIds = <int>[];
    for (final name in tagNames) {
      if (name.trim().isNotEmpty) {
        tagIds.add(await _db.insertTag(name.trim()));
      }
    }

    final existing = _allCards.firstWhere((c) => c.id == id);
    final updated = CardModel(
      id: id,
      body: body.trim(),
      type: type,
      categoryId: categoryId,
      createdAt: existing.createdAt,
    );

    await _db.updateCard(updated, tagIds);
    await _db.pruneOrphanTags();
    await _db.pruneOrphanCategories();
    await loadAll();
  }

  Future<void> deleteCard(int id) async {
    await _db.deleteCard(id);
    await _db.pruneOrphanTags();
    await _db.pruneOrphanCategories();
    await loadAll();
  }
}
