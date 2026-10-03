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

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CardsProvider>();
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
            final label = i == 0 ? 'الكل' : displayCategories[i - 1].name;
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
      body: TabBarView(
        controller: _tabController,
        children: List.generate(
          displayTabCount,
          (i) => CardListView(tabIndex: i),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openAddSheet(context),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 3,
        child: const Icon(Icons.add),
      ),
    );
  }
}
