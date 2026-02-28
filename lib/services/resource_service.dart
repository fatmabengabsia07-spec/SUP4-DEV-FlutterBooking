import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/resource.dart';

class ResourceService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<Resource>> streamResources() {
    return _db.collection('resources')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => Resource.fromFirestore(d.id, d.data()))
            .toList());
  }

  Future<void> createResource(Resource resource) async {
    await _db.collection('resources').add(resource.toMap());
  }

  Future<void> updateResource(Resource resource) async {
    await _db.collection('resources')
        .doc(resource.id)
        .update(resource.toMap());
  }

  Future<void> deleteResource(String id) async {
    await _db.collection('resources').doc(id).delete();
  }
} 