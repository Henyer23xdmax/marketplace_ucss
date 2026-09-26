import 'profile.dart';
import 'category.dart';

class ProductImage {
  final String id;
  final String productId;
  final String imageUrl;
  final int displayOrder;

  ProductImage({
    required this.id,
    required this.productId,
    required this.imageUrl,
    this.displayOrder = 0,
  });

  factory ProductImage.fromJson(Map<String, dynamic> json) {
    return ProductImage(
      id: json['id'].toString(),
      productId: json['product_id'].toString(),
      imageUrl: json['image_url'] as String,
      displayOrder: json['display_order'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'image_url': imageUrl,
      'display_order': displayOrder,
    };
  }
}

class Product {
  final String id;
  final String sellerId;
  final String categoryId;
  final String title;
  final String description;
  final double price;
  final int stock;
  final String status; // 'disponible', 'agotado', 'pausado', 'eliminado'
  final DateTime? createdAt;
  final List<ProductImage> images;
  final Profile? seller;
  final Category? category;

  Product({
    required this.id,
    required this.sellerId,
    required this.categoryId,
    required this.title,
    required this.description,
    required this.price,
    required this.stock,
    required this.status,
    this.createdAt,
    this.images = const [],
    this.seller,
    this.category,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    List<ProductImage> parsedImages = [];
    if (json['product_images'] != null && json['product_images'] is List) {
      parsedImages = (json['product_images'] as List)
          .map((img) => ProductImage.fromJson(img as Map<String, dynamic>))
          .toList();
      parsedImages.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    }

    Profile? sellerProfile;
    if (json['seller'] != null && json['seller'] is Map<String, dynamic>) {
      sellerProfile = Profile.fromJson(json['seller'] as Map<String, dynamic>);
    } else if (json['profiles'] != null && json['profiles'] is Map<String, dynamic>) {
      sellerProfile = Profile.fromJson(json['profiles'] as Map<String, dynamic>);
    }

    Category? cat;
    if (json['category'] != null && json['category'] is Map<String, dynamic>) {
      cat = Category.fromJson(json['category'] as Map<String, dynamic>);
    } else if (json['categories'] != null && json['categories'] is Map<String, dynamic>) {
      cat = Category.fromJson(json['categories'] as Map<String, dynamic>);
    }

    return Product(
      id: json['id'].toString(),
      sellerId: json['seller_id'] as String,
      categoryId: json['category_id'].toString(),
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      stock: (json['stock'] as num?)?.toInt() ?? 1,
      status: json['status'] as String? ?? 'disponible',
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
      images: parsedImages,
      seller: sellerProfile,
      category: cat,
    );
  }

  String get mainImageUrl {
    if (images.isNotEmpty) {
      return images.first.imageUrl;
    }
    return '';
  }

  bool get isAvailable => status == 'disponible' && stock > 0;
}
