import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../domain/entities/workspace.dart';
import '../workspace_datasource.dart';

/// Supabase implementation of [WorkspaceDataSource].
class SupabaseWorkspaceDataSource implements WorkspaceDataSource {
  final SupabaseClient _client;

  SupabaseWorkspaceDataSource(this._client);

  Workspace _fromJson(Map<String, dynamic> json) {
    final members = (json['workspace_members'] as List<dynamic>? ?? [])
        .map((m) => m['actor_id'] as String)
        .toList();
    return Workspace(
      id: json['id'] as String,
      name: json['name'] as String,
      ownerId: json['owner_id'] as String,
      memberIds: members,
    );
  }

  @override
  Future<Workspace?> getWorkspaceByOwnerId(String ownerId) async {
    final data = await _client
        .from('workspaces')
        .select('*, workspace_members(actor_id)')
        .eq('owner_id', ownerId)
        .maybeSingle();
    return data != null ? _fromJson(data) : null;
  }

  @override
  Future<Workspace> createWorkspace(Workspace workspace) async {
    await _client.from('workspaces').insert({
      'id': workspace.id,
      'name': workspace.name,
      'owner_id': workspace.ownerId,
    });
    // Add the owner as the first member.
    await _client.from('workspace_members').insert({
      'workspace_id': workspace.id,
      'actor_id': workspace.ownerId,
    });
    // Re-fetch to get a consistent object back.
    final data = await _client
        .from('workspaces')
        .select('*, workspace_members(actor_id)')
        .eq('id', workspace.id)
        .single();
    return _fromJson(data);
  }

  @override
  Future<Workspace> addMember(String workspaceId, String actorId) async {
    await _client.from('workspace_members').upsert({
      'workspace_id': workspaceId,
      'actor_id': actorId,
    });
    final data = await _client
        .from('workspaces')
        .select('*, workspace_members(actor_id)')
        .eq('id', workspaceId)
        .single();
    return _fromJson(data);
  }
}
