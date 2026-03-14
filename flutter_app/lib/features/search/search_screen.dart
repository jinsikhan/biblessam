import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../services/bible_api_service.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  List<Map<String, dynamic>> _results = [];
  bool _searching = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final q = _controller.text.trim();
    if (q.isEmpty) {
      setState(() => _results = []);
      return;
    }
    setState(() => _searching = true);
    final bible = context.read<BibleApiService>();
    final list = await bible.search(q);
    if (!mounted) return;
    setState(() {
      _results = list;
      _searching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: TextField(
          controller: _controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '요한복음 3장, 시편 23...',
            border: InputBorder.none,
          ),
          onSubmitted: (_) => _search(),
        ),
        actions: [
          TextButton(onPressed: _search, child: const Text('검색')),
        ],
      ),
      body: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.list),
            title: const Text('전체 목록 (구약 + 신약)'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/books'),
          ),
          const Divider(height: 1),
          Expanded(
            child: _searching
                ? const Center(child: CircularProgressIndicator())
                : _results.isEmpty
                    ? Center(
                        child: Text(
                          _controller.text.trim().isEmpty
                              ? '참조를 입력하고 검색하세요'
                              : '검색 결과가 없어요',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      )
                    : ListView.builder(
                        itemCount: _results.length,
                        itemBuilder: (context, i) {
                          final r = _results[i];
                          final book = r['book'] as String? ?? '';
                          final chapter = r['chapter'] as int? ?? 1;
                          final reference = r['reference'] as String? ?? '$book $chapter';
                          final referenceKo = r['referenceKo'] as String? ?? reference;
                          return ListTile(
                            title: Text(referenceKo),
                            onTap: () {
                              context.pop();
                              context.push(
                                '/reader/${Uri.encodeComponent(book)}/$chapter?ref=${Uri.encodeComponent(referenceKo)}',
                              );
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
