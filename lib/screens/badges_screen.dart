import 'package:flutter/material.dart';
import '../services/badge_service.dart';

class BadgesScreen extends StatelessWidget {
  const BadgesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Başarılar")),
      body: FutureBuilder(
        future: BadgeService.getUnlockedBadges(),
        builder: (context, snapshot) {
          final unlocked = snapshot.data ?? [];

          return ListView(
            children: BadgeService.allBadges.map((b) {
              final isUnlocked = unlocked.contains(b.id);

              return ListTile(
                leading: Icon(
                  Icons.emoji_events,
                  color: isUnlocked ? Colors.amber : Colors.grey,
                ),
                title: Text(b.title),
                subtitle: Text(b.description),
                trailing: isUnlocked
                    ? const Icon(Icons.check, color: Colors.green)
                    : const Icon(Icons.lock),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
