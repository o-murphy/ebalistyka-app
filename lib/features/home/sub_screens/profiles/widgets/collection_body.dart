import 'package:ebalistyka/features/home/sub_screens/profiles/widgets/collection_item_tile.dart';
import 'package:flutter/material.dart';

class BaseCollectionBody extends StatelessWidget {
  const BaseCollectionBody({super.key, this.tiles = const [], this.bottom});

  final List<CollectionItemTile> tiles;
  final Widget? bottom;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ListTile(
            trailing: IconButton(
              onPressed: () =>
                  debugPrint("Filter button (will call bottom toast)"),
              icon: Icon(Icons.filter_alt_outlined),
            ),
            title: TextField(
              // controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: 'Search',
                // errorText: _nameError,
              ),
              textCapitalization: TextCapitalization.words,
              // onChanged: (_) => setState(() {
              //   _nameError = null;
              // }),
              // onEditingComplete: _validateName,
            ),
          ),
          Expanded(
            // Додаємо Expanded, щоб ListView зайняв доступний простір
            child: ListView.builder(
              itemCount: tiles.length,
              itemBuilder: (context, index) => tiles[index],
            ),
          ),
          if (bottom != null)
            Padding(padding: const EdgeInsets.only(top: 8), child: bottom),
        ],
      ),
    );
  }
}
