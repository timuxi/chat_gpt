import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_chat_client/toast_util.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'baseresponse.dart';
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
  late SharedPreferences prefs;
  String accessToken = "暂无保存的token";
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  bool keyBordHide = true;

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
      prefs = await SharedPreferences.getInstance();
      _prefs.then((SharedPreferences prefs) {
        if(prefs.getString("access_token") != null){
          setState(() {
            accessToken = prefs.getString("access_token")!;
          });
        }
      });
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
    if(accessToken.length < 20){
      ToastUtil.centerToast("accessToken < 20");
      setState(() {
        answer = "accessToken < 20";
        answerStatus = AnswerStatus.Failed;
      });
      return;
    }
    try{
      Response<ResponseBody> rs = await dio.post(
          '$baseUrl/ask',
          data:  FormData.fromMap({'question': question,'access_token':accessToken}),
          options: Options(responseType: ResponseType.stream)
      );
      answerStatus = AnswerStatus.Success;
      rs.data?.stream.listen((event) {
        Uint8List bytes = Uint8List.fromList(event);
        String result = utf8.decode(bytes);
        if(result.startsWith("ERROR")){
          answerStatus = AnswerStatus.Failed;
        }
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
      return Container();
    }else if(answerStatus == AnswerStatus.Failed){
      return Container(
          margin: EdgeInsets.fromLTRB(20, 30, 20, 20),
          child: Row(children: [
            LoadingAnimationWidget.halfTriangleDot(
              color: Colors.red,
              size: 50,
            ),
            Expanded(child: SelectableText(
              " 错误原因：$answer",
              maxLines: 10,
              style: const TextStyle(fontSize: 32,fontWeight: FontWeight.w400 ),
            ))
          ],)
      );
    }else{
      return Container(
        margin: EdgeInsets.fromLTRB(20, 30, 20, 20),
        child: SelectableText(
          answer,
          style: const TextStyle(fontSize: 20,fontWeight: FontWeight.w400 ),
        )
      );
    }
  }

  Widget getInputText(){
    return TextField(
      onTap: (){
        setState(() {
          keyBordHide = false;
        });
      },
      autofocus: true,
      controller: _descController,
      onChanged: (value) {
        setState(() {
          question = value;
        });
      },
      maxLines: 8,
      decoration: const InputDecoration(
        hintText: "请输入问题",
        hintStyle: TextStyle(color:  Color.fromRGBO(231, 235, 245, 1),backgroundColor: Colors.white),
        border: InputBorder.none,
      ),
    );
  }

  /// 设置缓存
  void setToken(String token) async {
    if(token == ""){
      ToastUtil.centerToast('输入不得为空！');
      return;
    }
    try{
      Response rs = await dio.post(
          '$baseUrl/setToken',
          data:  FormData.fromMap({'access_token':accessToken}),
      );
      BaseResponse baseResponse = BaseResponse.jsonParse(rs.data);
      ToastUtil.centerToast(baseResponse.msg);
      _prefs.then((SharedPreferences prefs) async {
        prefs.setString("access_token", token);
      });
      accessToken = token;
    }catch (e){
      ToastUtil.centerToast('网络似乎出了点问题\n$e');
    }
  }

  void showInputDialog() {
    String token = "";
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            accessToken,
            style: TextStyle(color:Colors.black,backgroundColor: Colors.white,fontSize: 12),
            maxLines: 5,
            overflow: TextOverflow.ellipsis,
          ),
          content: TextField(
            maxLines: 5,
            decoration: const InputDecoration(
              hintText: "输入access_token：",
              hintStyle: TextStyle(color:  Colors.grey,backgroundColor: Colors.white),
              border: InputBorder.none,
            ),
            onChanged: (value) {
              token = value;
            },
          ),
          actions: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.resolveWith((states) {
                      return Colors.blue;
                    }),
                  ),
                  onPressed: () {
                    setToken(token);
                    Navigator.of(context).pop();
                  },
                  child: const Text('确定',style: TextStyle(color: Colors.white),),
                ),
                TextButton(
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.resolveWith((states) {
                      return Colors.grey;
                    }),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('取消',style: TextStyle(color: Colors.white),),
                ),
              ],
            )
          ],
        );
      },
    );
  }


  Widget getSettingWidget(){
    return FloatingActionButton(
      onPressed: ()=>showInputDialog(),
      child: const Icon(Icons.settings_rounded),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(231, 235, 245, 1),
      body: GestureDetector(
        onTap:(){
          FocusScope.of(context).unfocus();
          setState(() {
            keyBordHide = true;
          });
        },
        child: Stack(
          alignment: AlignmentDirectional.topEnd,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                Expanded(
                  child:Center(
                    child: SingleChildScrollView(
                      child: getAnswer(),
                    ),
                  )
                ),
                Container(
                  margin: const EdgeInsets.fromLTRB(0, 0, 0, 0),
                  child:Row(
                      children: [
                        LoadingAnimationWidget.flickr(
                          leftDotColor: Colors.white,
                          rightDotColor: Colors.black,
                          size: 50,
                        ),
                        const Text(
                          "请在下方输入你的问题",
                          style: TextStyle(fontSize: 20,fontWeight: FontWeight.w800 ),
                        ),]
                  ),
                ),
                Container(
                    height: 100,
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
            Container(
              padding: const EdgeInsets.fromLTRB(300,50,20,0),
              child: getSettingWidget(),
            ),
          ],

        ) ,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: ()=>ask(),
        child: const Icon(Icons.send),
      ),
    );
  }
}
