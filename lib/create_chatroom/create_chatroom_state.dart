import '../model/user.dart';

// class CreateChatroomAction {
//   CreateChatroomAction(this.chatroom, this.canceled);

//   final SelectedChatroom chatroom;
// }

class CreateChatroomState {
  final List<User> users;
  final List<String> requestStartChatUids;
  final bool isLoading;
  final bool canceled;
  // final CreateChatroomAction action;

  CreateChatroomState._internal(this.users, this.requestStartChatUids, this.isLoading, {this.canceled = false});

  factory CreateChatroomState.initial() =>
      CreateChatroomState._internal(List<User>(0), List<String>(0), true);

  factory CreateChatroomState.isLoading(
          bool isLoading, CreateChatroomState state) =>
      CreateChatroomState._internal(state.users, state.requestStartChatUids, isLoading);

  factory CreateChatroomState.users(
          List<User> users, CreateChatroomState state) =>
      CreateChatroomState._internal(users, state.requestStartChatUids, state.isLoading);

  factory CreateChatroomState.canceled(CreateChatroomState state) => 
      CreateChatroomState._internal(state.users, state.requestStartChatUids, false, canceled: true);

  factory CreateChatroomState.requestingUsers(
          List<String> uids, CreateChatroomState state) =>
      CreateChatroomState._internal(state.users, uids, state.isLoading);
}
