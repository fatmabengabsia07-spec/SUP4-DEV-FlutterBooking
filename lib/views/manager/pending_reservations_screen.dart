import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/reservation_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/reservation.dart';
import '../../widgets/app_colors.dart';

class PendingReservationsScreen extends StatelessWidget {
  const PendingReservationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.read<AuthProvider>();
    final managerId = authProvider.currentUser!.id;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Demandes en attente",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Validez ou refusez les réservations",
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Consumer<ReservationProvider>(
              builder: (context, provider, _) {
                return StreamBuilder<List<Reservation>>(
                  stream: provider.pendingReservations(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final reservations = snapshot.data!;

                    if (reservations.isEmpty) {
                      return const Center(
                        child: Text("Aucune réservation en attente"),
                      );
                    }

                    return ListView.separated(
                      itemCount: reservations.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final reservation = reservations[index];

                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Réservation #${reservation.id.substring(0, 6)}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text("Ressource : ${reservation.resourceName}"),
                                Text("Utilisateur : ${reservation.userName}"),
                                Text("Début : ${reservation.startAt}"),
                                Text("Fin : ${reservation.endAt}"),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: AppColors.success,
                                          foregroundColor: Colors.white,
                                        ),
                                        onPressed: () {
                                          _showDecisionDialog(
                                            context: context,
                                            title: "Approuver la réservation",
                                            onConfirm: (comment) async {
                                              await provider.approve(
                                                reservationId: reservation.id,
                                                managerId: managerId,
                                                comment: comment,
                                              );
                                            },
                                          );
                                        },
                                        icon: const Icon(Icons.check),
                                        label: const Text("Approuver"),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                          foregroundColor: Colors.white,
                                        ),
                                        onPressed: () {
                                          _showDecisionDialog(
                                            context: context,
                                            title: "Refuser la réservation",
                                            onConfirm: (comment) async {
                                              await provider.reject(
                                                reservationId: reservation.id,
                                                managerId: managerId,
                                                comment: comment,
                                              );
                                            },
                                          );
                                        },
                                        icon: const Icon(Icons.close),
                                        label: const Text("Refuser"),
                                      ),
                                    ),
                                  ],
                                ),
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

void _showDecisionDialog({
  required BuildContext context,
  required String title,
  required Future<void> Function(String? comment) onConfirm,
}) {
  final controller = TextEditingController();

  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(
        title,
        style: Theme.of(context).textTheme.headline6?.copyWith(
              color: AppColors.primary,
            ),
      ),
      content: TextField(
        controller: controller,
        maxLines: 3,
        decoration: InputDecoration(
          hintText: "Ajouter un commentaire (optionnel)",
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12), 
          ),
          filled: true,
          fillColor: AppColors.background, 
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            "Annuler",
            style: TextStyle(
              color: AppColors.primary, 
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () async {
            await onConfirm(
              controller.text.trim().isEmpty ? null : controller.text.trim(),
            );
            if (context.mounted) Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.success, 
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(
            "Confirmer",
            style: TextStyle(color: Colors.white), 
          ),
        ),
      ],
    ),
  );
}
}