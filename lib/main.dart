import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'constant.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  String baseUrl = 'http://43.143.78.2:8088';
  final dio = Dio();
  String answer = "";
  final TextEditingController _descController = TextEditingController();
  String question = "";
  var answerStatus = AnswerStatus.Init;

  @override
  void initState() {
    super.initState();
    _descController.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _descController.text.length,
    );
    ping();
  }


  Future<void> ping() async {
    try{
      await dio.get('$baseUrl/ping');
    }catch (e){
      Fluttertoast.showToast(
          msg: "网络似乎出了点问题～$e",
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.CENTER,
          timeInSecForIosWeb: 1,
          backgroundColor: Colors.white,
          textColor: Colors.black,
          fontSize: 16.0
      );
    }
  }

  Future<void> ask() async {
    setState(() {
      answer = "";
      answerStatus = AnswerStatus.Waiting;
    });
    try{
      Response<ResponseBody> rs = await dio.post(
          '$baseUrl/ask',
          data:  FormData.fromMap({'question': question}),
          options: Options(responseType: ResponseType.stream)
      );
      answerStatus = AnswerStatus.Success;
      rs.data?.stream.listen((event) {
        Uint8List bytes = Uint8List.fromList(event);
        String result = utf8.decode(bytes);
        setState(() {
          answer += result;
        });
      });
    }catch(e){
      setState(() {
        answer = e.toString();
        answerStatus = AnswerStatus.Failed;
      });
    }
  }

  Widget getAnswer(){
    if(answerStatus == AnswerStatus.Waiting){
      return LoadingAnimationWidget.waveDots(
        color: Colors.grey,
        size: 50,
      );
    }else if(answerStatus == AnswerStatus.Init){
      return Row(
        children: [
          LoadingAnimationWidget.flickr(
            leftDotColor: Colors.white,
            rightDotColor: Colors.black,
            size: 50,
          ),
          const Text(
            "请在下方输入你的问题",
            style: TextStyle(fontSize: 20,fontWeight: FontWeight.w800 ),
          )
        ],
      );
    }else{
      return Text(
        answer,
        style: const TextStyle(fontSize: 20,fontWeight: FontWeight.w400 ),
      );
    }
  }

  Widget getInputText(){
    return TextField(
      autofocus: true,
      controller: _descController,
      onChanged: (value) {
        setState(() {
          question = value;
        });
      },
      decoration: const InputDecoration(
        hintText: "请输入问题",
        hintStyle: TextStyle(color:  Color.fromRGBO(231, 235, 245, 1),backgroundColor: Colors.white),
        border: InputBorder.none,
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(231, 235, 245, 1),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.fromLTRB(20,0,20,0),
            child: getAnswer(),
          ),
          Container(
            height: 200,
            margin: const EdgeInsets.fromLTRB(10,0,10,30),
            padding: const EdgeInsets.fromLTRB(20,0,20,0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: getInputText()
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: ()=>ask(),
        child: const Icon(Icons.send),
      ),
    );
  }
}
