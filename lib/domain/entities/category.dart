import 'package:equatable/equatable.dart';

/// Represents a category that can be assigned to checklist items
/// in order to group them.
class Category extends Equatable {
  final String id;
  final String name;
  final int colorValue;

  const Category({
    required this.id,
    required this.name,
    required this.colorValue,
  });

  Category copyWith({
    String? id,
    String? name,
    int? colorValue,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      colorValue: colorValue ?? this.colorValue,
    );
  }

  @override
  List<Object?> get props => [id, name, colorValue];
}
