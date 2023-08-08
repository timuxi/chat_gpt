
import 'dart:convert';

class BaseResponse{


  int code;
  String msg;
  String data;

  BaseResponse(this.code , this.msg, this.data);

  static jsonParse(String res){
    dynamic jsonObject = jsonDecode(res);
    return BaseResponse(jsonObject['code'], jsonObject['msg'], jsonObject['data']);
  }

}