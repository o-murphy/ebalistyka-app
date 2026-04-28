import 'package:ebalistyka/features/home/sub_screens/widgets/collection_item_tile.dart';
import 'package:ebalistyka/l10n/app_localizations.dart';
import 'package:flutter/material.dart';

class BaseCollectionBody extends StatefulWidget {
  const BaseCollectionBody({super.key, this.tiles = const []});

  final List<CollectionItemTile> tiles;

  @override
  State<BaseCollectionBody> createState() => _BaseCollectionBodyState();
}

class _BaseCollectionBodyState extends State<BaseCollectionBody> {
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final filtered = _query.isEmpty
        ? widget.tiles
        : widget.tiles
              .where(
                (t) =>
                    t.searchText.toLowerCase().contains(_query.toLowerCase()),
              )
              .toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: ListTile(
            title: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: l10n.placeholderSearch,
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      )
                    : null,
              ),
              onChanged: (v) => setState(() => _query = v),
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
                itemCount: filtered.length,
                itemBuilder: (context, index) => filtered[index],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
