import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:toptal_chat/e2ee/e2ee_bloc.dart';
import 'package:toptal_chat/e2ee/e2ee_wrapper.dart';
import 'package:toptal_chat/e2ee/src/device.dart';
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
    // dangerous without await
    MessageRepo().instance.createTable(widget.chatroom.id);
    if(widget.isNew){
      _e2eeBloc.onCreateChat(widget.chatroom.oppId);
    }else{
      _e2eeBloc.onStartChat(widget.chatroom.oppId);
    }
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
        BlocProvider<InstantMessagingBloc>(
          create: (context) => InstantMessagingBloc(widget.chatroom.id, widget.chatroom.oppId),
          child: InstantMessagingWidget(widget.chatroom.id, widget.chatroom.displayName, widget.chatroom.oppId)),
        "error initializing double ratchet session"
        ),
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
      messageToDisplay.addAll(messageList);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(displayName),
          actions: <Widget>[
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: () async {
                try{
                  await Device().deleteRatchetChannel(oppId);
                  // message repo would be initialized by now
                  await MessageRepo().instance.deleteTable(chatroomId);
                  await Firestore.instance.collection(FirestorePaths.CHATROOMS_COLLECTION)
                    .document(chatroomId).delete()
                    .whenComplete((){Navigator.pop(context);});
                }catch(e){
                  print("error deleting ratchet channel: $e");
                }},
            )]),
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
            child: Text("An error ocurred"),
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

