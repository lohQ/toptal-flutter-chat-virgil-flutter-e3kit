import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  Message(this.authorId, this.timestamp, this.value, [this.outgoing = false]);

  final String authorId;
  final Timestamp timestamp;
  String value;
  final bool outgoing; // True if this message was sent by the current user
}

class MessageToDisplay {
  final String value;
  final bool outgoing;
  MessageToDisplay(this.value, this.outgoing);
}