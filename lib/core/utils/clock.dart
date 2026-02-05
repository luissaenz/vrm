/// Interface for clock abstraction to enable deterministic time handling
abstract class IClock {
  /// Returns the current date and time
  DateTime now();
}

/// Production implementation using system time
class SystemClock implements IClock {
  const SystemClock();

  @override
  DateTime now() => DateTime.now();
}

/// Fixed clock for testing and deterministic behavior
class FixedClock implements IClock {
  final DateTime _fixedTime;

  const FixedClock(this._fixedTime);

  @override
  DateTime now() => _fixedTime;
}

/// Mock clock that can be advanced manually for testing
class MockClock implements IClock {
  DateTime _currentTime;

  MockClock([DateTime? initialTime])
    : _currentTime = initialTime ?? DateTime.now();

  @override
  DateTime now() => _currentTime;

  /// Advance the clock by the given duration
  void advance(Duration duration) {
    _currentTime = _currentTime.add(duration);
  }

  /// Set the clock to a specific time
  void setTime(DateTime time) {
    _currentTime = time;
  }
}
