// all messages from cloud are encrypted
import 'package:flutter/material.dart';
import 'package:toptal_chat/e2ee/e2ee_bloc.dart';
import 'package:toptal_chat/e2ee/e2ee_state.dart';
import 'package:toptal_chat/model/message.dart';
import 'package:toptal_chat/util/constants.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MessageFromCloud extends StatefulWidget{
  final Message message;
  final BuildContext contextWithE2eeBloc;
  MessageFromCloud(this.message, this.contextWithE2eeBloc);
  @override
  MessageFromCloudState createState() => MessageFromCloudState();
}
class MessageFromCloudState extends State<MessageFromCloud>{
  Color _backgroundColor;
  TextAlign _textAlign; 
  String _text;
  @override
  void initState(){
    super.initState();
    _text = widget.message.value;
    if(widget.message.outgoing){
      _backgroundColor = Colors.lightBlueAccent;
      _textAlign = TextAlign.end;
    }else{
      _backgroundColor = Colors.blueAccent;
      _textAlign = TextAlign.start;
    }
    try{
      BlocProvider.of<E2eeBloc>(widget.contextWithE2eeBloc).onDecrypt(widget.message);
    }catch(e){print(e);}
  }
  @override
  Widget build(BuildContext context){
    return Container(
        child: BlocBuilder(
          bloc: BlocProvider.of<E2eeBloc>(context),
          builder: (context, E2eeState state){
            if(state.messageTimestamp == widget.message.timestamp){
              print("state change in MessageFromCloud: returnString is ${state.returnString}");
              if(state.returnString != null && state.returnString.isNotEmpty){
                if(state.returnString == widget.message.value){
                }
                _text = state.returnString;
              }else if(state.error){
                _text = "failed to decrypt";
              }else if(state.isLoading){
                _text = "decrypting...";
              }
            }
            return Text(
              _text,
              style: TextStyle(color: Colors.white),
              textAlign: _textAlign,
            );
          },
        ),
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

