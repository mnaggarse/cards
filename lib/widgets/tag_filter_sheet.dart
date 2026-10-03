import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/tag.dart';
import '../providers/cards_provider.dart';
import '../theme/app_fonts.dart';

class TagFilterSheet extends StatefulWidget {
  const TagFilterSheet({super.key});

  @override
  State<TagFilterSheet> createState() => _TagFilterSheetState();
}

class _TagFilterSheetState extends State<TagFilterSheet> {
  late Set<int> _selected;

  @override
  void initState() {
    super.initState();
    _selected = Set.of(context.read<CardsProvider>().selectedTagIds);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CardsProvider>();
    final tags = provider.allTags;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.only(top: 12, bottom: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Title row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text(
                  'فلترة حسب الوسوم',
                  style: AppFonts.ibmStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const Spacer(),
                // Always reserve space; only show when tags are selected
                Visibility(
                  visible: _selected.isNotEmpty,
                  maintainSize: true,
                  maintainAnimation: true,
                  maintainState: true,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () => setState(() => _selected.clear()),
                    child: Text(
                      'مسح الكل',
                      style: AppFonts.ibmStyle(
                        color: Colors.black54,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),

          if (tags.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'لا توجد وسوم بعد',
                style: AppFonts.ibmStyle(color: Colors.black45),
              ),
            )
          else
            Material(
              color: Colors.white,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.45,
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: tags.length,
                  itemBuilder: (context, i) {
                    final tag = tags[i];
                    final selected = _selected.contains(tag.id!);
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                      ),
                      title: Text(
                        tag.name,
                        style: AppFonts.ibmStyle(fontSize: 14),
                      ),
                      trailing: Checkbox(
                        value: selected,
                        activeColor: Colors.black,
                        checkColor: Colors.white,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: const VisualDensity(
                          horizontal: VisualDensity.minimumDensity,
                          vertical: VisualDensity.minimumDensity,
                        ),
                        onChanged: (val) {
                          setState(() {
                            if (val == true) {
                              _selected.add(tag.id!);
                            } else {
                              _selected.remove(tag.id!);
                            }
                          });
                        },
                      ),
                      onTap: () {
                        setState(() {
                          if (selected) {
                            _selected.remove(tag.id!);
                          } else {
                            _selected.add(tag.id!);
                          }
                        });
                      },
                      onLongPress: () => _showEditTagDialog(tag),
                    );
                  },
                ),
              ),
            ),

          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () {
                  context.read<CardsProvider>().setTagFilter(_selected);
                  Navigator.of(context).pop();
                },
                child: Text(
                  'تطبيق',
                  style: AppFonts.ibmStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditTagDialog(Tag tag) async {
    final controller = TextEditingController(text: tag.name);
    controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: tag.name.length,
    );
    String? errorMessage;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> submit() async {
              final newName = controller.text.trim();
              if (newName.isEmpty) {
                setDialogState(() {
                  errorMessage = 'اسم الوسم لا يمكن أن يكون فارغاً';
                });
                return;
              }
              if (newName == tag.name) {
                Navigator.of(dialogContext).pop();
                return;
              }

              final success = await context.read<CardsProvider>().updateTag(
                tag.id!,
                newName,
              );

              if (!success) {
                setDialogState(() {
                  errorMessage = 'هذا الوسم موجود بالفعل';
                });
                return;
              }

              if (dialogContext.mounted) {
                Navigator.of(dialogContext).pop();
              }
            }

            return AlertDialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                'تعديل اسم الوسم',
                textDirection: TextDirection.rtl,
                style: AppFonts.ibmStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: controller,
                    autofocus: true,
                    textDirection: TextDirection.rtl,
                    style: AppFonts.ibmStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'اسم الوسم الجديد...',
                      hintStyle: AppFonts.ibmStyle(
                        color: Colors.black38,
                        fontSize: 14,
                      ),
                      errorText: errorMessage,
                      errorStyle: AppFonts.ibmStyle(
                        fontSize: 12,
                        color: Colors.red,
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
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: (_) => submit(),
                    onChanged: (_) {
                      if (errorMessage != null) {
                        setDialogState(() => errorMessage = null);
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(
                    'إلغاء',
                    style: AppFonts.ibmStyle(
                      color: Colors.black54,
                      fontSize: 14,
                    ),
                  ),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: Colors.black),
                  onPressed: submit,
                  child: Text(
                    'حفظ',
                    style: AppFonts.ibmStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
