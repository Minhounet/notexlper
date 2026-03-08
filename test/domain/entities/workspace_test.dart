import 'package:flutter_test/flutter_test.dart';
import 'package:notexlper/domain/entities/workspace.dart';

void main() {
  const workspace = Workspace(
    id: 'ws-1',
    name: "Alice's Workspace",
    ownerId: 'actor-1',
    memberIds: ['actor-1', 'actor-2'],
  );

  group('Workspace', () {
    test('isMember returns true for existing member', () {
      expect(workspace.isMember('actor-1'), true);
      expect(workspace.isMember('actor-2'), true);
    });

    test('isMember returns false for non-member', () {
      expect(workspace.isMember('actor-99'), false);
    });

    test('copyWith replaces only specified fields', () {
      final updated = workspace.copyWith(name: 'Team Workspace');
      expect(updated.name, 'Team Workspace');
      expect(updated.id, workspace.id);
      expect(updated.ownerId, workspace.ownerId);
      expect(updated.memberIds, workspace.memberIds);
    });

    test('equality is based on props', () {
      const same = Workspace(
        id: 'ws-1',
        name: "Alice's Workspace",
        ownerId: 'actor-1',
        memberIds: ['actor-1', 'actor-2'],
      );
      expect(workspace, equals(same));
    });

    test('different ids are not equal', () {
      final other = workspace.copyWith(id: 'ws-2');
      expect(workspace, isNot(equals(other)));
    });
  });
}
