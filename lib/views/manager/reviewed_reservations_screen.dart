import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/reservation_provider.dart';
import '../../models/reservation.dart';
import '../../widgets/app_colors.dart';

class ReviewedReservationsScreen extends StatelessWidget {
  const ReviewedReservationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final managerId = context.read<AuthProvider>().currentUser!.id;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Réservations traitées",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Historique de vos validations et refus",
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Consumer<ReservationProvider>(
              builder: (context, provider, _) {
                return StreamBuilder<List<Reservation>>(
                  stream: provider.reviewedByManager(managerId),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final reservations = snapshot.data!;

                    if (reservations.isEmpty) {
                      return const Center(
                        child: Text("Aucune réservation traitée"),
                      );
                    }

                    return ListView.separated(
                      itemCount: reservations.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final reservation = reservations[index];
                        final approved =
                            reservation.status == ReservationStatus.approved;

                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  approved ? AppColors.success : AppColors.error,
                              child: Icon(
                                approved ? Icons.check : Icons.close,
                                color: Colors.white,
                              ),
                            ),
                            title: Text(
                              "Réservation #${reservation.id.substring(0, 6)}",   
                            ),
                            
                            
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Ressource : ${reservation.resourceName}"),
                                Text("Utilisateur : ${reservation.userName}"),
                                Text("Début : ${reservation.startAt}"),
                                Text("Fin : ${reservation.endAt}"),
                                Text("Statut : ${reservation.status.name}"),
                                if ((reservation.managerComment ?? '').isNotEmpty)
                                  Text("Commentaire : ${reservation.managerComment}"),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}