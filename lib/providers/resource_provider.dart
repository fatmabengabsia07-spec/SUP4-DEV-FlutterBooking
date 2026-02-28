import 'package:flutter/material.dart';
import '../models/resource.dart';
import '../services/resource_service.dart';

class ResourceProvider with ChangeNotifier {

  final ResourceService _service = ResourceService();

  List<Resource> resources = [];
  bool loading = false;

  Stream<List<Resource>> get stream =>
      _service.streamResources();

  Future<void> add(Resource r) async {
    await _service.createResource(r);
  }

  Future<void> update(Resource r) async {
    await _service.updateResource(r);
  }

  Future<void> delete(String id) async {
    await _service.deleteResource(id);
  }
}