import 'package:flutter/material.dart';
import 'package:formatic/core/theme/app_theme.dart';
import 'package:formatic/core/utils/snackbar_utils.dart';
import 'package:formatic/features/flashcards/controllers/flashcard_controller.dart';
import 'package:formatic/features/flashcards/widgets/flashcard_bottom_bar.dart';
import 'package:formatic/features/flashcards/widgets/flashcard_dialogs.dart';
import 'package:formatic/features/flashcards/widgets/flashcard_list_view.dart';
import 'package:formatic/features/flashcards/widgets/flashcard_study_view.dart';
import 'package:formatic/models/flashcards/flashcard.dart';
import 'package:formatic/services/auth/auth_service.dart';
import 'package:formatic/services/flashcards/flashcard_service.dart';

/// Feature page responsible for orchestrating flashcard UI states.
class FlashcardPage extends StatefulWidget {
  const FlashcardPage({
    super.key,
    required this.isDarkMode,
    required this.onThemeToggle,
  });

  final bool isDarkMode;
  final VoidCallback onThemeToggle;

  @override
  State<FlashcardPage> createState() => _FlashcardPageState();
}

class _FlashcardPageState extends State<FlashcardPage> {
  late final FlashcardController _controller;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = FlashcardController(
      authService: AuthService(),
      flashcardService: FlashcardService(),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadFlashcards());
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFlashcards() async {
    try {
      await _controller.loadFlashcards();
    } catch (error) {
      if (!mounted) return;
      SnackbarUtils.showError(context, 'Erro ao carregar flashcards: $error');
    }
  }

  Future<void> _createFlashcard() async {
    final result = await showFlashcardFormDialog(
      context: context,
      isDarkMode: widget.isDarkMode,
    );

    if (result == null) return;

    try {
      await _controller.createFlashcard(
        question: result.question,
        answer: result.answer,
      );
      if (!mounted) return;
      SnackbarUtils.showSuccess(context, 'Flashcard criado com sucesso!');
    } catch (error) {
      if (!mounted) return;
      SnackbarUtils.showError(context, 'Erro ao adicionar flashcard: $error');
    }
  }

  Future<void> _editFlashcard(Flashcard flashcard) async {
    final result = await showFlashcardFormDialog(
      context: context,
      isDarkMode: widget.isDarkMode,
      flashcard: flashcard,
    );

    if (result == null) return;

    try {
      await _controller.updateFlashcard(
        Flashcard(
          id: flashcard.id,
          userId: flashcard.userId,
          question: result.question,
          answer: result.answer,
          createdAt: flashcard.createdAt,
        ),
      );
      if (!mounted) return;
      SnackbarUtils.showSuccess(context, 'Flashcard atualizado com sucesso!');
    } catch (error) {
      if (!mounted) return;
      SnackbarUtils.showError(context, 'Erro ao atualizar flashcard: $error');
    }
  }

  Future<void> _deleteFlashcard(Flashcard flashcard) async {
    final confirmed = await showFlashcardDeleteDialog(
      context: context,
      flashcard: flashcard,
      isDarkMode: widget.isDarkMode,
    );
    if (!confirmed) return;

    try {
      await _controller.deleteFlashcard(flashcard);
      if (!mounted) return;
      SnackbarUtils.showSuccess(context, 'Flashcard deletado com sucesso!');
    } catch (error) {
      if (!mounted) return;
      SnackbarUtils.showError(context, 'Erro ao deletar flashcard: $error');
    }
  }

  void _toggleStudyMode() {
    if (_controller.isStudyMode) {
      _controller.exitStudyMode();
    } else {
      _controller.enterStudyMode();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: widget.isDarkMode
              ? AppTheme.darkBackground
              : Colors.white,
          body: _controller.isLoading
              ? const Center(child: CircularProgressIndicator())
              : Stack(
                  children: [
                    if (_controller.isStudyMode)
                      FlashcardStudyView(
                        controller: _controller,
                        onExit: _controller.exitStudyMode,
                      )
                    else
                      FlashcardListView(
                        controller: _controller,
                        searchController: _searchController,
                        onSearchChanged: _controller.setSearchQuery,
                        onRefresh: _loadFlashcards,
                        onCreate: _createFlashcard,
                        onEdit: _editFlashcard,
                        onDelete: _deleteFlashcard,
                      ),
                    if (!_controller.isStudyMode &&
                        _controller.flashcards.isNotEmpty)
                      FlashcardBottomBar(
                        onStudy: _toggleStudyMode,
                        onCreate: _createFlashcard,
                        isStudyDisabled: _controller.flashcards.isEmpty,
                      ),
                  ],
                ),
        );
      },
    );
  }
}
