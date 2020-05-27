import 'package:flutter/services.dart';

abstract class E2eeEvent{}

class E2eeOperationCompleted extends E2eeEvent {}

class E2eeErrorEvent extends E2eeEvent {
  E2eeErrorEvent(this.error);
  final PlatformException error;
}

class E2eeInProgressEvent extends E2eeEvent {}