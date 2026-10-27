/// Quiet hours: 10 PM to 8 AM local. No automatic nudges inside the window.
bool inQuietHours(DateTime now) => now.hour >= 22 || now.hour < 8;

/// True when sunset is right now or within the next 70 minutes.
bool goldenHourSoon(int sunsetMinutes, DateTime now) {
  if (sunsetMinutes < 0) return false;
  final diff = sunsetMinutes - (now.hour * 60 + now.minute);
  return diff >= 0 && diff <= 70;
}
