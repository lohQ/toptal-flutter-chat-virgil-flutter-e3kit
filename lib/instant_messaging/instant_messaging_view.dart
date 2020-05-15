import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:toptal_chat/e2ee/e2ee_bloc.dart';
import 'package:toptal_chat/e2ee/e2ee_widget.dart';

import '../util/constants.dart';
import '../model/message.dart';
import 'instant_messaging_bloc.dart';
import 'instant_messaging_state.dart';

class InstantMessagingScreen extends StatefulWidget {
  InstantMessagingScreen({Key key, @required this.displayName, @required this.chatroomId})
      : super(key: key);

  final String displayName;
  final String chatroomId;
  final TextEditingController _textEditingController = TextEditingController();

  @override
  State<StatefulWidget> createState() => _InstantMessagingState(chatroomId);
}

class _InstantMessagingState extends State<InstantMessagingScreen> {
  final String chatroomId;

  _InstantMessagingState(this.chatroomId);

  @override
  Widget build(BuildContext context) {
    return BlocProvider<E2eeBloc>(
      create: (context) => E2eeBloc(),
      child: BlocProvider<InstantMessagingBloc>(
        create: (context) => InstantMessagingBloc(chatroomId),
        child: InstantMessagingWidget(widget: widget),
      )
    );
  }

}

class InstantMessagingWidget extends StatelessWidget {
  const InstantMessagingWidget({Key key, @required this.widget}) : super(key: key);
  final InstantMessagingScreen widget;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text(widget.displayName)),
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
                      controller: widget._textEditingController,
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
              _instantMessagingBlocBuilderWithE2eeProvider(context)
            )
          ]
        )
    );
  }

  Widget _instantMessagingBlocBuilderWithE2eeProvider(BuildContext context){
    return BlocBuilder(
      bloc: BlocProvider.of<InstantMessagingBloc>(context),
      builder: (context, InstantMessagingState state) {
        if (state.error) {
          return Center(
            child: Text("An error ocurred"),
          );
        } else {
          return Container(
              child: ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.symmetric(
                  horizontal: UIConstants.SMALLER_PADDING,
                  vertical: UIConstants.SMALLER_PADDING,
                ),
                itemBuilder: (context, index) =>
                    MessageItem(state.messages[state.messages.length - 1 - index]),
                itemCount: state.messages.length,
                reverse: true,
              ),
          );
      }});
  }

  void _send(BuildContext context) async {
    print("sending message: ${widget._textEditingController.text}");
    String cipher = await BlocProvider.of<E2eeBloc>(context).onEncrypt(widget._textEditingController.text);
    if (cipher != null && cipher.isNotEmpty) {
      try{
        BlocProvider.of<InstantMessagingBloc>(context).send(cipher);
      }catch(e){print(e);}
      widget._textEditingController.text = "";
    }
  }

  void _sendFile(BuildContext context, File file) {
    BlocProvider.of<InstantMessagingBloc>(context).sendFile(file);
  }

  void _openPictureDialog(BuildContext context) async {
    File target = await ImagePicker.pickImage(source: ImageSource.gallery)
      .catchError((e){print(e);});
    if (target != null) {
      _sendFile(context, target);
    }
  }
}

class MessageItem extends StatelessWidget{
  final Message message;
  MessageItem(this.message);
  @override
  Widget build(BuildContext context){
    if (message.value.startsWith("_uri:")) {
      final String url = message.value.substring("_uri:".length);
      MainAxisAlignment _alignment;
      if (message.outgoing){
        _alignment = MainAxisAlignment.start;
      }else{
        _alignment = MainAxisAlignment.end;
      }
      return Row(
        mainAxisAlignment: _alignment,
        children: <Widget>[
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8.0)
            ),
            child: Image.network(url, width: 256),
          ),
        ],
      );
    }
    return MessageFromCloud(message, context);
  }
}

