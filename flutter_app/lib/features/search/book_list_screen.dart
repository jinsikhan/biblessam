import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/bible_book.dart';
import '../../services/bible_api_service.dart';

class BookListScreen extends StatefulWidget {
  const BookListScreen({super.key});

  @override
  State<BookListScreen> createState() => _BookListScreenState();
}

class _BookListScreenState extends State<BookListScreen> {
  List<BibleBook> _books = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final bible = context.read<BibleApiService>();
    final list = await bible.getBooks();
    if (!mounted) return;
    setState(() {
      _books = list;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ot = _books.where((b) => b.testament == 'OT').toList();
    final nt = _books.where((b) => b.testament == 'NT').toList();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('전체 목록'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _Section(title: '구약 (39권)', books: ot),
                const SizedBox(height: 16),
                _Section(title: '신약 (27권)', books: nt),
              ],
            ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<BibleBook> books;

  const _Section({required this.title, required this.books});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(title, style: Theme.of(context).textTheme.titleMedium),
        ),
        ...books.map((b) => ListTile(
              title: Text(b.nameKo),
              subtitle: Text(b.nameEn),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/books/${b.id}'),
            )),
      ],
    );
  }
}
