enum PlayerRole { citizen, undercover, mrWhite }

class Player {
  final String id;
  final String name;
  final PlayerRole? role;
  final String? word;
  final bool isEliminated;

  const Player({
    required this.id,
    required this.name,
    this.role,
    this.word,
    this.isEliminated = false,
  });

  Player copyWith({
    String? id,
    String? name,
    PlayerRole? role,
    String? word,
    bool? isEliminated,
  }) {
    return Player(
      id: id ?? this.id,
      name: name ?? this.name,
      role: role ?? this.role,
      word: word ?? this.word,
      isEliminated: isEliminated ?? this.isEliminated,
    );
  }
}
