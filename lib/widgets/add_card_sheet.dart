import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/card_model.dart';
import '../providers/cards_provider.dart';
import '../theme/app_fonts.dart';

class AddCardSheet extends StatefulWidget {
  final CardModel? existing;

  const AddCardSheet({super.key, this.existing});

  @override
  State<AddCardSheet> createState() => _AddCardSheetState();
}

class _AddCardSheetState extends State<AddCardSheet> {
  final _bodyController = TextEditingController();
  final _categoryController = TextEditingController();
  final _tagInputController = TextEditingController();
  final _bodyFocusNode = FocusNode();

  List<String> _selectedTags = [];
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _bodyController.text = existing.body;
      _selectedTags = existing.tags.map((t) => t.name).toList();

      // Find category name
      final provider = context.read<CardsProvider>();
      if (existing.categoryId != null) {
        final cat = provider.categories
            .where((c) => c.id == existing.categoryId)
            .firstOrNull;
        if (cat != null) _categoryController.text = cat.name;
      }
    }
  }

  @override
  void dispose() {
    _bodyController.dispose();
    _categoryController.dispose();
    _tagInputController.dispose();
    _bodyFocusNode.dispose();
    super.dispose();
  }

  void _addTag(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty || _selectedTags.contains(trimmed)) {
      _tagInputController.clear();
      return;
    }
    setState(() {
      _selectedTags.add(trimmed);
      _tagInputController.clear();
    });
  }

  void _removeTag(String name) {
    setState(() => _selectedTags.remove(name));
  }

  Future<void> _confirmDelete(BuildContext context) async {
    // Capture before any async gap
    final provider = context.read<CardsProvider>();
    final nav = Navigator.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(
          'حذف البطاقة',
          style: AppFonts.ibmStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        content: Text(
          'هل أنت متأكد من حذف هذه البطاقة؟',
          style: AppFonts.ibmStyle(
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'إلغاء',
              style: AppFonts.ibmStyle(color: Colors.black54),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade600),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'حذف',
              style: AppFonts.ibmStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await provider.deleteCard(widget.existing!.id!);
      nav.pop();
    }
  }

  Future<void> _save() async {
    final body = _bodyController.text.trim();
    if (body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'أدخل نص البطاقة',
            style: AppFonts.ibmStyle(),
          ),
          backgroundColor: Colors.black,
        ),
      );
      return;
    }

    setState(() => _saving = true);
    final provider = context.read<CardsProvider>();
    final categoryName = _categoryController.text.trim().isEmpty
        ? null
        : _categoryController.text.trim();

    if (widget.existing == null) {
      await provider.addCard(
        body: body,
        type: CardType.normal,
        categoryName: categoryName,
        tagNames: _selectedTags,
      );
    } else {
      await provider.updateCard(
        id: widget.existing!.id!,
        body: body,
        type: CardType.normal,
        categoryName: categoryName,
        tagNames: _selectedTags,
      );
    }

    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CardsProvider>();
    final bodyFont = AppFonts.ibmStyle(fontSize: 15, height: 1.6);
    final availableCategories = provider.categories.map((c) => c.name).toList();
    final availableTags = provider.allTags
        .where((t) => !_selectedTags.contains(t.name))
        .map((t) => t.name)
        .toList();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 8),
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Sheet title
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 4,
                ),
                child: Row(
                  children: [
                    Text(
                      widget.existing == null ? 'بطاقة جديدة' : 'تعديل البطاقة',
                      style: AppFonts.ibmStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    if (widget.existing != null)
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                        ),
                        onPressed: () => _confirmDelete(context),
                      ),
                  ],
                ),
              ),
              const Divider(height: 1),

              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Body field
                      _SectionLabel(label: 'نص البطاقة'),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _bodyController,
                        focusNode: _bodyFocusNode,
                        maxLines: null,
                        minLines: 4,
                        textDirection: TextDirection.rtl,
                        style: bodyFont,
                        decoration: InputDecoration(
                          hintText: 'اكتب نص البطاقة...',
                          hintStyle: AppFonts.ibmStyle(
                            color: Colors.black38,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Colors.black12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Colors.black12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Colors.black),
                          ),
                          contentPadding: const EdgeInsets.all(14),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Category field
                      _SectionLabel(label: 'التصنيف'),
                      const SizedBox(height: 8),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          return DropdownMenu<String>(
                            controller: _categoryController,
                            width: constraints.maxWidth,
                            enableFilter: true,
                            requestFocusOnTap: true,
                            hintText: 'اختر تصنيفًا أو أنشئ جديدًا',
                            textStyle: AppFonts.ibmStyle(fontSize: 14),
                            inputDecorationTheme: InputDecorationTheme(
                              hintStyle: AppFonts.ibmStyle(color: Colors.black38),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: Colors.black12),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: Colors.black12),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: Colors.black),
                              ),
                            ),
                            menuStyle: MenuStyle(
                              backgroundColor: const WidgetStatePropertyAll(Colors.white),
                              surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
                              shape: WidgetStatePropertyAll(
                                RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  side: const BorderSide(color: Colors.black12),
                                ),
                              ),
                            ),
                            dropdownMenuEntries: availableCategories
                                .map(
                                  (category) => DropdownMenuEntry<String>(
                                    value: category,
                                    label: category,
                                    style: MenuItemButton.styleFrom(
                                      textStyle: AppFonts.ibmStyle(fontSize: 14),
                                    ),
                                  ),
                                )
                                .toList(),
                            onSelected: (val) {
                              if (val != null) {
                                _categoryController.text = val;
                              }
                            },
                          );
                        },
                      ),

                      const SizedBox(height: 20),

                      // Tags field
                      _SectionLabel(label: 'الوسوم'),
                      const SizedBox(height: 8),

                      // Selected tag chips
                      if (_selectedTags.isNotEmpty) ...[
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: _selectedTags
                              .map(
                                (tag) => Chip(
                                  label: Text(
                                    tag,
                                    style: AppFonts.ibmStyle(
                                      fontSize: 12,
                                    ),
                                  ),
                                  backgroundColor: Colors.black,
                                  labelStyle: const TextStyle(
                                    color: Colors.white,
                                  ),
                                  deleteIconColor: Colors.white70,
                                  onDeleted: () => _removeTag(tag),
                                  materialTapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 4,
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                        const SizedBox(height: 8),
                      ],

                      LayoutBuilder(
                        builder: (context, constraints) {
                          return Row(
                            children: [
                              Expanded(
                                child: DropdownMenu<String>(
                                  controller: _tagInputController,
                                  width: constraints.maxWidth - 48,
                                  enableFilter: true,
                                  requestFocusOnTap: true,
                                  hintText: 'ابحث عن وسم أو أضف جديدًا',
                                  textStyle: AppFonts.ibmStyle(fontSize: 14),
                                  inputDecorationTheme: InputDecorationTheme(
                                    hintStyle: AppFonts.ibmStyle(color: Colors.black38),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 12,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(color: Colors.black12),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(color: Colors.black12),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: const BorderSide(color: Colors.black),
                                    ),
                                  ),
                                  menuStyle: MenuStyle(
                                    backgroundColor: const WidgetStatePropertyAll(Colors.white),
                                    surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
                                    shape: WidgetStatePropertyAll(
                                      RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        side: const BorderSide(color: Colors.black12),
                                      ),
                                    ),
                                  ),
                                  dropdownMenuEntries: availableTags
                                      .map(
                                        (tag) => DropdownMenuEntry<String>(
                                          value: tag,
                                          label: tag,
                                          style: MenuItemButton.styleFrom(
                                            textStyle: AppFonts.ibmStyle(fontSize: 14),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onSelected: (val) {
                                    if (val != null && val.isNotEmpty) {
                                      _addTag(val);
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton.filled(
                                style: IconButton.styleFrom(
                                  backgroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                icon: const Icon(Icons.add, color: Colors.white, size: 20),
                                onPressed: () => _addTag(_tagInputController.text),
                              ),
                            ],
                          );
                        },
                      ),

                      const SizedBox(height: 32),

                      // Save button
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onPressed: _saving ? null : _save,
                          child: _saving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  widget.existing == null ? 'حفظ' : 'تحديث',
                                  style: AppFonts.ibmStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                        ),
                      ),
                    ],
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

// ─── Helper widgets ───────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: AppFonts.ibmStyle(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: Colors.black54,
    ),
  );
}
