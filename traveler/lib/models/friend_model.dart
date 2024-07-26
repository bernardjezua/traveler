import 'dart:convert';

class Friend {
  String? id;
  String name;
  String nickname;
  String age;
  bool isSingle;
  double happinessLevel;
  String vision;
  String motto;
  bool isVerified;
  String? imageUrl;

  Friend({
    this.id,
    required this.name,
    required this.nickname,
    required this.age,
    required this.isSingle,
    required this.happinessLevel,
    required this.vision,
    required this.motto,
    required this.isVerified,
    this.imageUrl,
  });

  factory Friend.fromJson(Map<String, dynamic> json) {
    return Friend(
      id: json['id'],
      name: json['name'],
      nickname: json['nickname'],
      age: json['age'],
      isSingle: json['isSingle'],
      happinessLevel: (json['happinessLevel'] as num).toDouble(),
      vision: json['vision'],
      motto: json['motto'],
      isVerified: json['isVerified'],
      imageUrl: json['imageUrl'],
    );
  }

  static List<Friend> fromJsonArray(String jsonData) {
    final Iterable<dynamic> data = jsonDecode(jsonData);
    return data.map<Friend>((dynamic d) => Friend.fromJson(d)).toList();
  }

  Map<String, dynamic> toJson(Friend friend) {
    return {
      'id': friend.id,
      'name': friend.name,
      'nickname': friend.nickname,
      'age': friend.age,
      'isSingle': friend.isSingle,
      'happinessLevel': friend.happinessLevel,
      'vision': friend.vision,
      'motto': friend.motto,
      'isVerified': friend.isVerified,
      'imageUrl': friend.imageUrl,
    };
  }
}