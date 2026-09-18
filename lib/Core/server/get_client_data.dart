import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dashboard_desginland/Core/widgets/error_dailog_custom.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../model/user_model.dart';


final FirebaseFirestore _firestore=FirebaseFirestore.instance;
final FirebaseAuth _auth=FirebaseAuth.instance;


Future<UserModel> getClientData(BuildContext context,String UserID)async{
  UserModel user=UserModel(uid: "", email: "", Name: "", role: "");
  try{
    await _firestore.collection('user').doc(UserID).get().then((value){
      user.uid=UserID;
      user.email=value.get('email');
      user.role="user";
      user.Name=value.get('name');
    });
  }
  catch(e){
    showErrorDialog(context, "Error", e.toString());
  }
  return user;
}