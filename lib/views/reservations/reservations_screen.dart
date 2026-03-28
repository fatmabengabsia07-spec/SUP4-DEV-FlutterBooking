import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

import '../../providers/reservation_provider.dart';
import '../../models/reservation.dart';
import '../../widgets/reservation_card.dart';
import '../../widgets/app_colors.dart';

class ReservationsScreen extends StatelessWidget {
  const ReservationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userId =
        firebase_auth.FirebaseAuth.instance.currentUser!.uid;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Mes Réservations",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            "Historique et à venir",
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),

          Expanded(
            child: Consumer<ReservationProvider>(
              builder: (context, provider, _) {

                return StreamBuilder<List<Reservation>>(
                  stream: provider.userReservations(userId),
                  builder: (context, snapshot) {

                    if (!snapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    final reservations = snapshot.data!;

                    if (reservations.isEmpty) {
                      return const Center(
                        child: Text("Aucune réservation"),
                      );
                    }

                    return ListView.separated(
                      itemCount: reservations.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 16),
                      itemBuilder: (context, index) {

                        final reservation = reservations[index];

                        return ReservationCard(
                          reservation: reservation,
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