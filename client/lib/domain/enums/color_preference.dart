enum ColorPreference {
  white('white', 'Trắng', '♔'),
  black('black', 'Đen', '♚'),
  random('random', 'Ngẫu nhiên', '🎲');

  final String value;
  final String label;
  final String icon;
  const ColorPreference(this.value, this.label, this.icon);
}
