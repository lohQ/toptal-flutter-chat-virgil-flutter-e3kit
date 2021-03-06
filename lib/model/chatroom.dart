import 'message.dart';
import 'user.dart';

class SelectedChatroom {
  SelectedChatroom(this.id, this.oppId, this.displayName);

  final String id;
  final String oppId;
  final String displayName;
}

class Chatroom {
  Chatroom(this.id, this.participants, [this.messages]);

  final String id;
  final List<User> participants;
  final List<Message> messages;
}
