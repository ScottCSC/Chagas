import 'dart:async';

class Debouncer {
  Debouncer({this.milliseconds = 350});

  final int milliseconds;
  Timer? _t;

  void run(void Function() action) {
    _t?.cancel();
    _t = Timer(Duration(milliseconds: milliseconds), action);
  }

  void dispose() => _t?.cancel();
}
