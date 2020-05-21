import '../model/message.dart';

class InstantMessagingState {
  final bool isLoading;
  final Message message;
  final bool error;

  InstantMessagingState._internal(this.isLoading, this.message, {this.error = false});

  factory InstantMessagingState.initial() => InstantMessagingState._internal(true, null);

  factory InstantMessagingState.messages(Message message) => InstantMessagingState._internal(false, message);

  factory InstantMessagingState.error(InstantMessagingState state) => InstantMessagingState._internal(state.isLoading, state.message, error: true);
}