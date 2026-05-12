import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../models/reservation.dart';
import '../../models/resource.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/reservation_provider.dart';
import '../../views/home/home_screen.dart';
import '../../widgets/app_colors.dart';

class ReservationScreen extends StatelessWidget {
  final Resource resource;

  const ReservationScreen({
    super.key,
    required this.resource,
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
    final rp = Provider.of<ReservationProvider>(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final auth = context.read<AuthProvider>();
    final isManager = auth.currentUser?.role == UserRole.manager ||
        auth.selectedRole == UserRole.manager;
    final requiresApproval = !isManager;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        title: Text(
          resource.name,
          style: const TextStyle(color: AppColors.textPrimary),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
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
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
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
                        Text(
                          resource.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          resource.isSalle
                              ? "${resource.type} • ${resource.capacity} pers."
                              : resource.type,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                          ),
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
              child: Builder(builder: (context) {
                final firstDay = today;
                final lastDay = today.add(const Duration(days: 365));

                return TableCalendar(
                  firstDay: firstDay,
                  lastDay: lastDay,
                  focusedDay:
                      Provider.of<ReservationProvider>(context).selectedDay,
                  selectedDayPredicate: (day) => isSameDay(day,
                      Provider.of<ReservationProvider>(context).selectedDay),
                  enabledDayPredicate: (day) {
                    final normalized = DateTime(day.year, day.month, day.day);
                    return !normalized.isBefore(today);
                  },
                  onDaySelected: (selectedDay, focusedDay) {
                    Provider.of<ReservationProvider>(context, listen: false)
                        .setDay(selectedDay);
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
                );
              }),
            ),
            const SizedBox(height: 12),
            Consumer<ReservationProvider>(
              builder: (context, rp, _) {
                return StreamBuilder<List<Reservation>>(
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

                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: hours.map((h) {
                          final isReserved = reservedHours.contains(h);
                          final selectedDate = DateTime(
                            rp.selectedDay.year,
                            rp.selectedDay.month,
                            rp.selectedDay.day,
                          );
                          final slotStart = DateTime(
                            selectedDate.year,
                            selectedDate.month,
                            selectedDate.day,
                            h,
                          );
                          final isPastHour = slotStart.isBefore(now);
                          final isUnavailable = isReserved || isPastHour;
                          final isSelected = rp.selectedHour == h;

                          return GestureDetector(
                            onTap: isUnavailable ? null : () => rp.setHour(h),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.success,
                                  width: isSelected ? 2 : 1,
                                ),
                                color: isUnavailable
                                    ? Colors.grey.shade200
                                    : (isSelected
                                        ? AppColors.primary.withOpacity(0.1)
                                        : Colors.white),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "${h.toString().padLeft(2, '0')}:00",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isUnavailable
                                          ? Colors.grey
                                          : Colors.black,
                                    ),
                                  ),
                                  Text(
                                    isReserved
                                        ? "Indisponible"
                                        : (isPastHour
                                            ? "Passée"
                                            : (isSelected
                                                ? "Sélectionné"
                                                : "Disponible")),
                                    style: TextStyle(
                                      color: isUnavailable
                                          ? Colors.grey
                                          : AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  },
                );
              },
            ),
            if (rp.error != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red),
                  ),
                  child: Text(
                    rp.error!,
                    style: const TextStyle(color: Colors.red),
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
                  onPressed: rp.loading
                      ? null
                      : () async {
                          final uid = firebase_auth
                              .FirebaseAuth.instance.currentUser?.uid;

                          if (uid == null) return;

                          if (rp.selectedHour == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Veuillez choisir une heure"),
                              ),
                            );
                            return;
                          }

                          final ok = await rp.confirmReservation(
                            resourceId: resource.id,
                            userId: uid,
                            requiresApproval: requiresApproval,
                            durationMinutes: 60,
                          );

                          if (ok && context.mounted) {
                            showDialog(
                              context: context,
                              barrierDismissible: false,
                              builder: (_) => _SuccessDialog(
                                resource: resource,
                                selectedDay: rp.selectedDay,
                                selectedHour: rp.selectedHour!,
                              ),
                            );
                          }
                        },
                  child: rp.loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Continuer",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
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
    final userRole =
        context.read<AuthProvider>().currentUser?.role ?? UserRole.user;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
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
          const Icon(
            Icons.check_circle,
            size: 60,
            color: AppColors.success,
          ),
          const SizedBox(height: 12),
          const Text(
            "Réservation confirmée !",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Le ${selectedDay.day}/${selectedDay.month}/${selectedDay.year}\n"
            "${selectedHour.toString().padLeft(2, '0')}:00 - ${(selectedHour + 1).toString().padLeft(2, '0')}:00",
            textAlign: TextAlign.center,
          ),
          if (userRole == UserRole.manager) ...[
            const SizedBox(height: 10),
            const Text(
              "Réservation approuvée automatiquement.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.success,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () async {
                  Navigator.of(context, rootNavigator: true).pop();

                  await Future.delayed(const Duration(milliseconds: 100));

                  if (!context.mounted) return;

                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (_) => HomeScreen(
                        role: userRole,
                        initialIndex: userRole == UserRole.manager ||
                                userRole == UserRole.user
                            ? 1
                            : 0,
                      ),
                    ),
                    (route) => false,
                  );
                },
                child: const Text(
                  "Terminer",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
