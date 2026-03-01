import 'package:equatable/equatable.dart';

/// Represents a collaborative workspace that groups actors together.
///
/// A workspace is owned by one actor and can have multiple members.
/// Notes and categories are visible to all workspace members.
class Workspace extends Equatable {
  final String id;
  final String name;

  /// The actor who created and owns this workspace.
  final String ownerId;

  /// IDs of all actors who are members (including the owner).
  final List<String> memberIds;

  const Workspace({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.memberIds,
  });

  bool isMember(String actorId) => memberIds.contains(actorId);

  Workspace copyWith({
    String? id,
    String? name,
    String? ownerId,
    List<String>? memberIds,
  }) {
    return Workspace(
      id: id ?? this.id,
      name: name ?? this.name,
      ownerId: ownerId ?? this.ownerId,
      memberIds: memberIds ?? this.memberIds,
    );
  }

  @override
  List<Object?> get props => [id, name, ownerId, memberIds];
}
