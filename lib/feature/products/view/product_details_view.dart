import 'package:dashboard_desginland/feature/products/widget/product_details_widget.dart';
import 'package:dashboard_desginland/model/product_model.dart';
import 'package:flutter/material.dart';



class ProductDetailsView extends StatelessWidget{
  ProductModel _model;
  ProductDetailsView({required this._model});
  @override
  Widget build(BuildContext context) {
    return ProductDetailsWidget(product: _model,);
  }
}