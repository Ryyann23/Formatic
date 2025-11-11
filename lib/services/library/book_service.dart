import 'package:formatic/models/library/book.dart';

class BookService {
  // Lista de livros de exemplo (depois pode ser substituída por dados do Supabase)
  static final List<Book> _sampleBooks = [
    Book(
      id: '1',
      title: 'Cálculo - Volume 1',
      author: 'James Stewart',
      description: 'Livro de cálculo.',
      pdfPath: 'assets/pdfs/calculo.pdf',
      coverImageUrl: 'assets/images/livros/calculo.png',
      tags: [
        BookTags.matematica,
        BookTags.cienciasExatas,
        BookTags.livroTexto,
        BookTags.introducao,
      ],
      addedDate: DateTime.now().subtract(const Duration(days: 30)),
      pageCount: 661,
    ),
    Book(
      id: '3',
      title: 'Manual de Medicina de Emergência',
      author: 'FMUSP',
      description: 'Manual de medicina de emergência da FMUSP',
      pdfPath: 'assets/pdfs/manual_med.pdf',
      coverImageUrl: 'assets/images/livros/manual_med.png',
      tags: [BookTags.medicina, BookTags.intermediario],
      addedDate: DateTime.now().subtract(const Duration(days: 20)),
      pageCount: 1513,
    ),
    Book(
      id: '4',
      title: 'Neuropsicologia geriátrica, neuropsiquiatria cognitiva em idosos',
      author: 'Leonardo Caixeta e Antonio Lucio Teixeira',
      description:
          'Neuropsicologia geriátrica, neuropsiquiatria cognitiva em idosos',
      pdfPath: 'assets/pdfs/neuropsicologia.pdf',
      coverImageUrl: 'assets/images/livros/neuropsicologia.png',
      tags: [BookTags.psicologia, BookTags.livroTexto, BookTags.intermediario],
      addedDate: DateTime.now().subtract(const Duration(days: 18)),
      pageCount: 364,
    ),
    Book(
      id: '5',
      title: 'Introdução à Biologia Celular',
      author: 'Estácio',
      description: 'Fundamentos da biologia celular e molecular',
      pdfPath: 'assets/pdfs/biologia.pdf',
      coverImageUrl: 'assets/images/livros/biologia.png',
      tags: [
        BookTags.biologia,
        BookTags.cienciasBiologicas,
        BookTags.livroTexto,
        BookTags.introducao,
      ],
      addedDate: DateTime.now().subtract(const Duration(days: 15)),
      pageCount: 193,
    ),
    Book(
      id: '6',
      title: 'Bioquímica Básica',
      author: 'Juliana Hori',
      description: 'Fundamentos da bioquímica',
      pdfPath: 'assets/pdfs/bioquimica.pdf',
      coverImageUrl: 'assets/images/livros/bioquimica.png',
      tags: [
        BookTags.quimica,
        BookTags.cienciasBiologicas,
        BookTags.livroTexto,
        BookTags.introducao,
      ],
      addedDate: DateTime.now().subtract(const Duration(days: 12)),
      pageCount: 138,
    ),
    Book(
      id: '7',
      title: 'Princípios de Administração e Suas Tendências',
      author: 'Auristela Correa Castro',
      description: 'Princípios de Administração e Suas Tendências',
      pdfPath: 'assets/pdfs/adm.pdf',
      coverImageUrl: 'assets/images/livros/adm.png',
      tags: [
        BookTags.administracao,
        BookTags.cienciasExatas,
        BookTags.livroTexto,
        BookTags.introducao,
      ],
      addedDate: DateTime.now().subtract(const Duration(days: 10)),
      pageCount: 218,
    ),
  ];

  // Buscar todos os livros
  Future<List<Book>> getAllBooks() async {
    // Simula delay de rede
    await Future.delayed(const Duration(milliseconds: 500));
    return _sampleBooks;
  }

  // Buscar livros por texto (título, autor, descrição)
  Future<List<Book>> searchBooks(String query) async {
    await Future.delayed(const Duration(milliseconds: 300));

    if (query.isEmpty) {
      return _sampleBooks;
    }

    final lowerQuery = query.toLowerCase();
    return _sampleBooks.where((book) {
      return book.title.toLowerCase().contains(lowerQuery) ||
          book.author.toLowerCase().contains(lowerQuery) ||
          book.description.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  // Filtrar livros por tags
  Future<List<Book>> filterByTags(List<String> selectedTags) async {
    await Future.delayed(const Duration(milliseconds: 300));

    if (selectedTags.isEmpty) {
      return _sampleBooks;
    }

    return _sampleBooks.where((book) {
      // Verifica se o livro tem pelo menos uma das tags selecionadas
      return book.tags.any((tag) => selectedTags.contains(tag));
    }).toList();
  }

  // Buscar e filtrar combinados
  Future<List<Book>> searchAndFilter(
    String query,
    List<String> selectedTags,
  ) async {
    await Future.delayed(const Duration(milliseconds: 300));

    List<Book> results = _sampleBooks;

    // Aplicar busca por texto
    if (query.isNotEmpty) {
      final lowerQuery = query.toLowerCase();
      results = results.where((book) {
        return book.title.toLowerCase().contains(lowerQuery) ||
            book.author.toLowerCase().contains(lowerQuery) ||
            book.description.toLowerCase().contains(lowerQuery);
      }).toList();
    }

    // Aplicar filtro de tags
    if (selectedTags.isNotEmpty) {
      results = results.where((book) {
        return book.tags.any((tag) => selectedTags.contains(tag));
      }).toList();
    }

    return results;
  }

  // Buscar livro por ID
  Future<Book?> getBookById(String id) async {
    await Future.delayed(const Duration(milliseconds: 200));

    try {
      return _sampleBooks.firstWhere((book) => book.id == id);
    } catch (e) {
      return null;
    }
  }

  // Obter livros recentes
  Future<List<Book>> getRecentBooks({int limit = 5}) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final sortedBooks = List<Book>.from(_sampleBooks);
    sortedBooks.sort((a, b) => b.addedDate.compareTo(a.addedDate));

    return sortedBooks.take(limit).toList();
  }
}
