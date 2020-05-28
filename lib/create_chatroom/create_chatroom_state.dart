import '../model/user.dart';

// class CreateChatroomAction {
//   CreateChatroomAction(this.chatroom, this.canceled);

//   final SelectedChatroom chatroom;
// }

class CreateChatroomState {
  final List<User> users;
  final bool isLoading;
  final bool canceled;
  // final CreateChatroomAction action;

  CreateChatroomState._internal(this.users, this.isLoading, {this.canceled = false});

  factory CreateChatroomState.initial() =>
      CreateChatroomState._internal(List<User>(0), true);

  factory CreateChatroomState.isLoading(
          bool isLoading, CreateChatroomState state) =>
      CreateChatroomState._internal(state.users, isLoading);

  factory CreateChatroomState.users(
          List<User> users, CreateChatroomState state) =>
      CreateChatroomState._internal(users, state.isLoading);

  factory CreateChatroomState.canceled() => 
      CreateChatroomState._internal(List<User>(0), false, canceled: true);
}
