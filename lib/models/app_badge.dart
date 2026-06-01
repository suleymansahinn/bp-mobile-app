class AppBadge {
  final String id;
  final String title;
  final String description;
  final int requiredXP;
  final String emoji;

  const AppBadge({
    required this.id,
    required this.title,
    required this.description,
    required this.requiredXP,
    this.emoji = "🏆",
  });
}