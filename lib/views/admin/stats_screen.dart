import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../widgets/app_colors.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {

  Future<int> count(String collection) async {
    try {
      final snap =
          await FirebaseFirestore.instance.collection(collection).get();
      return snap.docs.length;
    } catch (e) {
      return 0;
    }
  }

  Future<int> countUsersByRole(String role) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: role)
          .get();

      return snap.docs.length;
    } catch (e) {
      return 0;
    }
  }

  Future<List<int>> loadStats() async {
    try {
      return [
        await count("resources"),
        await count("reservations"),
        await countUsersByRole("manager"), 
        await countUsersByRole("user"),    
      ];
    } catch (e) {
      return [0, 0, 0, 0];
    }
  }

  Future<List<FlSpot>> getWeeklyData() async {
    final now = DateTime.now();
    final List<FlSpot> spots = [];

    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));

      final start = DateTime(day.year, day.month, day.day);
      final end = DateTime(day.year, day.month, day.day, 23, 59, 59);

      final snap = await FirebaseFirestore.instance
          .collection('reservations')
          .where('startAt', isGreaterThanOrEqualTo: start)
          .where('startAt', isLessThanOrEqualTo: end)
          .get();

      spots.add(FlSpot((6 - i).toDouble(), snap.docs.length.toDouble()));
    }

    return spots;
  }

  Future<Map<String, int>> getTypeStats() async {
    final resSnap =
        await FirebaseFirestore.instance.collection('resources').get();

    final Map<String, int> counts = {
      "Salles": 0,
      "Véhicules": 0,
      "Matériel": 0,
    };

    for (var doc in resSnap.docs) {
      final type = doc['type'];
      if (counts.containsKey(type)) {
        counts[type] = counts[type]! + 1;
      }
    }

    return counts;
  }

  Future<Map<String, int>> getMonthlyStats() async {
    final snap =
        await FirebaseFirestore.instance.collection('reservations').get();

    final Map<String, int> months = {};

    for (var doc in snap.docs) {
      final date = (doc['startAt'] as Timestamp).toDate();
      final key = "${date.month}/${date.year}";
      months[key] = (months[key] ?? 0) + 1;
    }

    return months;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Dashboard",
          style: TextStyle(color: AppColors.textPrimary),
        ),
        iconTheme: const IconThemeData(color: AppColors.primary),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            const Text("Vue globale",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

            const SizedBox(height: 12),

            FutureBuilder<List<int>>(
              future: loadStats(),
              builder: (context, snapshot) {

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final data = snapshot.data!;

                return Column(
                  children: [
                    Row(
                      children: [
                        _card("Ressources", data[0], Icons.home),
                        const SizedBox(width: 10),
                        _card("Réservations", data[1], Icons.calendar_today),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _card("Managers", data[2], Icons.manage_accounts), // ✅ FIX ICON
                        const SizedBox(width: 10),
                        _card("Users", data[3], Icons.group),
                      ],
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 20),

            const Text("Évolution des réservations",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

            const SizedBox(height: 10),

            FutureBuilder<List<FlSpot>>(
              future: getWeeklyData(),
              builder: (context, snapshot) {

                if (!snapshot.hasData) {
                  return const CircularProgressIndicator();
                }

                return Container(
                  height: 220,
                  padding: const EdgeInsets.all(16),
                  decoration: _box(),
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(show: true),

                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 1,
                            getTitlesWidget: (value, _) =>
                                Text(value.toInt().toString(),
                                    style: const TextStyle(fontSize: 10)),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 1,
                            getTitlesWidget: (value, _) {
                              const days = ["L", "M", "M", "J", "V", "S", "D"];
                              return Text(days[value.toInt()],
                                  style: const TextStyle(fontSize: 10));
                            },
                          ),
                        ),
                        rightTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                      ),

                      lineBarsData: [
                        LineChartBarData(
                          spots: snapshot.data!,
                          isCurved: true,
                          color: Colors.red,
                          barWidth: 3,
                          dotData: FlDotData(show: true),
                          belowBarData: BarAreaData(
                            show: true,
                            color: Colors.red.withOpacity(0.2),
                          ),
                        )
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            const Text("Ressources par type",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

            const SizedBox(height: 10),

            FutureBuilder<Map<String, int>>(
              future: getTypeStats(),
              builder: (context, snapshot) {

                if (!snapshot.hasData) return const SizedBox();

                return Column(
                  children: snapshot.data!.entries
                      .map((e) => _tile(e.key, e.value))
                      .toList(),
                );
              },
            ),

            const SizedBox(height: 20),

            const Text("Réservations par mois",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

            const SizedBox(height: 10),

            FutureBuilder<Map<String, int>>(
              future: getMonthlyStats(),
              builder: (context, snapshot) {

                if (!snapshot.hasData) return const SizedBox();

                return Column(
                  children: snapshot.data!.entries
                      .map((e) => _tile("Mois ${e.key}", e.value))
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _card(String title, int value, IconData icon) {
    return Expanded(
      child: Container(
        height: 110,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.primary.withOpacity(0.8),
              AppColors.primary,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white),
            const Spacer(),
            Text("$value",
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold)),
            Text(title,
                style: const TextStyle(color: Colors.white70)),
          ],
        ),
      ),
    );
  }

  Widget _tile(String title, int value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: _box(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title),
          Text("$value",
              style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  BoxDecoration _box() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.primary),
    );
  }
}