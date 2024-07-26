import 'dart:convert';

class User {
  String? id;
  String email;
  String name;
  String username;
  List<dynamic> slambook;
  List<String> contact;
  String? imageUrl;

  User({
    this.id,
    required this.email,
    required this.name,
    required this.username,
    required this.contact,
    required this.slambook,
    this.imageUrl,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    var contactNumbersFromJson = json['contactNumbers'] as List;
    List<String> contactNumList = List<String>.from(contactNumbersFromJson);

    return User(
      id: json['id'],
      email: json['email'],
      name: json['name'],
      username: json['username'],
      contact: contactNumList,
      slambook: json['slambook'],
      imageUrl: json['imageUrl'],
    );
  }

  Map<String, dynamic> toJson(User user) {
    return {
      'email': user.email,
      'name': user.name,
      'username': user.username,
      'contact': user.contact,
      'slambook': user.slambook,
      'imageUrl': user.imageUrl,
    };
  }

  static List<User> fromJsonArray(String jsonData) {
    final Iterable<dynamic> data = jsonDecode(jsonData);
    return data.map<User>((dynamic d) => User.fromJson(d)).toList();
  }
}
