import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:toptal_chat/e2ee/e2ee_event.dart';
import 'package:toptal_chat/e2ee/e2ee_state.dart';
import 'package:toptal_chat/e2ee/src/device.dart';
import 'package:toptal_chat/model/message.dart';
import 'package:toptal_chat/model/user_repo.dart';

class E2eeBloc extends Bloc<E2eeEvent, E2eeState>{
  
  Device device = Device();

  // called after firebase auth success / sharedPreference has user?
  void onInit() async {
    add(E2eeInProgressEvent());
    final uid = (await UserRepo.getInstance().getCurrentUser()).uid;
    device.identity = uid;
    await device.initialize();
    final isSignedIn = await device.isSignedIn();
    if(isSignedIn){
      add(E2eeInitializeEvent());
    }else{
      final hasAccount = await device.findSelf(uid);
      if(hasAccount){
        try{
          await device.restorePrivateKey("password");
        }catch(e){
          // probably need to rotatePrivateKey
          add(E2eeErrorEvent(e));
        }
      }else{
        try{
          await device.register();
          await device.backupPrivateKey("password");
        }catch(e){
          add(E2eeErrorEvent(e));
          print("added error event");
        }
      }
      add(E2eeInitializeEvent());
    }
  }

  void onLogout() async {
    add(E2eeInProgressEvent());
    await device.cleanUp();
    add(E2eeLogoutEvent());
  }

  Future<void> onStartChat(List<String> identities) async {
    add(E2eeInProgressEvent());
    try{
      device.publicKeyMap = await device.findUsers(identities);
      print("publicKeyMap now has ${device.publicKeyMap.length} items");
      add(E2eeStartChatEvent());
    }catch(e){
      add(E2eeErrorEvent(e));
    }
  }

  // not needed - publicKeyMap is overwritten whenever user enters a new chatroom
  // void onExitChat(){
  //   publicKeyMap.clear();
  // }

  // somewhat out of place...
  Future<String> onEncrypt(String plainText) async {
    // add(E2eeInProgressEvent());
    return await device.encrypt(plainText);
    // add(E2eeEncryptionEvent(cipherText));
  }

  void onDecrypt(Message encryptedMessage) async {
    add(E2eeInProgressEvent());
    final plainText = await device.decrypt(encryptedMessage.value, encryptedMessage.author.uid);
    add(E2eeDecryptionEvent(plainText, encryptedMessage.timestamp));
  }

  @override
  E2eeState get initialState {
    return E2eeState.initial();
  }

  @override
  Stream<E2eeState> mapEventToState(E2eeEvent event) async* {
    if(event is E2eeInProgressEvent){
      yield E2eeState.loading(true);
    // }else if(event is E2eeEncryptionEvent){
    //   yield E2eeState.encrypt(event.encryptedText);
    }else if(event is E2eeDecryptionEvent){
      yield E2eeState.decrypt(event.decryptedText, event.timestamp);
    }else if(event is E2eeErrorEvent){
      yield E2eeState.error();
    }else if(event is E2eeStartChatEvent){
      yield E2eeState.loading(false);
    }else if(event is E2eeInitializeEvent){
      yield E2eeState.loading(false);
    }else if(event is E2eeLogoutEvent){
      yield E2eeState.loading(false);
    }
  }

}