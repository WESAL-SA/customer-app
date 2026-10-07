import 'package:equatable/equatable.dart';

class WesalUser extends Equatable {
  const WesalUser({
    required this.id,
    required this.phone,
    this.name,
    this.email,
    this.photoUrl,
    this.isProfileComplete = false,
  });

  final String id;
  final String phone;
  final String? name;
  final String? email;
  final String? photoUrl;
  final bool isProfileComplete;

  factory WesalUser.fromJson(Map<String, dynamic> json) => WesalUser(
        id: json['id'] as String,
        phone: json['phone'] as String,
        name: json['name'] as String?,
        email: json['email'] as String?,
        photoUrl: json['photoUrl'] as String?,
        isProfileComplete: (json['isProfileComplete'] as bool?) ?? false,
      );

  WesalUser copyWith({
    String? name,
    String? email,
    String? photoUrl,
    bool? isProfileComplete,
  }) =>
      WesalUser(
        id: id,
        phone: phone,
        name: name ?? this.name,
        email: email ?? this.email,
        photoUrl: photoUrl ?? this.photoUrl,
        isProfileComplete: isProfileComplete ?? this.isProfileComplete,
      );

  @override
  List<Object?> get props => [id, phone, name, email, photoUrl, isProfileComplete];
}
