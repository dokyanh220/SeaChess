enum AiDifficulty {
  beginner(0, 'Mới chơi', '🌱'),
  easy(1, 'Dễ', '😊'),
  medium(2, 'Trung bình', '🤔'),
  hard(3, 'Khó', '🔥');

  final int value;
  final String label;
  final String icon;
  const AiDifficulty(this.value, this.label, this.icon);
}
