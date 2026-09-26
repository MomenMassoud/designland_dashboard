import 'package:dashboard_desginland/feature/SubCountry/widget/sub_country_widget.dart';
import 'package:flutter/material.dart';


class SubCountryView extends StatelessWidget{
  String _CountryID;
  SubCountryView({required this._CountryID});
  @override
  Widget build(BuildContext context) {
    return SubCountryWidget(countryID: _CountryID);
  }
}