import 'package:flutter/foundation.dart';
import 'package:formatic/models/flashcards/flashcard.dart';
import 'package:formatic/services/auth/auth_service.dart';
import 'package:formatic/services/flashcards/flashcard_service.dart';

/// Handles flashcard business rules and exposes UI state.
class FlashcardController extends ChangeNotifier {
  FlashcardController({
    required AuthService authService,
    required FlashcardService flashcardService,
  }) : _authService = authService,
       _flashcardService = flashcardService;

  final AuthService _authService;
  final FlashcardService _flashcardService;

  List<Flashcard> _flashcards = [];
  bool _isLoading = false;
  bool _isStudyMode = false;
  int _currentCardIndex = 0;
  String _searchQuery = '';

  bool get isLoading => _isLoading;
  bool get isStudyMode => _isStudyMode;
  int get currentCardIndex => _currentCardIndex;
  String get searchQuery => _searchQuery;
  List<Flashcard> get flashcards => List.unmodifiable(_flashcards);

  List<Flashcard> get filteredFlashcards {
    if (_searchQuery.isEmpty) {
      return flashcards;
    }
    final query = _searchQuery.toLowerCase();
    return _flashcards
        .where((card) {
          return card.question.toLowerCase().contains(query) ||
              card.answer.toLowerCase().contains(query);
        })
        .toList(growable: false);
  }

  Flashcard? get currentCard =>
      _flashcards.isEmpty ? null : _flashcards[_currentCardIndex];

  Future<void> loadFlashcards() async {
    _setLoading(true);
    try {
      final user = _authService.currentUser;
      if (user == null) {
        throw StateError('Usuário não autenticado');
      }
      final cards = await _flashcardService.getUserFlashcards(user.id);
      _flashcards = cards;
      if (_flashcards.isEmpty) {
        _currentCardIndex = 0;
        _isStudyMode = false;
      } else if (_currentCardIndex >= _flashcards.length) {
        _currentCardIndex = 0;
      }
    } finally {
      _setLoading(false);
    }
  }

  Future<void> createFlashcard({
    required String question,
    required String answer,
  }) async {
    final user = _authService.currentUser;
    if (user == null) {
      throw StateError('Usuário não autenticado');
    }

    await _flashcardService.createFlashcard(
      userId: user.id,
      question: question,
      answer: answer,
    );
    await loadFlashcards();
  }

  Future<void> updateFlashcard(Flashcard flashcard) async {
    await _flashcardService.updateFlashcard(flashcard);
    await loadFlashcards();
  }

  Future<void> deleteFlashcard(Flashcard flashcard) async {
    await _flashcardService.deleteFlashcard(flashcard.id.toString());
    await loadFlashcards();
  }

  void setSearchQuery(String value) {
    _searchQuery = value.trim();
    notifyListeners();
  }

  void resetSearch() {
    if (_searchQuery.isEmpty) return;
    _searchQuery = '';
    notifyListeners();
  }

  void enterStudyMode() {
    if (_flashcards.isEmpty) return;
    _isStudyMode = true;
    _currentCardIndex = 0;
    notifyListeners();
  }

  void exitStudyMode() {
    if (!_isStudyMode) return;
    _isStudyMode = false;
    notifyListeners();
  }

  void nextCard() {
    if (_flashcards.isEmpty) return;
    _currentCardIndex = (_currentCardIndex + 1) % _flashcards.length;
    notifyListeners();
  }

  void previousCard() {
    if (_flashcards.isEmpty) return;
    _currentCardIndex =
        (_currentCardIndex - 1 + _flashcards.length) % _flashcards.length;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
