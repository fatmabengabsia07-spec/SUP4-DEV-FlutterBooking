import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../models/reservation.dart';
import '../../providers/reservation_provider.dart';
import '../../widgets/app_colors.dart';

class EditReservationScreen extends StatefulWidget {
  final Reservation reservation;

  const EditReservationScreen({super.key, required this.reservation});

  @override
  State<EditReservationScreen> createState() =>
      _EditReservationScreenState();
}

class _EditReservationScreenState extends State<EditReservationScreen> {

  @override
  void initState() {
    super.initState();

    final rp = context.read<ReservationProvider>();

    rp.setDay(widget.reservation.startAt);
    rp.setHour(widget.reservation.startAt.hour);
  }

  @override
  Widget build(BuildContext context) {
    final rp = Provider.of<ReservationProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Modifier réservation"),
        backgroundColor: AppColors.primary,
      ),
      body: Column(
        children: [

          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(16),
            ),
            child: TableCalendar(
              firstDay: DateTime.now(),
              lastDay: DateTime.now().add(const Duration(days: 120)),
              focusedDay: rp.selectedDay,
              selectedDayPredicate: (day) =>
                  isSameDay(day, rp.selectedDay),
              onDaySelected: (selectedDay, _) {
                rp.setDay(selectedDay);
              },
              calendarStyle: const CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: AppColors.textPrimary,
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
              ),
            ),
          ),

          Expanded(
            child: StreamBuilder(
              stream: rp.reservationsForDay(widget.reservation.resourceId),
              builder: (context, snapshot) {

                final reservedHours = <int>{};

                if (snapshot.hasData) {
                  final list = snapshot.data!;
                  for (final r in list) {
                    if (r.id != widget.reservation.id) {
                      reservedHours.add(r.startAt.hour);
                    }
                  }
                }

                return ListView.builder(
                  itemCount: 10,
                  itemBuilder: (context, index) {

                    final hour = 8 + index;
                    final isReserved = reservedHours.contains(hour);
                    final isSelected = rp.selectedHour == hour;

                    return GestureDetector(
                      onTap: isReserved ? null : () => rp.setHour(hour),
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.success,
                            width: isSelected ? 2 : 1,
                          ),
                          color: isReserved
                              ? Colors.grey.shade200
                              : (isSelected
                                  ? AppColors.primary.withOpacity(0.1)
                                  : Colors.white),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "${hour.toString().padLeft(2, '0')}:00",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isReserved
                                    ? Colors.grey
                                    : Colors.black,
                              ),
                            ),

                            Text(
                              isReserved
                                  ? "Indisponible"
                                  : (isSelected
                                      ? "Sélectionné"
                                      : "Disponible"),
                              style: TextStyle(
                                color: isReserved
                                    ? Colors.grey
                                    : AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          if (rp.error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                rp.error!,
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () async {

                  final ok = await rp.updateReservation(
                    id: widget.reservation.id,
                    durationMinutes: 60,
                  );

                  if (ok && context.mounted) {
                    Navigator.pop(context);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Réservation modifiée avec succès"),
                      ),
                    );
                  }
                },
                child: const Text(
                  "Valider modification",
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}