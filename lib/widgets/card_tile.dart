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
    final isQuran = card.type == CardType.quran;

    final bodyStyle = isQuran
        ? AppFonts.quranStyle(fontSize: 19, height: 1.8, color: Colors.black87)
        : AppFonts.ibmStyle(fontSize: 15, height: 1.6, color: Colors.black87);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          splashColor: Colors.black.withAlpha(18),
          highlightColor: Colors.black.withAlpha(10),
          onLongPress: () => _openEditSheet(context),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black.withAlpha(15)),
            ),
            padding: EdgeInsets.fromLTRB(16, isQuran ? 12 : 16, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Body
                Text(
                  card.body,
                  style: bodyStyle,
                  textDirection: TextDirection.rtl,
                  textHeightBehavior: isQuran
                      ? const TextHeightBehavior(
                          applyHeightToFirstAscent: false,
                        )
                      : null,
                ),

                if (card.tags.isNotEmpty) ...[
                  SizedBox(height: 12),
                  const Divider(height: 1, color: Colors.black12),
                  const SizedBox(height: 12),

                  // Tags
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
    );
  }
}
