import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cards_provider.dart';
import '../theme/app_fonts.dart';
import '../widgets/add_card_sheet.dart';
import '../widgets/card_list_view.dart';
import '../widgets/tag_filter_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  int _tabCount = 1; // starts with "All" only

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabCount, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CardsProvider>().loadAll();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  /// Safely replaces the TabController after the current build finishes.
  void _updateTabCount(int newCount) {
    if (newCount == _tabCount) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final prevIndex = _tabController.index.clamp(0, newCount - 1);
      _tabController.dispose();
      setState(() {
        _tabCount = newCount;
        _tabController = TabController(
          length: newCount,
          vsync: this,
          initialIndex: prevIndex,
        );
      });
    });
  }

  void _openAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<CardsProvider>(),
        child: const AddCardSheet(),
      ),
    );
  }

  void _openFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<CardsProvider>(),
        child: const TagFilterSheet(),
      ),
    );
  }

  void _showSortMenu(BuildContext context, CardsProvider provider) {
    final button = context.findRenderObject() as RenderBox?;
    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    showMenu<CardSortOrder>(
      context: context,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      position: RelativeRect.fromRect(
        Rect.fromPoints(
          button?.localToGlobal(Offset.zero, ancestor: overlay) ??
              const Offset(0, 56),
          button?.localToGlobal(
                button.size.bottomRight(Offset.zero),
                ancestor: overlay,
              ) ??
              const Offset(200, 120),
        ),
        Offset.zero & overlay.size,
      ),
      items: [
        _sortItem(CardSortOrder.date, 'تاريخ الإضافة',
            Icons.calendar_today_outlined, provider),
        _sortItem(CardSortOrder.alphabetical, 'ترتيب أبجدي',
            Icons.sort_by_alpha, provider),
        _sortItem(CardSortOrder.length, 'طول النص', Icons.format_size,
            provider),
      ],
    ).then((picked) {
      if (picked != null) provider.setSortOrder(picked);
    });
  }

  PopupMenuItem<CardSortOrder> _sortItem(
    CardSortOrder value,
    String label,
    IconData icon,
    CardsProvider provider,
  ) {
    final isActive = provider.sortOrder == value;
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 18, color: isActive ? Colors.black : Colors.black45),
          const SizedBox(width: 12),
          Text(
            label,
            style: AppFonts.ibmStyle(
              fontSize: 14,
              color: isActive ? Colors.black : Colors.black87,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          if (isActive) ...[const Spacer(), const Icon(Icons.check, size: 16)],
        ],
      ),
    );
  }

  Future<void> _confirmDeleteSelected(
    BuildContext context,
    CardsProvider provider,
  ) async {
    final count = provider.selectedIds.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(
          'حذف البطاقات',
          style: AppFonts.ibmStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        content: Text(
          'هل أنت متأكد من حذف $count بطاقة؟',
          style: AppFonts.ibmStyle(fontSize: 14, color: Colors.black87),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('إلغاء',
                style: AppFonts.ibmStyle(color: Colors.black54)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade600),
            onPressed: () => Navigator.of(ctx).pop(true),
            child:
                Text('حذف', style: AppFonts.ibmStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await provider.deleteSelectedCards();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CardsProvider>();
    final inSelectionMode = provider.selectionMode;
    final selectedCount = provider.selectedIds.length;
    final categories = provider.categories;
    final desiredTabCount = 1 + categories.length;

    // Schedule a safe rebuild if tab count changed — never mutate during build
    _updateTabCount(desiredTabCount);

    final isSearching = provider.isSearching;
    final isFiltering = provider.isFiltering;

    // Always use _tabCount (the currently active controller's length)
    // so TabBar and TabBarView stay in sync with the live controller.
    final displayTabCount = _tabCount;
    final displayCategories = categories.take(displayTabCount - 1).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),

      // ── AppBar stays exactly the same in all modes ──────────────────────
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: TextField(
            controller: _searchController,
            textDirection: TextDirection.rtl,
            style: AppFonts.ibmStyle(fontSize: 14),
            decoration: InputDecoration(
              hintText: 'بحث في البطاقات...',
              hintStyle: AppFonts.ibmStyle(
                color: Colors.black38,
                fontSize: 14,
              ),
              prefixIcon: isSearching
                  ? IconButton(
                      icon: const Icon(
                        Icons.close,
                        size: 18,
                        color: Colors.black54,
                      ),
                      onPressed: () {
                        _searchController.clear();
                        provider.setSearch('');
                      },
                    )
                  : const Icon(Icons.search, size: 20, color: Colors.black38),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: const Color(0xFFF0F0F0),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 10,
                horizontal: 14,
              ),
              isDense: true,
            ),
            onChanged: provider.setSearch,
          ),
        ),
        actions: [
          // Sort button
          Builder(
            builder: (btnCtx) => IconButton(
              icon: Icon(
                Icons.swap_vert_rounded,
                color: provider.sortOrder != CardSortOrder.date
                    ? Colors.black
                    : Colors.black54,
              ),
              tooltip: 'ترتيب',
              onPressed: () => _showSortMenu(btnCtx, provider),
            ),
          ),
          // Filter button
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.filter_list_rounded,
                    color: isFiltering ? Colors.black : Colors.black54,
                  ),
                  onPressed: () => _openFilterSheet(context),
                  tooltip: 'فلترة حسب الوسوم',
                ),
                if (isFiltering)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.black,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelStyle: AppFonts.ibmStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          unselectedLabelStyle: AppFonts.ibmStyle(
            fontWeight: FontWeight.w400,
            fontSize: 13,
          ),
          labelColor: Colors.black,
          unselectedLabelColor: Colors.black45,
          indicatorColor: Colors.black,
          indicatorWeight: 2,
          dividerColor: Colors.black12,
          tabs: List.generate(displayTabCount, (i) {
            final label = i == 0
                ? 'الكل'
                : (i - 1 < displayCategories.length
                    ? displayCategories[i - 1].name
                    : '');
            final count = provider.matchCountForTab(i);
            final showBadge = (isSearching || isFiltering) && count > 0;

            return Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label),
                  if (showBadge) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$count',
                        style: AppFonts.ibmStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
        ),
      ),

      body: Stack(
        children: [
          TabBarView(
            controller: _tabController,
            children: List.generate(
              displayTabCount,
              (i) => CardListView(tabIndex: i),
            ),
          ),
          
          // ── Floating selection action bar (slides up from bottom) ───────────
          Align(
            alignment: Alignment.bottomCenter,
            child: AnimatedSlide(
              offset: inSelectionMode ? Offset.zero : const Offset(0, 1),
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              child: _SelectionBar(
                count: selectedCount,
                onCancel: provider.clearSelection,
                onDelete: () => _confirmDeleteSelected(context, provider),
              ),
            ),
          ),
        ],
      ),

      // ── FAB always at same position, hidden during selection ────────────
      floatingActionButton: AnimatedScale(
        scale: inSelectionMode ? 0.0 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        child: FloatingActionButton(
          onPressed: () => _openAddSheet(context),
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          elevation: 3,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}

// ─── Selection action bar ─────────────────────────────────────────────────────

class _SelectionBar extends StatelessWidget {
  final int count;
  final VoidCallback onCancel;
  final VoidCallback onDelete;

  const _SelectionBar({
    required this.count,
    required this.onCancel,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.black.withAlpha(18))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              // Cancel
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                color: Colors.black54,
                tooltip: 'إلغاء التحديد',
                onPressed: onCancel,
              ),

              const SizedBox(width: 8),

              // Count label
              Expanded(
                child: Text(
                  'تم تحديد $count بطاقة',
                  style: AppFonts.ibmStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ),

              // Delete button
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
                onPressed: count == 0 ? null : onDelete,
                icon: const Icon(Icons.delete_outline, size: 18),
                label: Text(
                  'حذف',
                  style: AppFonts.ibmStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
