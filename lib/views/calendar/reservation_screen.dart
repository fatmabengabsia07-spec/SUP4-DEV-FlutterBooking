import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../models/resource.dart';
import '../../providers/reservation_provider.dart';
import '../../widgets/app_colors.dart';
import '../reservations/reservations_screen.dart';

class ReservationScreen extends StatelessWidget {
  final Resource resource;

  const ReservationScreen({super.key, required this.resource});

  bool get requiresApproval => true;

  ImageProvider _getImageProvider(String url) {
    if (url.isNotEmpty) {
      if (url.startsWith('/') && File(url).existsSync()) {
        return FileImage(File(url));
      }
      if (url.startsWith('http')) {
        return NetworkImage(url);
      }
    }
    return const AssetImage("assets/images/default_avatar.jpg");
  }

  @override
  Widget build(BuildContext context) {

    final rp = Provider.of<ReservationProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: Text(resource.name,
            style: const TextStyle(color: AppColors.textPrimary)),
      ),
      body: Column(
        children: [

          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Image(
                    image: _getImageProvider(resource.imageUrl),
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(resource.name,
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(
                        "${resource.type} • ${resource.capacity} pers.",
                        style:
                            TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(16),
            ),
            child: TableCalendar(
              firstDay: DateTime.now(),
              lastDay:
                  DateTime.now().add(const Duration(days: 120)),
              focusedDay: rp.selectedDay,

              selectedDayPredicate: (day) =>
                  isSameDay(day, rp.selectedDay),

              onDaySelected: (selectedDay, focusedDay) {
                rp.setDay(selectedDay);
              },

              calendarStyle: CalendarStyle(
                todayDecoration: const BoxDecoration(
                  color: AppColors.textPrimary,
                  shape: BoxShape.circle,
                ),
                selectedDecoration: const BoxDecoration(
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

          const SizedBox(height: 12),

          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(16),
              ),
              child: StreamBuilder(
                stream: rp.reservationsForDay(resource.id),
                builder: (context, snapshot) {

                  final reservedHours = <int>{};

                  if (snapshot.hasData) {
                    final list = snapshot.data!;
                    for (final r in list) {
                      reservedHours.add(r.startAt.hour);
                    }
                  }

                  final hours = List.generate(10, (i) => 8 + i);

                  return ListView.separated(
                    itemCount: hours.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, index) {

                      final h = hours[index];
                      final isReserved =
                          reservedHours.contains(h);
                      final isSelected =
                          rp.selectedHour == h;

                      return GestureDetector(
                        onTap: isReserved
                            ? null
                            : () => rp.setHour(h),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            borderRadius:
                                BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                              width: isSelected ? 2 : 1,
                            ),
                            color: isReserved
                                ? Colors.grey.shade200
                                : (isSelected
                                    ? Colors.red.shade50
                                    : AppColors.background),
                          ),
                          child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "${h.toString().padLeft(2, '0')}:00",
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: isReserved
                                      ? AppColors.textSecondary
                                      : AppColors.textPrimary,
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
                                        ? AppColors.textSecondary
                                        : AppColors.primary),
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
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [

                if (rp.error != null)
                  Padding(
                    padding:
                        const EdgeInsets.only(bottom: 8),
                    child: Text(rp.error!,
                        style:
                            const TextStyle(color: AppColors.error)),
                  ),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: rp.loading
                        ? null
                        : () async {

                            final uid = firebase_auth
                                .FirebaseAuth
                                .instance
                                .currentUser
                                ?.uid;

                            if (uid == null ||
                                rp.selectedHour == null)
                              return;

                            final ok =
                                await rp.confirmReservation(
                              resourceId: resource.id,
                              userId: uid,
                              requiresApproval:
                                  requiresApproval,
                              durationMinutes: 60,
                            );

                            if (ok && context.mounted) {
                              showDialog(
                                context: context,
                                barrierDismissible:
                                    false,
                                builder: (_) =>
                                    _SuccessDialog(
                                  resource: resource,
                                  selectedDay:
                                      rp.selectedDay,
                                  selectedHour:
                                      rp.selectedHour!,
                                ),
                              );
                            }
                          },
                    child: rp.loading
                        ? const CircularProgressIndicator(
                            color: AppColors.primary)
                        : const Text(
                            "Continuer",
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight:
                                    FontWeight.bold),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SuccessDialog extends StatelessWidget {
  final Resource resource;
  final DateTime selectedDay;
  final int selectedHour;

  const _SuccessDialog({
    required this.resource,
    required this.selectedDay,
    required this.selectedHour,
  });
  ImageProvider _getImageProvider(String url) {
    if (url.isNotEmpty) {
      if (url.startsWith('/') && File(url).existsSync()) {
        return FileImage(File(url));
      }
      if (url.startsWith('http')) {
        return NetworkImage(url);
      }
    }
    return const AssetImage("assets/images/default_avatar.jpg");
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [

         ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(20),
            ),
            child: Image(
              image: _getImageProvider(resource.imageUrl),
              height: 150,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),

          const SizedBox(height: 16),

          Text(resource.name,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary)),

          const SizedBox(height: 8),

          const Icon(Icons.check_circle,
              size: 60, color: AppColors.success),

          const SizedBox(height: 12),

          const Text("Réservation confirmée !",
              style:
                  TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

          const SizedBox(height: 8),

          Text(
            "Le ${selectedDay.day}/${selectedDay.month}/${selectedDay.year}\n"
            "${selectedHour.toString().padLeft(2, '0')}:00 - ${(selectedHour + 1).toString().padLeft(2, '0')}:00",
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 20),

          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.pop(context); 

                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ReservationsScreen(),
                    ),
                    (route) => false,
                  );
                },
                child: const Text("Terminer",
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}