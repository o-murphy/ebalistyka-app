import 'package:ebalistyka/features/home/sub_screens/profiles/widgets/collection_item_tile.dart';
import 'package:flutter/material.dart';

class BaseCollectionBody extends StatefulWidget {
  const BaseCollectionBody({super.key, this.tiles = const []});

  final List<CollectionItemTile> tiles;

  @override
  State<BaseCollectionBody> createState() => _BaseCollectionBodyState();
}

class _BaseCollectionBodyState extends State<BaseCollectionBody> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: ListTile(
            trailing: IconButton(
              onPressed: () =>
                  debugPrint("Filter button (will call bottom toast)"),
              icon: Icon(Icons.filter_alt_outlined),
            ),
            title: TextField(
              decoration: InputDecoration(labelText: 'Search'),
              textCapitalization: TextCapitalization.words,
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 4, 16),
            child: Scrollbar(
              controller: _scrollController,
              thumbVisibility: true,
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.only(right: 12, bottom: 88),
                itemCount: widget.tiles.length,
                itemBuilder: (context, index) => widget.tiles[index],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
