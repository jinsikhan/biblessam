import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/bible_book.dart';
import '../../services/bible_api_service.dart';

class ChapterListScreen extends StatefulWidget {
  final String bookId;

  const ChapterListScreen({super.key, required this.bookId});

  @override
  State<ChapterListScreen> createState() => _ChapterListScreenState();
}

class _ChapterListScreenState extends State<ChapterListScreen> {
  BibleBook? _book;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final bible = context.read<BibleApiService>();
    final books = await bible.getBooks();
    if (!mounted) return;
    BibleBook? b;
    for (final x in books) {
      if (x.id == widget.bookId) {
        b = x;
        break;
      }
    }
    setState(() {
      _book = b;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop())),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_book == null) {
      return Scaffold(
        appBar: AppBar(leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop())),
        body: const Center(child: Text('책을 찾을 수 없어요')),
      );
    }

    final book = _book!;
    final chapters = List.generate(book.chapters, (i) => i + 1);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(book.nameKo),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 5,
          childAspectRatio: 1.2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
        ),
        itemCount: chapters.length,
        itemBuilder: (context, i) {
          final ch = chapters[i];
          return Material(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                context.pop();
                context.push(
                  '/reader/${Uri.encodeComponent(book.apiBookName)}/$ch?ref=${Uri.encodeComponent('${book.nameKo} $ch')}',
                );
              },
              child: Center(
                child: Text(
                  '$ch',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
