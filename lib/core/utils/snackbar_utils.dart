import 'dart:async';
import 'package:flutter/material.dart';

class SnackbarUtils {
  SnackbarUtils._();

  static OverlayEntry? _currentEntry;

  static void showSuccess(BuildContext context, String message) {
    const successColor = Color(0xFF2ECC71);
    _show(context, message, successColor, Icons.check_circle_rounded);
  }

  static void showError(BuildContext context, String message) {
    const errorColor = Color(0xFFE74C3C);
    _show(context, message, errorColor, Icons.error_rounded);
  }

  static void _show(
    BuildContext context,
    String message,
    Color color,
    IconData icon,
  ) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) {
      // Fallback to the native snackbar if no overlay is available.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          backgroundColor: color,
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );
      return;
    }

    _removeEntry(_currentEntry);

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => _AnimatedSnackbar(
        message: message,
        backgroundColor: color,
        icon: icon,
        onDismissed: () => _removeEntry(entry),
      ),
    );

    _currentEntry = entry;
    overlay.insert(entry);
  }

  static void _removeEntry(OverlayEntry? entry) {
    if (entry == null) return;
    if (_currentEntry == entry) {
      entry.remove();
      _currentEntry = null;
    }
  }
}

class _AnimatedSnackbar extends StatefulWidget {
  const _AnimatedSnackbar({
    required this.message,
    required this.backgroundColor,
    required this.icon,
    required this.onDismissed,
  });

  final String message;
  final Color backgroundColor;
  final IconData icon;
  final VoidCallback onDismissed;

  @override
  State<_AnimatedSnackbar> createState() => _AnimatedSnackbarState();
}

class _AnimatedSnackbarState extends State<_AnimatedSnackbar>
    with SingleTickerProviderStateMixin {
  static const Duration _displayDuration = Duration(seconds: 1);
  static const double _horizontalMargin = 24;

  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
      reverseDuration: const Duration(milliseconds: 240),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _controller,
            curve: Curves.easeOutBack,
            reverseCurve: Curves.easeIn,
          ),
        );

    _controller.addStatusListener(_handleStatus);
    _controller.forward();

    _timer = Timer(_displayDuration, () {
      if (mounted) _controller.reverse();
    });
  }

  void _handleStatus(AnimationStatus status) {
    if (status == AnimationStatus.dismissed) {
      widget.onDismissed();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.removeStatusListener(_handleStatus);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomInset = mediaQuery.viewInsets.bottom;
    final bottomPadding =
        (bottomInset > 0 ? bottomInset : mediaQuery.padding.bottom) + 24;

    return IgnorePointer(
      ignoring: true,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            left: _horizontalMargin,
            right: _horizontalMargin,
            bottom: bottomPadding,
            child: SlideTransition(
              position: _slideAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: widget.backgroundColor,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: widget.backgroundColor.withOpacity(0.35),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(widget.icon, color: Colors.white, size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.message,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.left,
                            maxLines: 3,
                            overflow: TextOverflow.fade,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
