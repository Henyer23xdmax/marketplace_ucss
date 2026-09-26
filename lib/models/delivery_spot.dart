class DeliverySpot {
  final String id;
  final String name;
  final String? locationDetails;
  final String? campusName;

  DeliverySpot({
    required this.id,
    required this.name,
    this.locationDetails,
    this.campusName,
  });

  factory DeliverySpot.fromJson(Map<String, dynamic> json) {
    return DeliverySpot(
      id: json['id'].toString(),
      name: json['name'] as String? ?? 'Punto de Encuentro',
      locationDetails: json['reference'] as String? ?? json['location_details'] as String?,
      campusName: json['campus'] as String? ?? json['campus_name'] as String? ?? 'Lima Norte',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      if (locationDetails != null) 'location_details': locationDetails,
      if (campusName != null) 'campus_name': campusName,
    };
  }
}
