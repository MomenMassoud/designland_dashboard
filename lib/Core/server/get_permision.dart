import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

final FirebaseFirestore _firestore=FirebaseFirestore.instance;
final FirebaseAuth _auth=FirebaseAuth.instance;

Future<List<String>>GetPermisionUser()async{
  List<String> permision=[];
  try{
    await _firestore.collection('user').doc(_auth.currentUser!.uid).get().then((value){
      if(value.get('role')=="admin"){
        permision=[
          "products",
          "categories",
          "orders",
          "reports",
          "users",
          "about",
          "staff",
        ];
      }
      else{
        List<dynamic> rawPermissions = value['permissions'] ?? [];
        permision = List<String>.from(rawPermissions);
        return permision;
      }
    });
  }
  catch(e){
    print(e);
  }
  return permision;
}