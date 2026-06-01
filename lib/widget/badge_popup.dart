import 'package:flutter/material.dart';
import '../models/badge.dart';

class BadgePopup extends StatefulWidget {
  final Badge badge;

  const BadgePopup({super.key, required this.badge});

  @override
  State<BadgePopup> createState() => _BadgePopupState();
}

class _BadgePopupState extends State<BadgePopup>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scale = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: AlertDialog(
        title: const Text("🏆 Yeni Rozet Kazandın!"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.emoji_events, size: 64, color: Colors.amber),
            const SizedBox(height: 12),
            Text(
              widget.badge.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(widget.badge.description),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Harika!"),
          )
        ],
      ),
    );
  }
}