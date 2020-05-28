import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:toptal_chat/e2ee/e2ee_bloc.dart';
import 'package:toptal_chat/e2ee/e2ee_state.dart';
import 'package:toptal_chat/e2ee/e2ee_wrapper.dart';
import 'package:toptal_chat/model/chatroom.dart';
import 'package:toptal_chat/model/message.dart';
import 'package:toptal_chat/model/message_repo.dart';

import '../util/constants.dart';
import 'instant_messaging_bloc.dart';
import 'instant_messaging_state.dart';

class InstantMessagingScreen extends StatefulWidget {
  InstantMessagingScreen(
    {Key key, 
    @required this.chatroom,
    @required this.isNew}) : super(key: key);

  final SelectedChatroom chatroom;
  final bool isNew;

  @override
  State<StatefulWidget> createState() => _InstantMessagingState();
}

class _InstantMessagingState extends State<InstantMessagingScreen> {
  final E2eeBloc _e2eeBloc = E2eeBloc();

  @override
  void initState(){
    super.initState();
    MessageRepo().instance.createTable(widget.chatroom.id)
      .whenComplete((){
        if(widget.isNew){
          _e2eeBloc.onCreateChat(widget.chatroom.oppId);
        }else{
          _e2eeBloc.onStartChat(widget.chatroom.oppId);
        }
      })
      .catchError((e){
        print("error creating table: $e");
        Navigator.pop(context);
      });
  }

  @override
  void dispose(){
    _e2eeBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<E2eeBloc>(
      create: (context) => _e2eeBloc,
      child: E2eeWrapper(
        child: BlocProvider<InstantMessagingBloc>(
          create: (context) => InstantMessagingBloc(widget.chatroom.id, widget.chatroom.oppId),
          child: InstantMessagingWidget(widget.chatroom.id, widget.chatroom.displayName, widget.chatroom.oppId)),
        errorCallback: (E2eeState error){ mapErrorToAction(error); },
        errorWidget: (E2eeState error){ return mapErrorToWidget(error); },
        ),
    );
  }

  void mapErrorToAction(E2eeState state) async {
    if(state.error){
      final error = state.errorDetails;
      if(error.message == "70204: Channel with provided user and name already exists."){
        // print("try getting channel instead...");
        // _e2eeBloc.onStartChat(widget.chatroom.oppId);
        print("try delete the channel and create again...");
        _e2eeBloc.device.deleteRatchetChannel(widget.chatroom.oppId);
        _e2eeBloc.onCreateChat(widget.chatroom.oppId);
      }else if(error.message.contains(RegExp("Long-term key .* not found"))
        || error.message == "70602: Card for one or more of provided identities was not found."){
        // fails cleanly
        await _e2eeBloc.device.deleteRatchetChannel(widget.chatroom.oppId);
        await MessageRepo().instance.deleteTable(widget.chatroom.id);
        await Firestore.instance.collection(FirestorePaths.CHATROOMS_COLLECTION)
          .document(widget.chatroom.id).delete();
        print("chatroom deletion completed");
      // }else if(error.message == "no invitation"){
      // }else {
      }
    }
  }

  Widget mapErrorToWidget(E2eeState e){
    final createOrGet = widget.isNew ? "creating" : "getting";
    String additionalInfo = "";
    if(e.errorDetails.message == "70204: Channel with provided user and name already exists."){
      additionalInfo = "Deleting previous channel and re-creating...";
    }else if(e.errorDetails.message.contains(RegExp("Long-term key .* not found"))){
      additionalInfo = "Possible reason: unclean uninstallation. \nSuggested action: re-register to virgil cloud. ";
    }
    return Center(
      child: Text(
        "Error $createOrGet ratchet channel: ${e.errorDetails}\n$additionalInfo",
        style: TextStyle(fontSize: 16))
    );
  }

}

class InstantMessagingWidget extends StatelessWidget {
  final String chatroomId; final String displayName; final String oppId; 
  final TextEditingController _textEditingController = TextEditingController();
  final messageToDisplay = List<MessageToDisplay>();

