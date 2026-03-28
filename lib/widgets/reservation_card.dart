import 'dart:io';
import 'package:flutter/material.dart';
import 'package:projet/widgets/app_colors.dart';
import 'package:provider/provider.dart';

import '../models/reservation.dart';
import '../models/resource.dart';
import '../providers/reservation_provider.dart';
import '../services/resource_service.dart';
import '../views/reservations/edit_reservation_screen.dart';
import '../widgets/app_colors.dart';

class ReservationCard extends StatelessWidget {
  final Reservation reservation;

  const ReservationCard({super.key, required this.reservation});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<ReservationProvider>();
    final resourceService = ResourceService();

    final date =
        "${reservation.startAt.day}/${reservation.startAt.month}/${reservation.startAt.year}";

    final time =
        "${reservation.startAt.hour.toString().padLeft(2, '0')}:00 - "
        "${reservation.endAt.hour.toString().padLeft(2, '0')}:00";

    final status = reservation.status;

    Color statusColor;
    IconData statusIcon;

    switch (status) {
      case ReservationStatus.approved:
        statusColor = AppColors.success;
        statusIcon = Icons.check_circle;
        break;
      case ReservationStatus.rejected:
        statusColor = AppColors.primary;
        statusIcon = Icons.cancel;
        break;
      case ReservationStatus.cancelled:
        statusColor = Colors.grey;
        statusIcon = Icons.block;
        break;
      default:
        statusColor = AppColors.warning;
        statusIcon = Icons.access_time;
    }

    return StreamBuilder<Resource?>(
      stream: resourceService.streamResource(reservation.resourceId),
      builder: (context, snapshot) {

        if (!snapshot.hasData) {
          return const SizedBox();
        }

        final resource = snapshot.data!;

        ImageProvider imageProvider;

        if (resource.imageUrl.isNotEmpty &&
            resource.imageUrl.startsWith('http')) {
          imageProvider = NetworkImage(resource.imageUrl);
        } else if (resource.imageUrl.isNotEmpty &&
            File(resource.imageUrl).existsSync()) {
          imageProvider = FileImage(File(resource.imageUrl));
        } else {
          imageProvider =
              const AssetImage("assets/images/default_avatar.jpg");
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 6,
                offset: const Offset(0, 3),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Row(
                children: [

                  CircleAvatar(
                    radius: 28,
                    backgroundImage: imageProvider,
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        Text(
                          resource.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Row(
                          children: [
                            Icon(statusIcon, color: statusColor, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              status.name.toUpperCase(),
                              style: TextStyle(color: statusColor),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 16),
                  const SizedBox(width: 6),
                  Expanded(child: Text(date)),

                  const Icon(Icons.access_time, size: 16),
                  const SizedBox(width: 6),
                  Expanded(child: Text(time)),
                ],
              ),

              const SizedBox(height: 16),

              Row(
                children: [

                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: status == ReservationStatus.cancelled
                          ? null
                          : () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => EditReservationScreen(
                                    reservation: reservation,
                                  ),
                                ),
                              );
                            },
                      icon: const Icon(Icons.edit, color: AppColors.adminColor,),
                      label: const Text("Modifier", style: TextStyle(color: AppColors.adminColor),),
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                      ),
                      onPressed: () async {
                       final confirm = await showDialog(
  context: context,
  builder: (_) => Dialog(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
    ),
    child: Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [

          const Icon(
            Icons.warning_rounded,
            color: AppColors.primary,
            size: 50,
          ),

          const SizedBox(height: 12),

          const Text(
            "Supprimer la réservation",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 10),

          const Text(
            "Voulez-vous vraiment supprimer cette réservation ?",
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),

          const SizedBox(height: 20),

          Row(
            children: [

              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text("Annuler"),
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white, 
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text("Supprimer"),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  ),
);

                        if (confirm == true) {
                          await provider.delete(reservation.id);
                        }
                      },
                      icon: const Icon(Icons.delete,color: Colors.white),
                      label: const Text("Supprimer", style: TextStyle(color: Colors.white),),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}