import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:formatic/core/theme/app_theme.dart';
import 'package:formatic/features/flashcards/controllers/flashcard_controller.dart';
import 'package:formatic/models/flashcards/flashcard.dart';

/// Study mode with flip animation for question and answer.
class FlashcardStudyView extends StatefulWidget {
  const FlashcardStudyView({
    super.key,
    required this.controller,
    required this.onExit,
  });

  final FlashcardController controller;
  final VoidCallback onExit;

  @override
  State<FlashcardStudyView> createState() => _FlashcardStudyViewState();
}

class _FlashcardStudyViewState extends State<FlashcardStudyView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flipController;
  late final Animation<double> _flipAnimation;
  bool _showAnswer = false;
  int _lastIndex = 0;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOut),
    );
    _lastIndex = widget.controller.currentCardIndex;
    widget.controller.addListener(_handleControllerChanges);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleControllerChanges);
    _flipController.dispose();
    super.dispose();
  }

  void _handleControllerChanges() {
    if (!mounted) return;
    if (!widget.controller.isStudyMode) {
      _resetFlip();
      return;
    }
    if (_lastIndex != widget.controller.currentCardIndex) {
      _lastIndex = widget.controller.currentCardIndex;
      _resetFlip();
    }
  }

  void _resetFlip() {
    _flipController.reset();
    setState(() => _showAnswer = false);
  }

  void _flipCard() {
    if (_flipController.status == AnimationStatus.completed) {
      _flipController.reverse();
    } else {
      _flipController.forward();
    }
    setState(() => _showAnswer = !_showAnswer);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Flashcard? currentCard = widget.controller.currentCard;

    if (currentCard == null) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [AppTheme.darkBackground, AppTheme.darkSurface]
              : [Colors.grey.shade50, Colors.white],
        ),
      ),
      child: Column(
        children: [
          _StudyHeader(
            controller: widget.controller,
            isDarkMode: isDark,
            onExit: () {
              widget.onExit();
              _resetFlip();
            },
          ),
          _ProgressBar(
            controller: widget.controller,
            color: AppTheme.primaryColor,
            isDarkMode: isDark,
          ),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: GestureDetector(
                  onTap: _flipCard,
                  child: AnimatedBuilder(
                    animation: _flipAnimation,
                    builder: (context, child) {
                      final angle = _flipAnimation.value * math.pi;
                      final isFront = angle < math.pi / 2;

                      return Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.001)
                          ..rotateY(angle),
                        child: Container(
                          constraints: const BoxConstraints(
                            maxWidth: 600,
                            maxHeight: 500,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor,
                            borderRadius: BorderRadius.circular(28),
                          ),
                          child: Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.identity()
                              ..rotateY(isFront ? 0 : math.pi),
                            child: Padding(
                              padding: const EdgeInsets.all(40),
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          isFront
                                              ? Icons.help_outline_rounded
                                              : Icons.lightbulb_outline_rounded,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          isFront ? 'PERGUNTA' : 'RESPOSTA',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 2,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 32),
                                  Expanded(
                                    child: Center(
                                      child: SingleChildScrollView(
                                        child: Text(
                                          isFront
                                              ? currentCard.question
                                              : currentCard.answer,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 26,
                                            fontWeight: FontWeight.w600,
                                            height: 1.5,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 32),
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      isFront
                                          ? Icons.psychology_rounded
                                          : Icons.check_circle_rounded,
                                      color: Colors.white,
                                      size: 40,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          _StudyControls(
            onPrevious: widget.controller.previousCard,
            onFlip: _flipCard,
            onNext: widget.controller.nextCard,
            color: AppTheme.primaryColor,
          ),
        ],
      ),
    );
  }
}

class _StudyHeader extends StatelessWidget {
  const _StudyHeader({
    required this.controller,
    required this.isDarkMode,
    required this.onExit,
  });

  final FlashcardController controller;
  final bool isDarkMode;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: BoxDecoration(
        color: isDarkMode
            ? AppTheme.darkBackground.withOpacity(0.6)
            : Colors.white.withOpacity(0.9),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            IconButton(
              onPressed: onExit,
              icon: Icon(
                Icons.arrow_back_rounded,
                color: isDarkMode ? Colors.white : Colors.black87,
              ),
              style: IconButton.styleFrom(
                backgroundColor: isDarkMode
                    ? Colors.white.withOpacity(0.1)
                    : Colors.grey.withOpacity(0.1),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Modo Estudo',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Card ${controller.currentCardIndex + 1} de ${controller.flashcards.length}',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDarkMode ? Colors.white60 : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${(((controller.currentCardIndex + 1) / controller.flashcards.length) * 100).toStringAsFixed(0)}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({
    required this.controller,
    required this.color,
    required this.isDarkMode,
  });

  final FlashcardController controller;
  final Color color;
  final bool isDarkMode;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 4,
      color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: controller.flashcards.isEmpty
            ? 0
            : (controller.currentCardIndex + 1) / controller.flashcards.length,
        child: Container(color: color),
      ),
    );
  }
}

class _StudyControls extends StatelessWidget {
  const _StudyControls({
    required this.onPrevious,
    required this.onFlip,
    required this.onNext,
    required this.color,
  });

  final VoidCallback onPrevious;
  final VoidCallback onFlip;
  final VoidCallback onNext;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppTheme.darkBackground.withOpacity(0.6)
            : Colors.white.withOpacity(0.9),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Container(
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: IconButton(
                onPressed: onPrevious,
                icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                iconSize: 28,
                padding: const EdgeInsets.all(16),
              ),
            ),
            ElevatedButton.icon(
              onPressed: onFlip,
              icon: const Icon(Icons.flip_rounded, color: Colors.white),
              label: const Text(
                'Virar Card',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: IconButton(
                onPressed: onNext,
                icon: const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                ),
                iconSize: 28,
                padding: const EdgeInsets.all(16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
