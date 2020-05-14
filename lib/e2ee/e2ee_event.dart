import 'package:cloud_firestore/cloud_firestore.dart';

abstract class E2eeEvent{}

// initialize, register, backupPrivateKey OR 
// initialize, restorePrivateKey
class E2eeInitializeEvent extends E2eeEvent {}

// cleanUp local private key
class E2eeLogoutEvent extends E2eeEvent {}

// findUsers and store their public key
class E2eeStartChatEvent extends E2eeEvent {}

// encrypt with public key
class E2eeEncryptionEvent extends E2eeEvent {
  E2eeEncryptionEvent(this.encryptedText);
  String encryptedText;
}

// decrypt with private key
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