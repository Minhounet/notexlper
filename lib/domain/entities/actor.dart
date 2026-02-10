import 'package:equatable/equatable.dart';

/// Represents a person in the workspace who can be assigned to checklists.
class Actor extends Equatable {
  final String id;
  final String name;
  final int colorValue;

  const Actor({
    required this.id,
    required this.name,
    required this.colorValue,
  });

  Actor copyWith({
    String? id,
    String? name,
    int? colorValue,
  }) {
    return Actor(
      id: id ?? this.id,
      name: name ?? this.name,
      colorValue: colorValue ?? this.colorValue,
    );
  }

  @override
  List<Object?> get props => [id, name, colorValue];
}
