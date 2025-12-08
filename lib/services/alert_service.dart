import 'package:flutter/material.dart';

enum AlertType { success, error, warning, info }

class AlertService {
  AlertService._();
  static final AlertService instance = AlertService._();

  OverlayState? _overlayState;

  void init(BuildContext context) {
    _overlayState = Overlay.of(context);
  }

  void show(BuildContext context, String message, AlertType type) {
    _overlayState ??= Overlay.of(context);

    final overlayEntry = OverlayEntry(
      builder: (context) => _AlertOverlay(
        message: message,
        type: type,
        onDismiss:
            () {}, // Can't remove entry directly from inside easily without key or complex logic, simpler to let it handle its own exit animation and removal is managed by logic below
      ),
    );

    _overlayState?.insert(overlayEntry);

    // Auto-remove after duration + animation
    Future.delayed(const Duration(seconds: 4), () {
      overlayEntry.remove();
    });
  }
}

class _AlertOverlay extends StatefulWidget {
  final String message;
  final AlertType type;
  final VoidCallback onDismiss;

  const _AlertOverlay({
    required this.message,
    required this.type,
    required this.onDismiss,
  });

  @override
  State<_AlertOverlay> createState() => _AlertOverlayState();
}

class _AlertOverlayState extends State<_AlertOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(1.5, 0.0), // Start from right off-screen
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();

    // Start exit animation before outer overlay removal
    Future.delayed(const Duration(seconds: 3, milliseconds: 500), () {
      if (mounted) {
        _controller.reverse();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getColor(AlertType type) {
    switch (type) {
      case AlertType.success:
        return Colors.green.shade600;
      case AlertType.error:
        return Colors.red.shade600;
      case AlertType.warning:
        return Colors.orange.shade800;
      case AlertType.info:
        return Colors.blue.shade600;
    }
  }

  IconData _getIcon(AlertType type) {
    switch (type) {
      case AlertType.success:
        return Icons.check_circle_outline;
      case AlertType.error:
        return Icons.error_outline;
      case AlertType.warning:
        return Icons.warning_amber_rounded;
      case AlertType.info:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Positioned safely within overlay
    return Positioned(
      top: 100, // Below navbar usually
      right: 20,
      width: 350, // Fixed width for nice look on web
      child: SlideTransition(
        position: _offsetAnimation,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border(
                left: BorderSide(color: _getColor(widget.type), width: 6),
              ),
            ),
            child: Row(
              children: [
                Icon(_getIcon(widget.type), color: _getColor(widget.type)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.message,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
