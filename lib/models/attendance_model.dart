class AttendanceModel {
  int? id;
  int userId;
  String checkIn;
  String? checkOut;
  double latitude;
  double longitude;
  String address;
  String status;
  String? createdAt;

  AttendanceModel({
    this.id,
    required this.userId,
    required this.checkIn,
    this.checkOut,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.status,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'check_in': checkIn,
      'check_out': checkOut,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'status': status,
      'created_at': createdAt,
    };
  }

  factory AttendanceModel.fromMap(Map<String, dynamic> map) {
    return AttendanceModel(
      id: map['id'],
      userId: map['user_id'],
      checkIn: map['check_in'],
      checkOut: map['check_out'],
      latitude: map['latitude'],
      longitude: map['longitude'],
      address: map['address'],
      status: map['status'],
      createdAt: map['created_at'],
    );
  }
}