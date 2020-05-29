import '../model/user.dart';

abstract class CreateChatroomEvent {}

class ChatroomUserListUpdatedEvent extends CreateChatroomEvent {
  ChatroomUserListUpdatedEvent(this.users);

  final List<User> users;
}

class ChatroomRequestListUpdatedEvent extends CreateChatroomEvent {
  final List<String> uids;
  ChatroomRequestListUpdatedEvent(this.uids);
}

class CreateChatroomRequestedEvent extends CreateChatroomEvent {}

class CancelCreateChatroomEvent extends CreateChatroomEvent {}