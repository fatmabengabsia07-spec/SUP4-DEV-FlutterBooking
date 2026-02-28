class Resource {
  final String id;
  final String name;
  final String type;
  final int capacity;
  final String description;
  final String imageUrl;

  Resource({
    required this.id,
    required this.name,
    required this.type,
    required this.capacity,
    required this.description,
    required this.imageUrl,
  });

  factory Resource.fromFirestore(String id, Map<String, dynamic> data) {
    return Resource(
      id: id,
      name: data['name'] ?? '',
      type: data['type'] ?? '',
      capacity: data['capacity'] ?? 0,
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'type': type,
      'capacity': capacity,
      'description': description,
      'imageUrl': imageUrl,
      'createdAt': DateTime.now(),
    };
  }
}