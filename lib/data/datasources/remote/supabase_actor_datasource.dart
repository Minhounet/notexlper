import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../domain/entities/actor.dart';
import '../actor_datasource.dart';

/// Supabase implementation of [ActorDataSource].
class SupabaseActorDataSource implements ActorDataSource {
  final SupabaseClient _client;

  SupabaseActorDataSource(this._client);

  Actor _fromJson(Map<String, dynamic> json) => Actor(
        id: json['id'] as String,
        name: json['name'] as String,
        colorValue: json['color_value'] as int,
      );

  @override
  Future<List<Actor>> getAllActors() async {
    final data = await _client.from('actors').select();
    return data.map(_fromJson).toList();
  }

  @override
  Future<Actor?> getActorById(String id) async {
    final data =
        await _client.from('actors').select().eq('id', id).maybeSingle();
    return data != null ? _fromJson(data) : null;
  }

  @override
  Future<Actor> createActor(Actor actor) async {
    final data = await _client.from('actors').insert({
      'id': actor.id,
      'name': actor.name,
      'color_value': actor.colorValue,
    }).select().single();
    return _fromJson(data);
  }
}
