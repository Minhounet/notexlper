import 'package:flutter_test/flutter_test.dart';
import 'package:notexlper/data/datasources/local/fake_workspace_datasource.dart';
import 'package:notexlper/data/repositories/workspace_repository_impl.dart';
import 'package:notexlper/domain/entities/workspace.dart';

void main() {
  late FakeWorkspaceDataSource dataSource;
  late WorkspaceRepositoryImpl repository;

  const testWorkspace = Workspace(
    id: 'ws-1',
    name: 'Test Workspace',
    ownerId: 'actor-1',
    memberIds: ['actor-1'],
  );

  setUp(() {
    dataSource = FakeWorkspaceDataSource(delay: Duration.zero);
    repository = WorkspaceRepositoryImpl(dataSource: dataSource);
  });

  group('WorkspaceRepositoryImpl', () {
    group('createWorkspace', () {
      test('should persist and return the workspace', () async {
        final result = await repository.createWorkspace(testWorkspace);

        expect(result.isRight(), true);
        result.fold(
          (f) => fail('Should not return failure'),
          (ws) {
            expect(ws.id, testWorkspace.id);
            expect(ws.name, testWorkspace.name);
            expect(ws.ownerId, testWorkspace.ownerId);
            expect(ws.memberIds, contains('actor-1'));
          },
        );
      });
    });

    group('getWorkspaceForOwner', () {
      test('should return null when no workspace exists for owner', () async {
        final result = await repository.getWorkspaceForOwner('actor-99');

        expect(result.isRight(), true);
        result.fold(
          (f) => fail('Should not return failure'),
          (ws) => expect(ws, isNull),
        );
      });

      test('should return the workspace after creation', () async {
        await repository.createWorkspace(testWorkspace);

        final result = await repository.getWorkspaceForOwner('actor-1');

        expect(result.isRight(), true);
        result.fold(
          (f) => fail('Should not return failure'),
          (ws) {
            expect(ws, isNotNull);
            expect(ws!.id, 'ws-1');
          },
        );
      });
    });

    group('addMember', () {
      test('should add actor to workspace memberIds', () async {
        await repository.createWorkspace(testWorkspace);

        final result = await repository.addMember('ws-1', 'actor-2');

        expect(result.isRight(), true);
        result.fold(
          (f) => fail('Should not return failure'),
          (ws) {
            expect(ws.memberIds, containsAll(['actor-1', 'actor-2']));
          },
        );
      });

      test('should be idempotent when adding an existing member', () async {
        await repository.createWorkspace(testWorkspace);

        await repository.addMember('ws-1', 'actor-1');
        final result = await repository.addMember('ws-1', 'actor-1');

        expect(result.isRight(), true);
        result.fold(
          (f) => fail('Should not return failure'),
          (ws) {
            final count = ws.memberIds.where((id) => id == 'actor-1').length;
            expect(count, 1);
          },
        );
      });
    });
  });
}
