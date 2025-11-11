// ignore_for_file: deprecated_member_use, avoid_single_cascade_in_expression_statements, use_build_context_synchronously
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:formatic/core/utils/snackbar_utils.dart';
import 'package:formatic/models/assistant/ai_history.dart';
import 'package:formatic/services/assistant/ai_history_service.dart';
import 'package:formatic/services/auth/auth_service.dart';
import 'package:http/http.dart' as http;
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:xml/xml.dart';

class AssistantPage extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onThemeToggle;

  const AssistantPage({
    super.key,
    required this.isDarkMode,
    required this.onThemeToggle,
  });

  @override
  State<AssistantPage> createState() => _AssistantPageState();
}

class _AssistantPageState extends State<AssistantPage> {
  static const _helpyName = 'Helpy';
  static const _systemPrompt =
      'Você é Helpy, a tutora virtual da Formatic focada em apoiar estudantes. '
      'Forneça explicações claras, objetivas e em português, reforce técnicas de organização '
      'e proponha próximas etapas ou exercícios práticos sempre que possível.';
  static const int _maxFileBytes = 5 * 1024 * 1024;
  static const int _maxContextMessages = 14;

  final List<_ChatMessage> _messages = <_ChatMessage>[];
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _sendingMessage = false;
  bool _processingUpload = false;
  String? _apiKey;
  bool _loading = true;
  List<_ConversationSession> _sessions = <_ConversationSession>[];
  _ConversationSession? _activeSession;
  final List<_UploadedDocument> _pendingDocuments = <_UploadedDocument>[];

