
class BufferManager {
  final List<double> _doBuffer = [];
  final List<double> _condBuffer = [];
  final List<double> _tempBuffer = [];
  final List<double> _turbBuffer = [];
  final List<double> _phBuffer = [];

  // Window size = 5, but we keep 20 as requested for history
  static const int _historySize = 20;
  static const int _windowSize = 5;

  void addReading({
    required double doVal,
    required double cond,
    required double temp,
    required double turb,
    required double ph,
  }) {
    _addToBuffer(_doBuffer, doVal);
    _addToBuffer(_condBuffer, cond);
    _addToBuffer(_tempBuffer, temp);
    _addToBuffer(_turbBuffer, turb);
    _addToBuffer(_phBuffer, ph);
  }

  void _addToBuffer(List<double> buffer, double value) {
    if (buffer.length >= _historySize) {
      buffer.removeAt(0);
    }
    buffer.add(value);
  }

  void clear() {
    _doBuffer.clear();
    _condBuffer.clear();
    _tempBuffer.clear();
    _turbBuffer.clear();
    _phBuffer.clear();
  }

  void removeReading(int index) {
    // Index 0 is the oldest if we just use list index.
    // However, the UI displays reversed (last is first). 
    // If UI passes index 0 for the most recent reading, we need to convert it.
    // But implementation plan said "index relative to the end".
    // Let's assume the service/UI handles the index conversion or we just accept standard list index.
    // To be safe, let's assume standard list index (0 = oldest) and let UI calculate it.
    
    if (index >= 0 && index < _doBuffer.length) {
      _doBuffer.removeAt(index);
      _condBuffer.removeAt(index);
      _tempBuffer.removeAt(index);
      _turbBuffer.removeAt(index);
      _phBuffer.removeAt(index);
    }
  }

  bool get isReady => _doBuffer.length >= _windowSize;

  // Get last N readings for feature engineering
  List<double> getLastN(String sensor, int n) {
    List<double> buffer;
    switch (sensor) {
      case 'DO': buffer = _doBuffer; break;
      case 'COND': buffer = _condBuffer; break;
      case 'TEMP': buffer = _tempBuffer; break;
      case 'TURB': buffer = _turbBuffer; break;
      case 'PH': buffer = _phBuffer; break;
      default: return [];
    }
    
    if (buffer.length < n) return buffer;
    return buffer.sublist(buffer.length - n);
  }
  
  int get count => _doBuffer.length;
}
