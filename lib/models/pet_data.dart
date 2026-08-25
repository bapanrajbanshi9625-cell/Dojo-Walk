class PetData {
  final String name;
  final int age;
  final String breed;
  final String behaviour;

  const PetData({
    required this.name,
    required this.age,
    required this.breed,
    required this.behaviour,
  });

  PetData copyWith({
    String? name,
    int? age,
    String? breed,
    String? behaviour,
  }) {
    return PetData(
      name: name ?? this.name,
      age: age ?? this.age,
      breed: breed ?? this.breed,
      behaviour: behaviour ?? this.behaviour,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'age': age,
      'breed': breed,
      'behaviour': behaviour,
    };
  }

  factory PetData.fromMap(Map<String, dynamic> map) {
    return PetData(
      name: map['name']?.toString() ?? '',
      age: map['age'] is int
          ? map['age'] as int
          : int.tryParse(map['age']?.toString() ?? '') ?? 0,
      breed: map['breed']?.toString() ?? '',
      behaviour: map['behaviour']?.toString() ?? '',
    );
  }
}
