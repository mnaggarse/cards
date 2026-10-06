import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/card_model.dart';
import '../models/tag.dart';
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

  // Autocomplete overlay
  List<String> _categorySuggestions = [];
  List<Tag> _tagSuggestions = [];
  bool _showCategorySuggestions = false;
  bool _showTagSuggestions = false;

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

  void _onCategoryChanged(String value, CardsProvider provider) {
    final q = value.trim().toLowerCase();
    if (q.isEmpty) {
      setState(() {
        _categorySuggestions = [];
        _showCategorySuggestions = false;
      });
      return;
    }
    final suggestions = provider.categories
        .where((c) => c.name.toLowerCase().contains(q))
        .map((c) => c.name)
        .toList();
    setState(() {
      _categorySuggestions = suggestions;
      _showCategorySuggestions = suggestions.isNotEmpty;
    });
  }

  void _onTagInputChanged(String value, CardsProvider provider) {
    final q = value.trim().toLowerCase();
    if (q.isEmpty) {
      setState(() {
        _tagSuggestions = [];
        _showTagSuggestions = false;
      });
      return;
    }
    final suggestions = provider.allTags
        .where(
          (t) =>
              t.name.toLowerCase().contains(q) &&
              !_selectedTags.contains(t.name),
        )
        .toList();
    setState(() {
      _tagSuggestions = suggestions;
      _showTagSuggestions = true;
    });
  }

  void _addTag(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty || _selectedTags.contains(trimmed)) {
      _tagInputController.clear();
      setState(() => _showTagSuggestions = false);
      return;
    }
    setState(() {
      _selectedTags.add(trimmed);
      _tagInputController.clear();
      _tagSuggestions = [];
      _showTagSuggestions = false;
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
                      _AutocompleteField(
                        controller: _categoryController,
                        hint: 'اختر تصنيفًا أو أنشئ جديدًا',
                        suggestions: _categorySuggestions,
                        showSuggestions: _showCategorySuggestions,
                        onChanged: (v) => _onCategoryChanged(v, provider),
                        onSuggestionTap: (s) {
                          _categoryController.text = s;
                          setState(() {
                            _categorySuggestions = [];
                            _showCategorySuggestions = false;
                          });
                        },
                        onDismiss: () =>
                            setState(() => _showCategorySuggestions = false),
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

                      _AutocompleteField(
                        controller: _tagInputController,
                        hint: 'ابحث عن وسم أو أضف جديدًا',
                        suggestions: _tagSuggestions
                            .map((t) => t.name)
                            .toList(),
                        showSuggestions: _showTagSuggestions,
                        onChanged: (v) => _onTagInputChanged(v, provider),
                        onSuggestionTap: (s) => _addTag(s),
                        onDismiss: () =>
                            setState(() => _showTagSuggestions = false),
                        onSubmitted: (v) => _addTag(v),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.add, size: 20),
                          onPressed: () => _addTag(_tagInputController.text),
                        ),
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

class _AutocompleteField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final List<String> suggestions;
  final bool showSuggestions;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSuggestionTap;
  final VoidCallback onDismiss;
  final ValueChanged<String>? onSubmitted;
  final Widget? suffixIcon;

  const _AutocompleteField({
    required this.controller,
    required this.hint,
    required this.suggestions,
    required this.showSuggestions,
    required this.onChanged,
    required this.onSuggestionTap,
    required this.onDismiss,
    this.onSubmitted,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: controller,
          textDirection: TextDirection.rtl,
          style: AppFonts.ibmStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppFonts.ibmStyle(color: Colors.black38),
            suffixIcon: suffixIcon,
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
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
          ),
          onChanged: onChanged,
          onSubmitted: onSubmitted,
        ),
        if (showSuggestions && suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 2),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.black12),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(15),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: suggestions
                  .map(
                    (s) => InkWell(
                      onTap: () => onSuggestionTap(s),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        child: Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: Text(
                            s,
                            style: AppFonts.ibmStyle(fontSize: 14),
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
      ],
    );
  }
}