  final AiHistoryService _aiHistoryService = AiHistoryService();
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _apiKey = dotenv.maybeGet('DEEPSEEK_API_KEY')?.trim();
    _loadHistory();
  }

  static const _welcomeText =
      'Olá! Sou a $_helpyName, sua tutora virtual. Conte o que você precisa estudar '
      'ou quais dificuldades enfrentou e eu preparo um plano de estudos personalizado.';

  _ChatMessage _welcomeMessage() => const _ChatMessage(
    author: _MessageAuthor.assistant,
    content: _welcomeText,
  );

  Future<void> _loadHistory() async {
    setState(() => _loading = true);

    final List<_ConversationSession> sessions = <_ConversationSession>[];

    try {
      final user = _authService.currentUser;
      if (user != null) {
        final history = await _aiHistoryService.getUserHistory(user.id);
        for (final entry in history) {
          final session = _ConversationSession.fromHistory(entry);
          sessions.add(session);
        }
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showError(
          context,
          'Não foi possível carregar o histórico: $e',
        );
      }
    } finally {
      // ignore: control_flow_in_finally
      if (!mounted) return;
      setState(() {
        if (sessions.isEmpty) {
          _messages
            ..clear()
            ..add(_welcomeMessage());
          _activeSession = null;
        } else {
          sessions.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          _activeSession = sessions.first;
          _messages
            ..clear()
            ..addAll(
              _activeSession!.messages.isEmpty
                  ? <_ChatMessage>[_welcomeMessage()]
                  : _activeSession!.messages,
            );
        }
        _sessions = sessions;
        _loading = false;
        _pendingDocuments.clear();
      });
      _scrollToBottom();
    }
  }

  void _startNewConversation() {
    setState(() {
      _messages..clear();
      _sendingMessage = false;
      _processingUpload = false;
      _activeSession = null;
      _pendingDocuments.clear();
    });
    if (_messages.isEmpty) _messages.add(_welcomeMessage());
    _messageController.clear();
    _scrollToBottom();
  }

  Future<void> _sendMessage() async {
    final question = _messageController.text.trim();
    final hasAttachments = _pendingDocuments.isNotEmpty;
    if ((question.isEmpty && !hasAttachments) ||
        _sendingMessage ||
        _processingUpload) {
      return;
    }
    _messageController.clear();

    final effectivePrompt = question.isNotEmpty
        ? question
        : 'Analise os documentos anexados.';

    final attachmentsSummary = hasAttachments
        ? _pendingDocuments.map((doc) => doc.name).join(', ')
        : null;

    final aiContentBuffer = StringBuffer(effectivePrompt.trim());
    if (hasAttachments) {
      for (final doc in _pendingDocuments) {
        aiContentBuffer
          ..writeln('\n\n[Documento: ${doc.name}]')
          ..writeln(doc.content);
      }
    }
    final aiContent = aiContentBuffer.toString().trim();

    String displayContent;
    if (hasAttachments) {
      final summaryLine = '📎 Documentos anexados: ${attachmentsSummary!}';
      displayContent = question.isNotEmpty
          ? '$question\n\n$summaryLine'
          : summaryLine;
    } else {
      displayContent = question;
    }

    final historyQuestion = question.isNotEmpty
        ? question
        : (attachmentsSummary != null
              ? 'Documentos anexados: $attachmentsSummary'
              : effectivePrompt);

    setState(() {
      _messages.add(
        _ChatMessage(
          author: _MessageAuthor.user,
          content: aiContent,
          displayContent: displayContent.trim(),
        ),
      );
      _pendingDocuments.clear();
      _sendingMessage = true;
    });
    _scrollToBottom();

    try {
      final reply = await _fetchAssistantReply();

      setState(() {
        _messages.add(
          _ChatMessage(author: _MessageAuthor.assistant, content: reply),
        );
      });

      await _persistConversation(question: historyQuestion);
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showError(context, 'Erro ao falar com a IA: $e');
      }
    }

    setState(() => _sendingMessage = false);
    _scrollToBottom();
  }

  Future<String> _fetchAssistantReply() async {
    final apiKey = _apiKey ?? dotenv.maybeGet('DEEPSEEK_API_KEY')?.trim();
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception(
        'Configure a variável DEEPSEEK_API_KEY no .env e reinicie o app para usar a $_helpyName.',
      );
    }

    final response = await http.post(
      Uri.parse('https://api.deepseek.com/v1/chat/completions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        'model': 'deepseek-chat',
        'messages': _buildChatPayload(),
        'temperature': 0.7,
        'top_p': 0.8,
      }),
    );

    if (response.statusCode != 200) {
      final body = response.body.isEmpty
          ? 'Sem detalhes adicionais.'
          : response.body;
      throw Exception('Falha (${response.statusCode}): $body');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = decoded['choices'] as List<dynamic>?;
    if (choices == null || choices.isEmpty) {
      throw Exception('Resposta inesperada da IA.');
    }

    final message = choices.first['message'] as Map<String, dynamic>?;
    final content = message?['content'] as String?;
    if (content == null || content.trim().isEmpty) {
      throw Exception('A IA não retornou conteúdo.');
    }

    return content.trim();
  }

  List<Map<String, String>> _buildChatPayload() {
    final recentMessages = _messages.length <= _maxContextMessages
        ? _messages
        : _messages.sublist(_messages.length - _maxContextMessages);

    return [
      {'role': 'system', 'content': _systemPrompt},
      ...recentMessages.map(
        (message) => {
          'role': message.author == _MessageAuthor.user ? 'user' : 'assistant',
          'content': message.content,
        },
      ),
    ];
  }

  Future<void> _persistConversation({required String question}) async {
    final user = _authService.currentUser;
    if (user == null) return;

    final conversation = _messages
        .where((message) => !_isWelcomeMessage(message))
        .toList(growable: false);
    if (conversation.isEmpty) return;

    final firstUserMessage = conversation.firstWhere(
      (message) => message.author == _MessageAuthor.user,
      orElse: () =>
          _ChatMessage(author: _MessageAuthor.user, content: question),
    );

    String fallbackTitleCandidate =
        firstUserMessage.displayContent?.trim() ?? '';
    final firstUserContent = firstUserMessage.content.trim();
    if (fallbackTitleCandidate.isEmpty) {
      if (firstUserContent.isNotEmpty) {
        fallbackTitleCandidate = firstUserContent;
      } else {
        fallbackTitleCandidate = question;
      }
    }

    final fallbackTitle = fallbackTitleCandidate.trim().isNotEmpty
        ? fallbackTitleCandidate.trim()
        : 'Conversa iniciada em ${_formatTimestamp(DateTime.now().toUtc())}';

    final resolvedTitle = (_activeSession?.title.trim().isNotEmpty ?? false)
        ? _activeSession!.title
        : fallbackTitle;

    final normalizedTitle = _normalizeTitle(resolvedTitle);

    final serialized = _serializeMessages(conversation);

    if (_activeSession == null) {
      final response = await _aiHistoryService.client
          .from('ai_history')
          .insert({
            'user_id': user.id,
            'question': normalizedTitle,
            'answer': serialized,
          })
          .select()
          .limit(1);

      if (response.isEmpty) return;

      final Map<String, dynamic> data = response.first;
      final createdAt = DateTime.parse(data['created_at'] as String);
      final newSession = _ConversationSession(
        id: data['id'] as int,
        title: normalizedTitle,
        createdAt: createdAt,
        messages: conversation,
      );

      setState(() {
        _activeSession = newSession;
        _sessions = <_ConversationSession>[newSession, ..._sessions];
      });
    } else {
      await _aiHistoryService.client
          .from('ai_history')
          .update({'question': normalizedTitle, 'answer': serialized})
          .eq('id', _activeSession!.id);

      final updatedSession = _activeSession!.copyWith(
        title: normalizedTitle,
        messages: conversation,
      );

      setState(() {
        _activeSession = updatedSession;
        _sessions = <_ConversationSession>[
          updatedSession,
          ..._sessions.where((s) => s.id != updatedSession.id),
        ];
      });
    }
  }

  String _serializeMessages(List<_ChatMessage> messages) {
    final serialized = messages
        .map((message) {
          final map = <String, String>{
            'role': message.author == _MessageAuthor.user
                ? 'user'
                : 'assistant',
            'content': message.content,
          };
          final display = message.displayContent;
          if (display != null &&
              display.trim().isNotEmpty &&
              display.trim() != message.content.trim()) {
            map['display_content'] = display.trim();
          }
          return map;
        })
        .toList(growable: false);
    return jsonEncode(serialized);
  }

  bool _isWelcomeMessage(_ChatMessage message) =>
      message.author == _MessageAuthor.assistant &&
      message.content == _welcomeText;

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleMenuSelection(_AssistantMenuAction action) {
    switch (action) {
      case _AssistantMenuAction.newConversation:
        _startNewConversation();
        break;
      case _AssistantMenuAction.history:
        _showHistorySheet();
        break;
    }
  }

  Future<void> _handleFileUpload() async {
    if (_sendingMessage || _processingUpload) return;

    setState(() => _processingUpload = true);

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf', 'docx'],
        withData: true,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        setState(() => _processingUpload = false);
        return;
      }

      final file = result.files.single;
      final extension = (file.extension ?? '').toLowerCase();
      final name = file.name;

      if (extension != 'pdf' && extension != 'docx') {
        setState(() => _processingUpload = false);
        if (mounted) {
          SnackbarUtils.showError(
            context,
            'Formato não suportado. Envie arquivos PDF ou DOCX.',
          );
        }
        return;
      }

      Uint8List? bytes = file.bytes;
      if (bytes == null) {
        setState(() => _processingUpload = false);
        if (mounted) {
          final message = kIsWeb
              ? 'Não foi possível ler o arquivo selecionado. Verifique as permissões do navegador e tente novamente.'
              : 'Não foi possível ler o arquivo selecionado. Tente novamente.';
          SnackbarUtils.showError(context, message);
        }
        return;
      }

      if (bytes.length > _maxFileBytes) {
        setState(() => _processingUpload = false);
        if (mounted) {
          SnackbarUtils.showError(
            context,
            'Arquivo muito grande. Limite de 5MB.',
          );
        }
        return;
      }

      final extracted = await _extractTextFromFile(bytes, extension: extension);
      final cleaned = _cleanWhitespace(extracted);

      if (cleaned.isEmpty) {
        setState(() => _processingUpload = false);
        if (mounted) {
          SnackbarUtils.showError(
            context,
            'Não consegui extrair texto do arquivo. Verifique se o documento não é apenas imagem.',
          );
        }
        return;
      }

      final limitedForAssistant = _limitText(cleaned, 8000);
      setState(() {
        _processingUpload = false;
        _pendingDocuments.add(
          _UploadedDocument(name: name, content: limitedForAssistant),
        );
      });

      if (!mounted) return;
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showError(
          context,
          'Não foi possível processar o arquivo: $e',
        );
      }
      setState(() => _processingUpload = false);
    }
  }

  void _removePendingDocument(_UploadedDocument doc) {
    setState(() => _pendingDocuments.remove(doc));
  }

  Future<String> _extractTextFromFile(
    Uint8List bytes, {
    required String extension,
  }) async {
    if (extension == 'pdf') {
      return _extractTextFromPdf(bytes);
    }
    if (extension == 'docx') {
      return _extractTextFromDocx(bytes);
    }
    return '';
  }

  Future<String> _extractTextFromPdf(Uint8List bytes) async {
    try {
      final document = PdfDocument(inputBytes: bytes);
      final extractor = PdfTextExtractor(document);
      final buffer = StringBuffer();
      for (var i = 0; i < document.pages.count; i++) {
        buffer.write(extractor.extractText(startPageIndex: i, endPageIndex: i));
        buffer.write('\n');
      }
      document.dispose();
      return buffer.toString();
    } catch (_) {
      return '';
    }
  }

  Future<String> _extractTextFromDocx(Uint8List bytes) async {
    try {
      final archive = ZipDecoder().decodeBytes(bytes, verify: false);
      final documentEntry = archive.files.firstWhere(
        (file) => file.name == 'word/document.xml',
        orElse: () => ArchiveFile('empty', 0, const <int>[]),
      );

      if (documentEntry.size == 0) return '';

      final xmlString = utf8.decode(documentEntry.content as List<int>);
      final xmlDoc = XmlDocument.parse(xmlString);
      final buffer = StringBuffer();

      for (final node in xmlDoc.findAllElements('w:t')) {
        buffer.write(node.text);
        buffer.write(' ');
      }

      return buffer.toString();
    } catch (_) {
      return '';
    }
  }

  String _limitText(String text, int maxChars) {
    if (text.length <= maxChars) return text;
    return text.substring(0, maxChars);
  }

  String _cleanWhitespace(String text) {
    return text.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  Future<void> _deleteSession(_ConversationSession session) async {
    final user = _authService.currentUser;
    if (user == null) return;

    try {
      await _aiHistoryService.client
          .from('ai_history')
          .delete()
          .eq('id', session.id)
          .eq('user_id', user.id);

      if (!mounted) return;

      final updatedSessions = _sessions
          .where((existing) => existing.id != session.id)
          .toList();

      setState(() {
        _sessions = updatedSessions;
        if (_activeSession?.id == session.id) {
          _activeSession = null;
          _messages
            ..clear()
            ..add(_welcomeMessage());
          _sendingMessage = false;
          _messageController.clear();
          _pendingDocuments.clear();
        }
      });

      if (!mounted) return;
      SnackbarUtils.showSuccess(context, 'Conversa removida.');
    } catch (e) {
      if (!mounted) return;
      SnackbarUtils.showError(
        context,
        'Não foi possível excluir a conversa: $e',
      );
    }
  }

  void _showHistorySheet() {
    if (!_mountedWithContext()) return;
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (modalContext) {
        if (_sessions.isEmpty) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.history_rounded, size: 32, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Nenhuma conversa salva ainda.',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Envie uma mensagem para a Helpy e o histórico aparecerá aqui!',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return SafeArea(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: _sessions.length,
            separatorBuilder: (_, __) => const Divider(height: 20),
            itemBuilder: (context, index) {
              final session = _sessions[index];
              return ListTile(
                leading: CircleAvatar(
                  radius: 20,
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primary.withOpacity(0.12),
                  child: Icon(
                    Icons.chat_bubble_outline,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                title: Text(
                  session.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    session.preview,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatTimestamp(session.createdAt),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    IconButton(
                      tooltip: 'Excluir conversa',
                      icon: const Icon(Icons.delete_outline),
                      color: Theme.of(context).colorScheme.error,
                      onPressed: () => _deleteSession(session),
                    ),
                  ],
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  setState(() {
                    _activeSession = session;
                    _messages
                      ..clear()
                      ..addAll(
                        session.messages.isEmpty
                            ? <_ChatMessage>[_welcomeMessage()]
                            : session.messages,
                      );
                    _sendingMessage = false;
                    _pendingDocuments.clear();
                  });
                  _messageController.clear();
                  _scrollToBottom();
                },
              );
            },
          ),
        );
      },
    );
  }

  bool _mountedWithContext() => mounted && context.mounted;

  String _formatTimestamp(DateTime timestamp) {
    final local = timestamp.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day/$month $hour:$minute';
  }

  String _normalizeTitle(String value, {int maxLength = 140}) {
    final sanitized = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (sanitized.isEmpty || sanitized.length <= maxLength) {
      return sanitized;
    }
    final safeLength = maxLength > 3 ? maxLength - 3 : maxLength;
    final int endIndex = safeLength.clamp(0, sanitized.length);
    final truncated = sanitized.substring(0, endIndex).trimRight();
    if (maxLength <= 3 || endIndex >= sanitized.length) {
      return truncated;
    }
    return '$truncated...';
  }

  void _copyMessage(_ChatMessage message) {
    final text = message.uiContent.trim();
    if (text.isEmpty || !_mountedWithContext()) return;
    Clipboard.setData(ClipboardData(text: text));
    SnackbarUtils.showSuccess(context, 'Mensagem copiada.');
  }

  Future<void> _editMessage(int index) async {
    if (index < 0 || index >= _messages.length) return;
    if (_sendingMessage || _processingUpload || !_mountedWithContext()) return;

    final message = _messages[index];
    if (message.author != _MessageAuthor.user) return;

    final docMarker = '\n\n[Documento:';
    final docIndex = message.content.indexOf(docMarker);
    final hasAttachments = docIndex != -1;
    final attachmentsSection = hasAttachments
        ? message.content.substring(docIndex)
        : '';
    final basePrompt = hasAttachments
        ? message.content.substring(0, docIndex).trim()
        : message.content.trim();

    final controller = TextEditingController(text: basePrompt);

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Editar mensagem'),
        content: TextField(
          controller: controller,
          maxLines: null,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Atualize a mensagem selecionada',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );

    controller.dispose();

    if (result == null) return;
    final updatedPrompt = result.trim();

    if (updatedPrompt.isEmpty && !hasAttachments) {
      SnackbarUtils.showError(context, 'A mensagem não pode ficar vazia.');
      return;
    }

    final promptForContent = updatedPrompt.isNotEmpty
        ? updatedPrompt
        : (hasAttachments ? 'Analise os documentos anexados.' : '');

    final newContent = hasAttachments
        ? '$promptForContent$attachmentsSection'
        : promptForContent;

    String? newDisplay;
    if (hasAttachments) {
      final summary = _buildAttachmentSummaryFromContent(
        attachmentsSection,
      )?.trim();
      if (summary != null && summary.isNotEmpty) {
        newDisplay = promptForContent.isNotEmpty
            ? '$promptForContent\n\n$summary'
            : summary;
      } else {
        newDisplay = promptForContent.isNotEmpty ? promptForContent : null;
      }
    }

    final sanitizedContent = newContent.trim();
    final sanitizedDisplay = (newDisplay?.trim().isNotEmpty ?? false)
        ? newDisplay!.trim()
        : null;

    final updatedMessage = _ChatMessage(
      author: _MessageAuthor.user,
      content: sanitizedContent,
      displayContent: sanitizedDisplay,
    );

    setState(() => _messages[index] = updatedMessage);

    final persistReference = promptForContent.isNotEmpty
        ? promptForContent
        : (sanitizedDisplay ?? '');

    if (persistReference.isNotEmpty) {
      await _persistConversation(question: persistReference);
    }

    SnackbarUtils.showSuccess(context, 'Mensagem atualizada.');
  }

  String? _buildAttachmentSummaryFromContent(String attachmentSection) {
    final names = _attachmentNamesFromContent(attachmentSection);
    if (names.isEmpty) return null;
    return '📎 Documentos anexados: ${names.join(', ')}';
  }

  List<String> _attachmentNamesFromContent(String attachmentSection) {
    final regex = RegExp(r'\[Documento: ([^\]]+)\]');
    return regex
        .allMatches(attachmentSection)
        .map((match) => match.group(1)?.trim())
        .whereType<String>()
        .where((name) => name.isNotEmpty)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final scaffoldColor = theme.scaffoldBackgroundColor;

    return Column(
      children: [
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                  itemCount: _messages.length + (_sendingMessage ? 1 : 0),
                  itemBuilder: (context, index) {
                    final isTypingIndicator =
                        _sendingMessage && index == _messages.length;
                    if (isTypingIndicator) {
                      return Align(
                        alignment: Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 16, right: 50),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF2D2A39)
                                : const Color(0xFFE9E9ED),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    isDark
                                        ? Colors.white70
                                        : const Color(0xFF8B2CF5),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '$_helpyName está pensando...',
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white.withOpacity(0.85)
                                      : Colors.black87,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    final message = _messages[index];
                    final isUser = message.author == _MessageAuthor.user;
                    final bubbleColor = isUser
                        ? const Color(0xFF8B2CF5)
                        : (isDark
                              ? const Color.fromARGB(255, 65, 61, 79)
                              : const Color(0xFFE9E9ED));

                    return Align(
                      alignment: isUser
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _copyMessage(message),
                        onLongPress: message.author == _MessageAuthor.user
                            ? () => _editMessage(index)
                            : null,
                        child: Container(
                          margin: EdgeInsets.only(
                            bottom: 16,
                            left: isUser ? 50 : 0,
                            right: isUser ? 0 : 50,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: bubbleColor,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: _buildFormattedMessage(
                            message,
                            isDark: isDark,
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? scaffoldColor : Colors.white,
            border: Border(
              top: BorderSide(
                color: isDark
                    ? Colors.white.withOpacity(0.06)
                    : Colors.grey[300]!,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_pendingDocuments.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _pendingDocuments
                        .map(
                          (doc) => InputChip(
                            label: Text(doc.name),
                            avatar: const Icon(
                              Icons.insert_drive_file,
                              size: 18,
                            ),
                            onDeleted: () => _removePendingDocument(doc),
                          ),
                        )
                        .toList(),
                  ),
                ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Digite sua pergunta para $_helpyName...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(25),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: isDark
                            ? const Color(0xFF1E1B2A)
                            : Colors.grey[100],
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        hintStyle: TextStyle(
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                      enabled: !_sendingMessage && !_processingUpload,
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Enviar arquivo',
                    onPressed: (_sendingMessage || _processingUpload)
                        ? null
                        : _handleFileUpload,
                    icon: Icon(
                      Icons.attach_file,
                      color: (_sendingMessage || _processingUpload)
                          ? Colors.grey
                          : (isDark ? Colors.white : Colors.black87),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    decoration: const BoxDecoration(
                      color: Color(0xFF8B2CF5),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: (_sendingMessage || _processingUpload)
                          ? null
                          : _sendMessage,
                      icon: _sendingMessage
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 8),
                  PopupMenuButton<_AssistantMenuAction>(
                    onSelected: _handleMenuSelection,
                    tooltip: 'Mais opções',
                    itemBuilder: (context) => const [
                      PopupMenuItem<_AssistantMenuAction>(
                        value: _AssistantMenuAction.newConversation,
                        child: Text('Nova conversa'),
                      ),
                      PopupMenuItem<_AssistantMenuAction>(
                        value: _AssistantMenuAction.history,
                        child: Text('Histórico de conversas'),
                      ),
                    ],
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF1E1B2A)
                            : Colors.grey[200],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.more_vert,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

enum _MessageAuthor { user, assistant }

class _ChatMessage {
  final _MessageAuthor author;
  final String content;
  final String? displayContent;

  const _ChatMessage({
    required this.author,
    required this.content,
    this.displayContent,
  });

  String get uiContent => displayContent ?? content;
}

class _UploadedDocument {
  final String name;
  final String content;

  const _UploadedDocument({required this.name, required this.content});
}

class _ConversationSession {
  final int id;
  final String title;
  final DateTime createdAt;
  final List<_ChatMessage> messages;

  const _ConversationSession({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.messages,
  });

  String get preview {
    final buffer = StringBuffer();
    for (final message in messages) {
      if (message.author == _MessageAuthor.assistant) {
        buffer.write(message.uiContent);
        break;
      }
    }
    if (buffer.isEmpty) {
      return messages.isNotEmpty
          ? messages.first.uiContent
          : 'Conversa sem mensagens registradas.';
    }
    return buffer.toString();
  }

  _ConversationSession copyWith({String? title, List<_ChatMessage>? messages}) {
    return _ConversationSession(
      id: id,
      title: title ?? this.title,
      createdAt: createdAt,
      messages: messages ?? this.messages,
    );
  }

  factory _ConversationSession.fromHistory(AiHistory entry) {
    List<_ChatMessage> parsed;
    try {
      final decoded = jsonDecode(entry.answer);
      if (decoded is List) {
        parsed = decoded.whereType<Map<String, dynamic>>().map((map) {
          final displayRaw = (map['display_content'] as String?)?.trim();
          return _ChatMessage(
            author: map['role'] == 'user'
                ? _MessageAuthor.user
                : _MessageAuthor.assistant,
            content: (map['content'] as String?)?.trim() ?? '',
            displayContent: displayRaw == null || displayRaw.isEmpty
                ? null
                : displayRaw,
          );
        }).toList();
      } else {
        throw const FormatException('Formato inválido');
      }
    } catch (_) {
      parsed = <_ChatMessage>[
        if (entry.question.trim().isNotEmpty)
          _ChatMessage(author: _MessageAuthor.user, content: entry.question),
        if (entry.answer.trim().isNotEmpty)
          _ChatMessage(author: _MessageAuthor.assistant, content: entry.answer),
      ];
    }

    final title = _resolveTitle(entry.question, parsed, entry.createdAt);

    return _ConversationSession(
      id: entry.id,
      title: title,
      createdAt: entry.createdAt,
      messages: parsed,
    );
  }

  static String _resolveTitle(
    String fallback,
    List<_ChatMessage> messages,
    DateTime createdAt,
  ) {
    final firstUser = messages.firstWhere(
      (message) => message.author == _MessageAuthor.user,
      orElse: () =>
          _ChatMessage(author: _MessageAuthor.user, content: fallback.trim()),
    );

    if (firstUser.content.trim().isNotEmpty) {
      return firstUser.content.trim();
    }

    final formattedDate =
        '${createdAt.day.toString().padLeft(2, '0')}/'
        '${createdAt.month.toString().padLeft(2, '0')} '
        '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';

    return 'Conversa de $formattedDate';
  }
}

enum _AssistantMenuAction { newConversation, history }

Widget _buildFormattedMessage(_ChatMessage message, {required bool isDark}) {
  final isUser = message.author == _MessageAuthor.user;
  final baseColor = isUser
      ? Colors.white
      : (isDark ? Colors.white : Colors.black87);
  final baseStyle = TextStyle(fontSize: 16, color: baseColor);

  final pattern = RegExp(r'\*\*([^*]+)\*\*');
  final spans = <TextSpan>[];
  var currentIndex = 0;
  final text = message.uiContent;

  for (final match in pattern.allMatches(text)) {
    if (match.start > currentIndex) {
      spans.add(TextSpan(text: text.substring(currentIndex, match.start)));
    }
    final boldText = match.group(1) ?? '';
    spans.add(
      TextSpan(
        text: boldText,
        style: baseStyle.copyWith(fontWeight: FontWeight.w600),
      ),
    );
    currentIndex = match.end;
  }

  if (currentIndex < text.length) {
    spans.add(TextSpan(text: text.substring(currentIndex)));
  }

  if (spans.isEmpty) {
    spans.add(TextSpan(text: text));
  }

  return RichText(
    text: TextSpan(style: baseStyle, children: spans),
  );
}
