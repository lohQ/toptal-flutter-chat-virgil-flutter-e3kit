import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:toptal_chat/e2ee/src/device.dart';
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
      chatroomsSubscription = ChatRepo.getInstance().getChatroomsForUser(user).listen((chatrooms) {
        chatrooms.forEach((room) {
          if (room.participants.first.uid == user.uid) {
            Util.swapElementsInList(room.participants, 0, 1);
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
    await Device().deleteRatchetChannel(oppId);
    try{
      await Device().deleteRatchetChannel(oppId);
    }catch(e){
      print(e);
    }
    await MessageRepo().instance.deleteTable(chatroomId);
    await Firestore.instance.collection(FirestorePaths.CHATROOMS_COLLECTION)
      .document(chatroomId).delete();
    print("chatroom deletion completed");
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
