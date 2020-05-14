import 'package:cloud_firestore/cloud_firestore.dart';

class E2eeState {
  final bool isLoading;
  final bool error;
  final Timestamp messageTimestamp;
  final String returnString;

  E2eeState._internal(this.isLoading, {this.error = false, this.messageTimestamp, this.returnString = ""});

  factory E2eeState.initial() => E2eeState._internal(false);
  factory E2eeState.error() => E2eeState._internal(false, error: true);
  factory E2eeState.loading(bool isLoading) => E2eeState._internal(isLoading);
  factory E2eeState.encrypt(String cipherText)
     => E2eeState._internal(false, returnString: cipherText);
  factory E2eeState.decrypt(String plainText, Timestamp timestamp)
     => E2eeState._internal(false, messageTimestamp: timestamp, returnString: plainText);
}