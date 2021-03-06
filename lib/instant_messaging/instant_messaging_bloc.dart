import 'dart:async';
import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:toptal_chat/e2ee/src/device.dart';
import 'package:toptal_chat/model/message_repo.dart';

import 'instant_messaging_event.dart';
import 'instant_messaging_state.dart';
import '../model/user.dart';
import '../model/message.dart';
import '../model/chat_repo.dart';
import '../model/user_repo.dart';
import '../model/storage_repo.dart';

class InstantMessagingBloc extends Bloc<InstantMessagingEvent, InstantMessagingState> {
  InstantMessagingBloc(this.chatroomId, this.oppUserId);

  final String chatroomId;
  final String oppUserId;
  final MessageRepo messageRepo = MessageRepo().instance;
  StreamSubscription<QuerySnapshot> chatroomSubscription;

  void _retrieveMessagesForThisChatroom() async {
    final User user = await UserRepo.getInstance().getCurrentUser();
    chatroomSubscription = ChatRepo.getInstance().getMessagesForChatroom(chatroomId).listen(
      (snapshot) async {
        final docsToDelete = List<DocumentReference>();
        int messageId = await messageRepo.getMessageId(chatroomId);

        snapshot.documentChanges.forEach((change) async {
          if(change.type == DocumentChangeType.added){
            final String authorId = change.document.data["author"];
            if(authorId != user.uid){
              docsToDelete.add(change.document.reference);
              final message = change.document.data;
              String messageValue;
              if (message["value"].startsWith("_uri:")) {
                  final String uri = message["value"].substring("_uri:".length);
                  final String downloadUri = await StorageRepo.getInstance().decodeUri(uri);
                  messageValue = "_uri:$downloadUri";
              } else {
                  try{
                    messageValue = await Device().ratchetDecrypt(oppUserId, message["value"]);
                  } catch (err){
                    messageValue = err.message;
                  }
              }
              final processedMessage = MessageToDisplay(messageValue, false);
              await messageRepo.saveMessage(messageId++, processedMessage, chatroomId);
              add(MessageReceivedEvent(processedMessage));
            }
          }
        });

        for(final d in docsToDelete){
          await Firestore.instance.collection("chatrooms").document(chatroomId)
            .collection("messages").document(d.documentID).delete();
        }
      });
  }
  
  void _messageSent(String text, List<MessageToDisplay> curMessageList) async {
    final m = MessageToDisplay(text, true);
    curMessageList.insert(0,m);
    final mId = await messageRepo.getMessageId(chatroomId);
    await messageRepo.saveMessage(mId, m, chatroomId);
    add(MessageSentEvent());
  }

  void send(String text, List<MessageToDisplay> curMessageList) async {
    final User user = await UserRepo.getInstance().getCurrentUser();
    if(text.startsWith("_uri")){
      final bool success = await ChatRepo.getInstance().sendMessageToChatroom(chatroomId, user, text);
      if (!success) {
        add(MessageSendErrorEvent());
      }else{
        _messageSent(text, curMessageList);
      }
    // encrypt text messages only
    }else{
      String cipher = await Device().ratchetEncrypt(oppUserId, text);
      if(cipher != null){
        try{
          final bool success = await ChatRepo.getInstance().sendMessageToChatroom(chatroomId, user, cipher);
          if (!success) {
            add(MessageSendErrorEvent());
          }else{
            _messageSent(text, curMessageList);
          }
        }catch(e){
          if(e.message == "chatroom does not exist"){
            add(MessageSendErrorEvent());
          }
        }
      }else{
        add(MessageSendErrorEvent());
      }
    }
  }

  void sendFile(File file, List<MessageToDisplay> curMessageList) async {
    final String storagePath = await StorageRepo.getInstance().uploadFile(file);
    if (storagePath != null) {
      _sendFileUri(storagePath, curMessageList);
    } else {
      add(MessageSendErrorEvent());
    }
  }

  void _sendFileUri(String uri, List<MessageToDisplay> curMessageList) async {
    send("_uri:$uri", curMessageList);
  }

  @override
  InstantMessagingState get initialState {
    _retrieveMessagesForThisChatroom();
    return InstantMessagingState.initial();
  }

  @override
  Stream<InstantMessagingState> mapEventToState(InstantMessagingEvent event) async* {
    if (event is MessageReceivedEvent) {
      yield InstantMessagingState.messages(event.message);
    } else if (event is MessageSendErrorEvent) {
      yield InstantMessagingState.error(state);
    } else if (event is MessageSentEvent) {
      yield InstantMessagingState.messages(null);
    }
  }

  @override
  Future<void> close() async {
    if (chatroomSubscription != null) {
      chatroomSubscription.cancel();
    }
    super.close();
  }
}

