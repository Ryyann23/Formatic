// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:formatic/core/utils/snackbar_utils.dart';
import 'package:formatic/models/library/book.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class PdfViewerPage extends StatefulWidget {
  final Book book;
  final bool isDarkMode;

  const PdfViewerPage({
    super.key,
    required this.book,
    required this.isDarkMode,
  });

  @override
  State<PdfViewerPage> createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends State<PdfViewerPage> {
  final PdfViewerController _pdfViewerController = PdfViewerController();
  int _currentPage = 1;
  int _totalPages = 0;
  bool _isLoading = true;
  double _zoomLevel = 1.0;
  double _dragDeltaX = 0.0;

  @override
  void initState() {
    super.initState();
    _pdfViewerController.addListener(_updatePageInfo);
  }

  @override
  void dispose() {
    _pdfViewerController.removeListener(_updatePageInfo);
    _pdfViewerController.dispose();
    super.dispose();
  }

  void _updatePageInfo() {
    setState(() {
      _currentPage = _pdfViewerController.pageNumber;
      _totalPages = _pdfViewerController.pageCount;
      _zoomLevel = _pdfViewerController.zoomLevel;
    });
  }

  void _zoomIn() {
    final newLevel = (_pdfViewerController.zoomLevel + 0.25).clamp(0.5, 5.0);
    _pdfViewerController.zoomLevel = newLevel;
    setState(() => _zoomLevel = newLevel);
  }

  void _zoomOut() {
    final newLevel = (_pdfViewerController.zoomLevel - 0.25).clamp(0.5, 5.0);
    _pdfViewerController.zoomLevel = newLevel;
    setState(() => _zoomLevel = newLevel);
  }

  void _fitPage() {
    _pdfViewerController.zoomLevel = 1.0; // padrão
    setState(() => _zoomLevel = 1.0);
  }

  void _fitWidth() {
    // Aproximação: um pouco mais que o padrão para ocupar melhor a largura.
    // O usuário pode refinar com +/-
    final newLevel = 1.3;
    _pdfViewerController.zoomLevel = newLevel;
    setState(() => _zoomLevel = newLevel);
  }

  void _onDoubleTap() {
    // Toggle rápido de zoom: 1.0 <-> 2.0
    final newLevel = _zoomLevel <= 1.05 ? 2.0 : 1.0;
    _pdfViewerController.zoomLevel = newLevel;
    setState(() => _zoomLevel = newLevel);
  }

  void _onHorizontalDragStart(DragStartDetails details) {
    _dragDeltaX = 0.0;
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    _dragDeltaX += details.delta.dx;
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    // Só navega por gesto quando não está com zoom (como Kindle)
    if (_zoomLevel > 1.05) return;
    const threshold = 60.0; // arrasto mínimo em px
    if (_dragDeltaX <= -threshold && _currentPage < _totalPages) {
      _pdfViewerController.nextPage();
    } else if (_dragDeltaX >= threshold && _currentPage > 1) {
      _pdfViewerController.previousPage();
    }
  }

  void _showPageNavigator() {
    final controller = TextEditingController(text: _currentPage.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ir para página'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: 'Número da página (1-$_totalPages)',
            border: const OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final page = int.tryParse(controller.text);
              if (page != null && page >= 1 && page <= _totalPages) {
                _pdfViewerController.jumpToPage(page);
                Navigator.pop(context);
              } else {
                SnackbarUtils.showError(
                  context,
                  'Página inválida. Digite um número entre 1 e $_totalPages',
                );
              }
            },
            child: const Text('Ir'),
          ),
        ],
      ),
    );
  }

  void _showBookInfo() {
    showModalBottomSheet(
      context: context,
      backgroundColor: widget.isDarkMode ? Colors.grey[900] : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.book.title,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Por ${widget.book.author}',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            Text(
              widget.book.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.book.tags.map((tag) {
                return Chip(
                  label: Text(
                    BookTags.tagLabels[tag] ?? tag,
                    style: const TextStyle(fontSize: 12),
                  ),
                  backgroundColor: widget.isDarkMode
                      ? Colors.grey[800]
                      : Colors.grey[200],
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _InfoItem(
                  icon: Icons.book,
                  label: 'Páginas',
                  value: widget.book.pageCount.toString(),
                ),
                _InfoItem(
                  icon: Icons.language,
                  label: 'Idioma',
                  value: widget.book.language == 'pt-BR'
                      ? 'Português'
                      : widget.book.language,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Verifica se é URL ou asset
    final isNetworkPdf =
        widget.book.pdfPath.startsWith('http://') ||
        widget.book.pdfPath.startsWith('https://');

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.book.title),
        actions: [
          // Informações do livro
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: _showBookInfo,
            tooltip: 'Informações do livro',
          ),
          // Opções de ajuste
          PopupMenuButton<String>(
            tooltip: 'Opções de zoom',
            onSelected: (value) {
              if (value == 'fit-page') _fitPage();
              if (value == 'fit-width') _fitWidth();
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'fit-page', child: Text('Ajustar à página')),
              PopupMenuItem(
                value: 'fit-width',
                child: Text('Ajustar à largura'),
              ),
            ],
            icon: const Icon(Icons.zoom_out_map),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Viewer PDF
          Expanded(
            child: Stack(
              children: [
                // Envolve o viewer em GestureDetector para gestos tipo Kindle (swipe horizontal e duplo toque)
                isNetworkPdf
                    ? GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onDoubleTap: _onDoubleTap,
                        onHorizontalDragStart: _zoomLevel <= 1.05
                            ? _onHorizontalDragStart
                            : null,
                        onHorizontalDragUpdate: _zoomLevel <= 1.05
                            ? _onHorizontalDragUpdate
                            : null,
                        onHorizontalDragEnd: _zoomLevel <= 1.05
                            ? _onHorizontalDragEnd
                            : null,
                        child: SfPdfViewer.network(
                          widget.book.pdfPath,
                          controller: _pdfViewerController,
                          pageLayoutMode: PdfPageLayoutMode.single,
                          canShowScrollHead: false,
                          canShowScrollStatus: false,
                          pageSpacing: 0,
                          onDocumentLoaded: (details) {
                            setState(() {
                              _isLoading = false;
                              _totalPages = details.document.pages.count;
                            });
                          },
                          onDocumentLoadFailed: (details) {
                            setState(() => _isLoading = false);
                            SnackbarUtils.showError(
                              context,
                              'Erro ao carregar PDF: ${details.description}',
                            );
                          },
                        ),
                      )
                    : GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onDoubleTap: _onDoubleTap,
                        onHorizontalDragStart: _zoomLevel <= 1.05
                            ? _onHorizontalDragStart
                            : null,
                        onHorizontalDragUpdate: _zoomLevel <= 1.05
                            ? _onHorizontalDragUpdate
                            : null,
                        onHorizontalDragEnd: _zoomLevel <= 1.05
                            ? _onHorizontalDragEnd
                            : null,
                        child: SfPdfViewer.asset(
                          widget.book.pdfPath,
                          controller: _pdfViewerController,
                          pageLayoutMode: PdfPageLayoutMode.single,
                          canShowScrollHead: false,
                          canShowScrollStatus: false,
                          pageSpacing: 0,
                          onDocumentLoaded: (details) {
                            setState(() {
                              _isLoading = false;
                              _totalPages = details.document.pages.count;
                            });
                          },
                          onDocumentLoadFailed: (details) {
                            setState(() => _isLoading = false);
                            SnackbarUtils.showError(
                              context,
                              'Erro ao carregar PDF: ${details.description}',
                            );
                          },
                        ),
                      ),

                // Loading indicator (usa surface do tema para não estourar no dark)
                if (_isLoading)
                  Container(
                    color: Theme.of(
                      context,
                    ).colorScheme.surface.withOpacity(0.6),
                    child: const Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
          ),

          // Barra de controles (apenas navegação e indicador)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Botão página anterior
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: _currentPage > 1
                        ? () => _pdfViewerController.previousPage()
                        : null,
                    tooltip: 'Página anterior',
                  ),
                  // Botão próxima página (logo ao lado da anterior)
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: _currentPage < _totalPages
                        ? () => _pdfViewerController.nextPage()
                        : null,
                    tooltip: 'Próxima página',
                  ),

                  const SizedBox(width: 8),

                  // Indicador central (somente páginas)
                  InkWell(
                    onTap: _totalPages > 0 ? _showPageNavigator : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _totalPages > 0
                                  ? 'Página $_currentPage de $_totalPages'
                                  : 'Carregando...',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Zoom - e Zoom + (lado a lado, na barra inferior)
                  IconButton(
                    icon: const Icon(Icons.remove),
                    onPressed: _zoomLevel > 0.5 ? _zoomOut : null,
                    tooltip: 'Diminuir zoom',
                  ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: _zoomLevel < 5.0 ? _zoomIn : null,
                    tooltip: 'Aumentar zoom',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 32, color: Colors.grey[600]),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
        ),
      ],
    );
  }
}
