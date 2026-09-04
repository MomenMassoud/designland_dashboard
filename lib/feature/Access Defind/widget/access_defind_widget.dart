import 'package:flutter/material.dart';



class AccessDefindWidget extends StatefulWidget{
  @override
  State<StatefulWidget> createState() {
    return _AccessDefindWidget();
  }
}


class _AccessDefindWidget extends State<AccessDefindWidget>{
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text("Access Defined !",style: TextStyle(fontSize: 18),),
      ),
    );
  }
}