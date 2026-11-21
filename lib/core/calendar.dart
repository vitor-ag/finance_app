DateTime calendarDate(DateTime date) =>
    DateTime(date.year, date.month, date.day);

DateTime dateWithClampedDay(int year, int month, int day) {
  final lastDay = DateTime(year, month + 1, 0).day;
  return DateTime(year, month, day > lastDay ? lastDay : day);
}
