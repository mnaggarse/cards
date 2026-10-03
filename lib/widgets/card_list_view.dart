import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cards_provider.dart';
import '../theme/app_fonts.dart';
import 'card_tile.dart';

class CardListView extends StatelessWidget {
  final int tabIndex;

  const CardListView({super.key, required this.tabIndex});

  @override
  Widget build(BuildContext context) {
    final cards =
        context.watch<CardsProvider>().cardsForTab(tabIndex);

    if (cards.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.layers_outlined,
                size: 52, color: Colors.black.withAlpha(40)),
            const SizedBox(height: 16),
            Text(
              'لا توجد بطاقات',
              style: AppFonts.ibmStyle(
                fontSize: 15,
                color: Colors.black38,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 100),
      itemCount: cards.length,
      itemBuilder: (context, index) => CardTile(card: cards[index]),
    );
  }
}
