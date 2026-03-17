
class UserProfile {
  const UserProfile({
    required this.id,
    required this.firebaseUid,
    required this.name,
    required this.email,
    this.phone = '',
    this.address = '',
    this.profilePhoto = '',
    required this.initials,
    required this.pets,
    required this.familyGroup,
  });

  final String id;
  final String firebaseUid;
  final String name;
  final String email;
  final String phone;
  final String address;
  final String profilePhoto;
  final String initials;
  final List<dynamic> pets;
  final List<dynamic> familyGroup;

  int get petCount => pets.length;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      firebaseUid: json['firebaseUid'] as String,
      name: json['name'] as String,
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      address: json['address'] as String? ?? '',
      profilePhoto: json['profilePhoto'] as String? ?? '',
      initials: json['initials'] as String? ?? '',
      pets: (json['pets'] as List<dynamic>?) ?? const [],
      familyGroup: (json['familyGroup'] as List<dynamic>?) ?? const [],
    );
  }
}
