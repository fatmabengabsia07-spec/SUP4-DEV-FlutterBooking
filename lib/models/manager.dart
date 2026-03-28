class Manager {
  final String id;
  final String name;
  final String email;

  Manager({
    required this.id,
    required this.name,
    required this.email,
  });

  factory Manager.fromFirestore(String id, Map<String, dynamic> data) {
    return Manager(
      id: id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'createdAt': DateTime.now(),
    };
  }
}