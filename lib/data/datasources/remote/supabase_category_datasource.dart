import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../domain/entities/category.dart';
import '../category_datasource.dart';

/// Supabase implementation of [CategoryDataSource].
class SupabaseCategoryDataSource implements CategoryDataSource {
  final SupabaseClient _client;

  SupabaseCategoryDataSource(this._client);

  Category _fromJson(Map<String, dynamic> json) => Category(
        id: json['id'] as String,
        name: json['name'] as String,
        colorValue: json['color_value'] as int,
      );

  Map<String, dynamic> _toJson(Category category) => {
        'id': category.id,
        'name': category.name,
        'color_value': category.colorValue,
      };

  @override
  Future<List<Category>> getAllCategories() async {
    final data = await _client.from('categories').select();
    return data.map(_fromJson).toList();
  }

  @override
  Future<Category?> getCategoryById(String id) async {
    final data = await _client
        .from('categories')
        .select()
        .eq('id', id)
        .maybeSingle();
    return data != null ? _fromJson(data) : null;
  }

  @override
  Future<Category> createCategory(Category category) async {
    final data = await _client
        .from('categories')
        .insert(_toJson(category))
        .select()
        .single();
    return _fromJson(data);
  }

  @override
  Future<Category> updateCategory(Category category) async {
    final data = await _client
        .from('categories')
        .update(_toJson(category))
        .eq('id', category.id)
        .select()
        .single();
    return _fromJson(data);
  }

  @override
  Future<void> deleteCategory(String id) async {
    await _client.from('categories').delete().eq('id', id);
  }
}
