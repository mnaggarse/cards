class Tag {
  final int? id;
  final String name;

  const Tag({this.id, required this.name});

  factory Tag.fromMap(Map<String, dynamic> map) =>
      Tag(id: map['id'] as int?, name: map['name'] as String);

  Map<String, dynamic> toMap() => {'id': id, 'name': name};

  @override
  bool operator ==(Object other) => other is Tag && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
