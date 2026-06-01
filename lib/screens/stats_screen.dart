import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  int totalXP = 0;
  List<int> dailyXP = [0, 0, 0, 0, 0, 0, 0]; // 7 günlük XP geçmişi

  @override
  void initState() {
    super.initState();
    _loadXPData();
  }

  Future<void> _loadXPData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      totalXP = prefs.getInt('xp') ?? 0;
      // Örnek veri: Gerçekte burada günlük kayıt tutulabilir.
      dailyXP = List<int>.from(prefs.getStringList('dailyXP')?.map(int.parse) ?? [5, 8, 10, 6, 12, 9, 7]);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("İstatistikler"),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              "Toplam XP: $totalXP",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text("Son 7 Günlük XP Kazanımı", style: TextStyle(fontSize: 18)),
            const SizedBox(height: 12),
            Expanded(
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: (dailyXP.reduce((a, b) => a > b ? a : b)).toDouble() + 5,
                  barTouchData: BarTouchData(enabled: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          const days = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
                          return Text(days[value.toInt() % 7]);
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(dailyXP.length, (i) {
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: dailyXP[i].toDouble(),
                          color: Colors.blueAccent,
                          width: 18,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
