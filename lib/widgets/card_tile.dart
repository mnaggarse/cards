import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/card_model.dart';
import '../providers/cards_provider.dart';
import '../theme/app_fonts.dart';
import 'add_card_sheet.dart';

class CardTile extends StatelessWidget {
  final CardModel card;

  const CardTile({super.key, required this.card});

  void _openEditSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<CardsProvider>(),
        child: AddCardSheet(existing: card),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CardsProvider>();
    final isSelected = provider.selectedIds.contains(card.id);
    final inSelectionMode = provider.selectionMode;

    final bodyStyle =
        AppFonts.ibmStyle(fontSize: 15, height: 1.6, color: Colors.black87);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Stack(
        children: [
          // ── Card body ────────────────────────────────────────────────────
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? Colors.black : Colors.black.withAlpha(15),
                width: isSelected ? 2 : 1,
              ),
              color: isSelected ? Colors.black.withAlpha(8) : Colors.white,
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                splashColor: Colors.black.withAlpha(18),
                highlightColor: Colors.black.withAlpha(10),
                onTap: () {
                  if (inSelectionMode) {
                    provider.toggleSelection(card.id!);
                  } else {
                    _openEditSheet(context);
                  }
                },
                onLongPress: () => provider.toggleSelection(card.id!),
                child: Padding(
                  // Add a bit of top padding so the overlay badge doesn't
                  // visually clash with the first line of text
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        card.body,
                        style: bodyStyle,
                        textDirection: TextDirection.rtl,
                      ),
                      if (card.tags.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        const Divider(height: 1, color: Colors.black12),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: card.tags
                              .map(
                                (tag) => Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.black12),
                                  ),
                                  child: Text(
                                    tag.name,
                                    style: AppFonts.ibmStyle(
                                      fontSize: 11,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Selection badge (overlay, no layout shift) ───────────────────
          if (inSelectionMode)
            Positioned(
              top: 10,
              left: 10,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? Colors.black : Colors.white,
                  border: Border.all(
                    color: isSelected ? Colors.black : Colors.black38,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(30),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: isSelected
                    ? const Icon(Icons.check, size: 13, color: Colors.white)
                    : null,
              ),
            ),
        ],
      ),
    );
  }
}
