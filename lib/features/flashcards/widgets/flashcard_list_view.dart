import 'package:flutter/material.dart';
import 'package:formatic/core/theme/app_theme.dart';
import 'package:formatic/features/flashcards/controllers/flashcard_controller.dart';
import 'package:formatic/features/flashcards/widgets/flashcard_empty_state.dart';
import 'package:formatic/models/flashcards/flashcard.dart';

/// Displays user flashcards with search and filtering controls.
class FlashcardListView extends StatelessWidget {
  const FlashcardListView({
    super.key,
    required this.controller,
    required this.searchController,
    required this.onSearchChanged,
    required this.onRefresh,
    required this.onCreate,
    required this.onEdit,
    required this.onDelete,
  });

  final FlashcardController controller;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final Future<void> Function() onRefresh;
  final VoidCallback onCreate;
  final ValueChanged<Flashcard> onEdit;
  final ValueChanged<Flashcard> onDelete;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filtered = controller.filteredFlashcards;

    if (controller.flashcards.isEmpty) {
      return FlashcardEmptyState(isDarkMode: isDark, onCreate: onCreate);
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? const [AppTheme.darkBackground, AppTheme.darkSurface]
              : const [Color(0xFFF6F2FF), Colors.white],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: _SearchField(
              controller: searchController,
              onSearchChanged: onSearchChanged,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Meus flashcards',
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Total de ${filtered.length} ${filtered.length == 1 ? "card disponível" : "cards disponíveis"}',
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black54,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: onRefresh,
              color: AppTheme.primaryColor,
              child: filtered.isEmpty
                  ? _EmptySearchState(isDark: isDark)
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final flashcard = filtered[index];
                        return _FlashcardTile(
                          flashcard: flashcard,
                          onEdit: () => onEdit(flashcard),
                          onDelete: () => onDelete(flashcard),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatefulWidget {
  const _SearchField({required this.controller, required this.onSearchChanged});

  final TextEditingController controller;
  final ValueChanged<String> onSearchChanged;

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_syncText);
  }

  @override
  void didUpdateWidget(covariant _SearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_syncText);
      widget.controller.addListener(_syncText);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_syncText);
    super.dispose();
  }

  void _syncText() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.06) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.15) : Colors.black12,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.35)
                : AppTheme.primaryColor.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: TextField(
        controller: widget.controller,
        decoration: InputDecoration(
          hintText: 'Buscar por perguntas ou respostas... ',
          hintStyle: TextStyle(
            color: isDark ? Colors.white.withOpacity(0.5) : Colors.black45,
            fontSize: 15,
          ),
          prefixIcon: Icon(
            Icons.search_rounded,
            color: isDark ? Colors.white70 : Colors.black54,
            size: 24,
          ),
          suffixIcon: widget.controller.text.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear_rounded,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                  onPressed: () {
                    widget.controller.clear();
                    widget.onSearchChanged('');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
        ),
        style: TextStyle(
          fontSize: 15,
          color: isDark ? Colors.white : Colors.black87,
        ),
        onChanged: widget.onSearchChanged,
      ),
    );
  }
}

class _FlashcardTile extends StatelessWidget {
  const _FlashcardTile({
    required this.flashcard,
    required this.onEdit,
    required this.onDelete,
  });

  final Flashcard flashcard;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          iconTheme: const IconThemeData(color: Colors.white),
          textTheme: Theme.of(context).textTheme.apply(
            bodyColor: Colors.white,
            displayColor: Colors.white,
          ),
        ),
        child: ExpansionTile(
          iconColor: Colors.white,
          collapsedIconColor: Colors.white.withOpacity(0.85),
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          leading: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.psychology_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          title: Text(
            flashcard.question,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
              color: Colors.white,
              height: 1.4,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.calendar_today_rounded,
                    size: 12,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _formatDate(flashcard.createdAt),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          trailing: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.edit_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                  onPressed: onEdit,
                  tooltip: 'Editar',
                  splashRadius: 24,
                ),
                IconButton(
                  icon: Icon(
                    Icons.delete_rounded,
                    color: Colors.white.withOpacity(0.9),
                    size: 22,
                  ),
                  onPressed: onDelete,
                  tooltip: 'Deletar',
                  splashRadius: 24,
                ),
              ],
            ),
          ),
          children: [
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 14),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.lightbulb_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'RESPOSTA',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.6,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    flashcard.answer,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.6,
                      color: Colors.white,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptySearchState extends StatelessWidget {
  const _EmptySearchState({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 80),
          child: Column(
            children: [
              Icon(
                Icons.search_off_rounded,
                size: 64,
                color: isDark ? Colors.white.withOpacity(0.35) : Colors.black26,
              ),
              const SizedBox(height: 16),
              Text(
                'Nenhum resultado encontrado',
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black87,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tente ajustar sua busca',
                style: TextStyle(
                  color: isDark ? Colors.white54 : Colors.black54,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

String _formatDate(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  final year = date.year.toString();
  return '$day/$month/$year';
}
