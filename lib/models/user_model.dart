class UserModel {
  int? id;
  String fullname;
  String email;
  String password;
  String? phone;
  String? createdAt;
  String? photo;

  UserModel({
    this.id,
    required this.fullname,
    required this.email,
    required this.password,
    this.phone,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fullname': fullname,
      'email': email,
      'password': password,
      'phone': phone,
      'created_at': createdAt,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'],
      fullname: map['fullname'],
      email: map['email'],
      password: map['password'],
      phone: map['phone'],
      createdAt: map['created_at'],
    );
  }
}