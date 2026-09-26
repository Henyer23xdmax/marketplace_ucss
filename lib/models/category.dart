import 'package:flutter/cupertino.dart';

class Category {
  final String id;
  final String name;
  final String? icon;
  final String? description;

  Category({required this.id, required this.name, this.icon, this.description});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id']?.toString() ?? '',
      name: (json['name'] ?? json['nombre'] ?? json['categoria'] ?? json['title'] ?? 'Categoría').toString(),
      icon: json['icon'] as String? ?? json['icono'] as String?,
      description: json['description'] as String? ?? json['descripcion'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (icon != null) 'icon': icon,
      if (description != null) 'description': description,
    };
  }

  /// Retorna un icono adecuado estilo iOS según la categoría
  IconData get cupertinoIcon {
    final lower = name.toLowerCase();
    if (lower.contains('libro') || lower.contains('fotocopia')) {
      return CupertinoIcons.book;
    } else if (lower.contains('tecno') || lower.contains('laptop')) {
      return CupertinoIcons.device_laptop;
    } else if (lower.contains('útil') || lower.contains('maqueta')) {
      return CupertinoIcons.pencil;
    } else if (lower.contains('ropa') ||
        lower.contains('uniforme') ||
        lower.contains('mandil')) {
      return CupertinoIcons.bag;
    } else if (lower.contains('comida') ||
        lower.contains('snack') ||
        lower.contains('postre')) {
      return CupertinoIcons.flame;
    } else if (lower.contains('tutoría') || lower.contains('servicio')) {
      return CupertinoIcons.person_2;
    }
    return CupertinoIcons.tag;
  }
}
