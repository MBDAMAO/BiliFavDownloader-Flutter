import 'package:flutter/material.dart';

extension WidgetExtensions on Widget {
  Widget get cardx {
    return Card(
      elevation: 0,
      margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: this,
    );
  }
}