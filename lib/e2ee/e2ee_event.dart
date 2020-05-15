import 'package:cloud_firestore/cloud_firestore.dart';

abstract class E2eeEvent{}

class E2eeOperationCompleted extends E2eeEvent {}

class E2eeEncryptionEvent extends E2eeEvent {
  E2eeEncryptionEvent(this.encryptedText);
  String encryptedText;
}

class E2eeDecryptionEvent extends E2eeEvent {
  E2eeDecryptionEvent(this.decryptedText, this.timestamp);
  Timestamp timestamp;
  String decryptedText;
}

class E2eeErrorEvent extends E2eeEvent {
  E2eeErrorEvent(this.error);
  final dynamic error;
}

class E2eeInProgressEvent extends E2eeEvent {}