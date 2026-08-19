import 'package:dashboard_desginland/feature/SubCategory/widget/subcategory_widget.dart';
import 'package:dashboard_desginland/model/category_model.dart';
import 'package:flutter/material.dart';



class SubcategoryView extends StatelessWidget{
  CategoryModel _categoryModel;
  SubcategoryView({required this._categoryModel});
  @override
  Widget build(BuildContext context) {
    return SubcategoryWidget(categoryModel: _categoryModel,);
  }
}