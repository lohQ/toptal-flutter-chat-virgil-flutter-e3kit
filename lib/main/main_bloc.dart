import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:toptal_chat/e2ee/src/device.dart';
import 'package:toptal_chat/model/chatroon_repo.dart';
import 'package:toptal_chat/model/message_repo.dart';
import 'package:toptal_chat/util/constants.dart';

import 'main_event.dart';
import 'main_state.dart';
import 'main_view.dart';
import '../model/user.dart';
import '../model/chatroom.dart';
import '../model/login_repo.dart';
import '../model/user_repo.dart';
import '../model/chat_repo.dart';
import '../util/util.dart';

class MainBloc extends Bloc<MainEvent, MainState> {
  StreamSubscription<List<Chatroom>> chatroomsSubscription;

  void logout() {
    LoginRepo.getInstance().signOut().then((success) {
      if (success) {
        add(LogoutEvent());
        // view.navigateToLogin();
      }
    });
  }

  @override
  MainState get initialState {
    retrieveUserChatrooms();
    return MainState.initial();
  }

  void retrieveUserChatrooms() async {
    add(ClearChatroomsEvent());
    final user = await UserRepo.getInstance().getCurrentUser();
    if (user != null) {
      chatroomsSubscription = ChatRepo.getInstance().getChatroomsForUser(user).listen((chatrooms) async {
        chatrooms.forEach((room) {
          if (room.participants.first.uid == user.uid) {
            Util.swapElementsInList(room.participants, 0, 1);
          }
          if (ChatroomRepo.instance.deletedChatrooms.contains(room.participants.first.uid)){
            ChatroomRepo.instance.removeDeletedChatroom(room.participants.first.uid);
          }
        });
        add(ChatroomsUpdatedEvent(chatrooms));
      });
    } else {
      add(MainErrorEvent());
    }
  }

  void retrieveChatroomForParticipant(User user, MainWidget view) async {
    final currentUser = await UserRepo.getInstance().getCurrentUser();
    List<User> users = List<User>(2);
    users[0] = user;
    users[1] = currentUser;
    ChatRepo.getInstance().startChatroomForUsers(users).then((chatroom) {
      view.navigateToChatroom(chatroom);
    });
  }

  void deleteChatroom(String chatroomId, String oppId, BuildContext context) async {
    // TODO: delete Messages collection
    Firestore.instance.collection(FirestorePaths.CHATROOMS_COLLECTION)
      .document(chatroomId).delete();
    Device().deleteRatchetChannel(oppId);
    // final currentUser = await UserRepo.getInstance().getCurrentUser();
    // Firestore.instance.collection(FirestorePaths.DELETED_CHATROOMS_COLLECTION)
    //   .document("${currentUser.uid}_$oppId").setData({"pending": true, "chatroomId": chatroomId});
    ChatroomRepo.instance.addDeletedChatroom(oppId);
  }

  @override
  Stream<MainState> mapEventToState(MainEvent event) async* {
    if (event is ClearChatroomsEvent) {
      yield MainState.isLoading(true, MainState.initial());
    } else if (event is ChatroomsUpdatedEvent) {
      yield MainState.isLoading(false, MainState.chatrooms(event.chatrooms, state));
    } else if (event is MainErrorEvent) {
      yield MainState.isLoading(false, state);
    } else if (event is LogoutEvent) {
      yield MainState.logout(state);
    }
  }

  @override
  Future<void> close() async {
    if (chatroomsSubscription != null) {
      chatroomsSubscription.cancel();
    }
    super.close();
  }
}
