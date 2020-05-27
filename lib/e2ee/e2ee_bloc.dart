import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:toptal_chat/e2ee/e2ee_event.dart';
import 'package:toptal_chat/e2ee/e2ee_state.dart';
import 'package:toptal_chat/e2ee/src/device.dart';
import 'package:toptal_chat/model/message_repo.dart';
import 'package:toptal_chat/model/user_repo.dart';

class E2eeBloc extends Bloc<E2eeEvent, E2eeState>{
  
  Device device = Device();

  Future<void> addTimedError(Exception e) async {
    add(E2eeErrorEvent(e));
    Future.delayed(Duration(seconds: 3))
    .whenComplete((){add(E2eeOperationCompleted());});
  }

  void onInit() async {
    add(E2eeInProgressEvent());
    final uid = (await UserRepo.getInstance().getCurrentUser()).uid;
    device.identity = uid;
    try{
      await device.initialize();
    }catch(e){
      add(E2eeErrorEvent(e));
    }
    final isSignedIn = await device.isSignedIn();
    if(isSignedIn){
      print("already signed in");
      add(E2eeOperationCompleted());
    }else{
      final hasAccount = await device.findSelf(uid);
      if(hasAccount){
        try{
          await device.restorePrivateKey("password");
          print("signed in");
          add(E2eeOperationCompleted());
        }catch(e){
          print("error restoring private key: $e");
          await addTimedError(e);
        }
      }else{
        try{
          await device.register();
          await device.backupPrivateKey("password");
          print("registered");
          add(E2eeOperationCompleted());
        }catch(e){
          add(E2eeErrorEvent(e));
        }
      }
    }
  }

  onLogout() async {
    // add(E2eeInProgressEvent());
    await device.cleanUp();
    device.eThree = null;
    device.publicKeyMap.clear();
    device.identity = null;
    // add(E2eeOperationCompleted());
  }

  onUnregister(List<String> chatroomIds) async {
    add(E2eeInProgressEvent());
    try{
      await device.unregister();
      // TODO: delete subcollection
      chatroomIds.forEach((chatroomId) async {
        await Firestore.instance.collection("chatrooms").document(chatroomId).delete();
        await MessageRepo().instance.deleteTable(chatroomId);
      });
      // await device.register();
      // trigger database to clear all records?
      // trigger firestore to delete all chatrooms? 
    } on PlatformException catch (e) {
      print(e.message);
      add(E2eeErrorEvent(e));
    }
    add(E2eeOperationCompleted());
  }

  // detect whether chat is correctly created -- if not then re-create?
  Future<void> onCreateChat(String identity) async {
    add(E2eeInProgressEvent());
    try{
      device.publicKeyMap = await device.findUsers([identity]);
      await device.createRatchetChannel(identity);
      add(E2eeOperationCompleted());
    }on PlatformException catch (e){
      print("ratchet channel creation failed");
      print(e.message);
      add(E2eeErrorEvent(e));
    }
  }

  Future<void> onStartChat(String identity) async {
    add(E2eeInProgressEvent());
    try{
      final channelExists = await device.getRatchetChannel(identity);
      if(channelExists){
        add(E2eeOperationCompleted());
      }else{
        try{
          await device.joinRatchetChannel(identity);
          add(E2eeOperationCompleted());
        }on PlatformException catch (e){
          print("join ratchet channel failed");
          print(e.message);
          add(E2eeErrorEvent(e));
        }
      }
    }on PlatformException catch (e){
      print("get ratchet channel failed");
      print(e.message);
      add(E2eeErrorEvent(e));
    }
  }

  @override
  E2eeState get initialState {
    return E2eeState.initial();
  }

  @override
  Stream<E2eeState> mapEventToState(E2eeEvent event) async* {
    if(event is E2eeInProgressEvent){
      yield E2eeState.loading(true);
    }else if(event is E2eeErrorEvent){
      yield E2eeState.error(event.error);
    }else if(event is E2eeOperationCompleted){
      yield E2eeState.loading(false);
    }
  }

}