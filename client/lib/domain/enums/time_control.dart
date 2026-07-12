enum TimeControl {
  five(5, '5 phút', '⚡'),
  ten(10, '10 phút', '🕐'),
  fifteen(15, '15 phút', '🕒'),
  thirty(30, '30 phút', '🕕');

  final int minutes;
  final String label;
  final String icon;
  const TimeControl(this.minutes, this.label, this.icon);
}
