class Achievement {
  final String title;
  final String description;
  final bool Function(int xp, List<String> lessons) earned;

  Achievement({
    required this.title,
    required this.description,
    required this.earned,
  });
}

final achievements = [
  Achievement(
    title: "Başlangıç Yazımcısı",
    description: "50 XP kazandın",
    earned: (xp, _) => xp >= 50,
  ),
  Achievement(
    title: "Usta Yazımcı",
    description: "150 XP kazandın",
    earned: (xp, _) => xp >= 150,
  ),
  Achievement(
    title: "İlk Ders",
    description: "Bir ders tamamladın",
    earned: (_, l) => l.length >= 1,
  ),
  Achievement(
    title: "Azimli Öğrenci",
    description: "3 ders tamamladın",
    earned: (_, l) => l.length >= 3,
  ),
];