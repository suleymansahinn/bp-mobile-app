import 'package:flutter/material.dart';
import '../xp_manager.dart';

class ProgressHeader extends StatefulWidget {
  const ProgressHeader({super.key});

  @override
  State<ProgressHeader> createState() => _ProgressHeaderState();
}

class _ProgressHeaderState extends State<ProgressHeader> {
  int level = 1;
  int streak = 0;

  @override
  void initState() {
    super.initState();
    loadProgress();
  }

  Future<void> loadProgress() async {
    int xp = await XPManager.getXP();
    level = XPManager.getLevel(xp);
    streak = 0; // placeholder, eklenebilir
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text("Level: $level"),
        subtitle: Text("🔥 Streak: $streak gün"),
      ),
    );
  }
}