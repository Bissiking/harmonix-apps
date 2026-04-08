import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../features/catalog/presentation/track_list_tile.dart';
import '../../../shared/widgets/async_value_widget.dart';
import '../data/search_repository.dart';

final _queryProvider = StateProvider<String>((ref) => '');

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(_queryProvider);
    final results = ref.watch(searchTracksProvider(query));

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: false,
          decoration: const InputDecoration(
            hintText: 'Rechercher une piste…',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.white38),
          ),
          style: const TextStyle(color: Colors.white),
          onChanged: (v) {
            Future.delayed(const Duration(milliseconds: 300), () {
              if (_controller.text == v) {
                ref.read(_queryProvider.notifier).state = v;
              }
            });
          },
        ),
        actions: [
          if (query.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _controller.clear();
                ref.read(_queryProvider.notifier).state = '';
              },
            ),
        ],
      ),
      body: query.isEmpty
          ? const Center(
              child: Text('Entrez un terme pour rechercher'),
            )
          : AsyncValueWidget(
              value: results,
              data: (tracks) => tracks.isEmpty
                  ? const Center(child: Text('Aucun résultat'))
                  : ListView.builder(
                      itemCount: tracks.length,
                      itemBuilder: (_, i) => TrackListTile(track: tracks[i]),
                    ),
            ),
    );
  }
}