  InstantMessagingWidget(this.chatroomId, this.displayName, this.oppId, {Key key})
   : super(key: key){
    MessageRepo().instance.readMessages(chatroomId)
    .then((messageList){
      if(messageList != null){
        messageToDisplay.addAll(messageList.reversed);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(displayName)),
        body: Column(
          mainAxisSize: MainAxisSize.max,
          verticalDirection: VerticalDirection.up,
          children: <Widget>[
            Row(
              mainAxisSize: MainAxisSize.max,
              children: <Widget>[
                Expanded(
                  child: Container(
                    margin: EdgeInsets.only(bottom: UIConstants.STANDARD_PADDING),
                    padding: EdgeInsets.symmetric(
                        vertical: UIConstants.SMALLER_PADDING,
                        horizontal: UIConstants.SMALLER_PADDING),
                    child: TextField(
                      maxLines: null,
                      controller: _textEditingController,
                      focusNode: FocusNode(),
                      style: TextStyle(color: Colors.black),
                      cursorColor: Colors.blueAccent,
                      decoration: InputDecoration(hintText: "Your message..."),
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ),
                ),
                Container(
                  child: IconButton(
                      icon: Icon(Icons.image),
                      onPressed: () {
                        _openPictureDialog(context);
                      }),
                  decoration: BoxDecoration(shape: BoxShape.circle),
                ),
                Container(
                  child: IconButton(
                      icon: Icon(Icons.send),
                      onPressed: () {
                        _send(context);
                      }),
                  decoration: BoxDecoration(shape: BoxShape.circle),
                ),
              ],
            ),
            Expanded(
              child: 
              _instantMessagingBlocBuilder(context)
            )
          ]
        )
    );
  }

  Widget _instantMessagingBlocBuilder(BuildContext context){
    return BlocBuilder(
      bloc: BlocProvider.of<InstantMessagingBloc>(context),
      builder: (context, InstantMessagingState state) {
        if (state.error) {
          return Center(
            child: Text("An error ocurred, pleaase leave this chatroom"),
          );
        } else {
          if(state.message != null){
            messageToDisplay.insert(0,state.message);
          }
          return Container(
              child: ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.symmetric(
                  horizontal: UIConstants.SMALLER_PADDING,
                  vertical: UIConstants.SMALLER_PADDING,
                ),
                itemCount: messageToDisplay.length,
                reverse: true,
                itemBuilder: (context, index){
                  final message = messageToDisplay[index];
                  if (message.value.startsWith("_uri:")) {
                    return ImageMessage(message);
                  }else{
                    return TextMessage(message);
                  }
                },
              ),
          );
      }});
  }

  void _send(BuildContext context) async {
    BlocProvider.of<InstantMessagingBloc>(context).send(_textEditingController.text, messageToDisplay);
    _textEditingController.text = "";
  }

  void _sendFile(BuildContext context, File file) {
    BlocProvider.of<InstantMessagingBloc>(context).sendFile(file, messageToDisplay);
  }

  void _openPictureDialog(BuildContext context) async {
    File target = await ImagePicker.pickImage(source: ImageSource.gallery)
      .catchError((e){print(e);});
    if (target != null) {
      _sendFile(context, target);
    }
  }
}

class ImageMessage extends StatelessWidget{
  final MessageToDisplay message;
  String url;
  MainAxisAlignment _alignment;
  ImageMessage(this.message){
    url = message.value.substring("_uri:".length);
    if (message.outgoing){
      _alignment = MainAxisAlignment.start;
    }else{
      _alignment = MainAxisAlignment.end;
    }
  }
  @override
  Widget build(BuildContext context){
    return Row(
      mainAxisAlignment: _alignment,
      children: <Widget>[
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8.0)
          ),
          child: Image.network(url, width: 256))],
    );
  }
}

class TextMessage extends StatelessWidget{
  final MessageToDisplay message;
  Color _backgroundColor;
  TextAlign _textAlign; 

  TextMessage(this.message){
    if(message.outgoing){
      _backgroundColor = Colors.lightBlueAccent;
      _textAlign = TextAlign.end;
    }else{
      _backgroundColor = Colors.blueAccent;
      _textAlign = TextAlign.start;
    }
  }

  @override
  Widget build(BuildContext context){
    return Container(
        child: Text(
          message.value,
          style: TextStyle(color: Colors.white),
          textAlign: _textAlign),
        decoration: BoxDecoration(
            color: _backgroundColor, borderRadius: BorderRadius.all(Radius.circular(6.0))),
        padding: EdgeInsets.all(UIConstants.SMALLER_PADDING),
        margin: EdgeInsets.symmetric(
          vertical: UIConstants.SMALLER_PADDING / 2.0,
          horizontal: 0.0,
        ),
    );
  }
}

