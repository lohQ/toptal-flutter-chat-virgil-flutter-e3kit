import '../model/message.dart';

abstract class InstantMessagingEvent {}

class MessageReceivedEvent extends InstantMessagingEvent {
  final Message message;

  MessageReceivedEvent(this.message);
}

class MessageSentEvent extends InstantMessagingEvent {}

class MessageSendErrorEvent extends InstantMessagingEvent {}