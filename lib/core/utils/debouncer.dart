import 'dart:async';
import 'package:flutter/foundation.dart';

/// Trì hoãn một hành động cho đến khi không còn lời gọi mới trong [delay].
class Debouncer {
  final Duration delay;
  Timer? _timer;

  Debouncer({this.delay = const Duration(milliseconds: 400)});

  void run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  void cancel() => _timer?.cancel();
}

