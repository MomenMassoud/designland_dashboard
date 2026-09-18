import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dashboard_desginland/Core/widgets/error_dailog_custom.dart';
import 'package:dashboard_desginland/model/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';



final FirebaseFirestore _firestore=FirebaseFirestore.instance;
final FirebaseAuth _auth=FirebaseAuth.instance;



Future<UserModel> GetCurrentUserData(BuildContext context)async{
  UserModel user=UserModel(uid: "", email: "", Name: "", role: "");
  try{
    await _firestore.collection('user').doc(_auth.currentUser!.uid).get().then((value){
      user.uid=_auth.currentUser!.uid;
      user.email=value.get('email');
      user.Name=value.get("name");
      user.role=value.get('role');
    });
  }
  catch(e){
    showErrorDialog(context, "Error", e.toString());
  }
  return user;
}