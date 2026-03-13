import 'package:flutter/material.dart';
import 'package:neom_commons/ui/theme/app_theme.dart';

Widget buildEntryField(String hint, {required TextEditingController controller,
  bool isPassword = false, bool isEmail = false,
  FocusNode? focusNode, TextInputAction? textInputAction,
  FocusNode? nextFocusNode}) {
  return Container(
    margin: const EdgeInsets.symmetric(vertical: 15),
    decoration: AppTheme.kBoxDecorationStyle,
    child: TextField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
      textInputAction: textInputAction ?? TextInputAction.next,
      style: const TextStyle(
        fontStyle: FontStyle.normal,
        fontWeight: FontWeight.normal,
      ),
      obscureText: isPassword,
      onSubmitted: nextFocusNode != null ? (_) => nextFocusNode.requestFocus() : null,
      decoration: InputDecoration(
        hintText: hint,
        border: InputBorder.none,
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(30.0),
          ),
          borderSide: BorderSide(color: Colors.blue),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: AppTheme.padding20),
      ),
      inputFormatters: const [],
    ),
  );
}

Widget buildTwoEntryFields(String firstHint, String secondHint, {required TextEditingController firstController,
  required TextEditingController secondController,
  required BuildContext fieldsContext,
  FocusNode? firstFocusNode, FocusNode? secondFocusNode,
  FocusNode? nextFocusNode, double? maxFieldWidth}) {
  final fieldWidth = maxFieldWidth ?? AppTheme.fullWidth(fieldsContext)/2.5;
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Container(
        width: fieldWidth,
        margin: const EdgeInsets.symmetric(vertical: 15),
        decoration: AppTheme.kBoxDecorationStyle,
        child: TextField(
          controller: firstController,
          focusNode: firstFocusNode,
          textInputAction: TextInputAction.next,
          style: const TextStyle(
            fontStyle: FontStyle.normal,
            fontWeight: FontWeight.normal,
          ),
          onSubmitted: secondFocusNode != null ? (_) => secondFocusNode.requestFocus() : null,
          decoration: InputDecoration(
            hintText: firstHint,
            border: InputBorder.none,
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(
                Radius.circular(30.0),
              ),
              borderSide: BorderSide(color: Colors.blue),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
          ),
        ),
      ),
      Container(
        width: fieldWidth,
        margin: const EdgeInsets.symmetric(vertical: 15),
        decoration: AppTheme.kBoxDecorationStyle,
        child: TextField(
          controller: secondController,
          focusNode: secondFocusNode,
          textInputAction: TextInputAction.next,
          style: const TextStyle(
            fontStyle: FontStyle.normal,
            fontWeight: FontWeight.normal,
          ),
          onSubmitted: nextFocusNode != null ? (_) => nextFocusNode.requestFocus() : null,
          decoration: InputDecoration(
            hintText: secondHint,
            border: InputBorder.none,
            focusedBorder: const OutlineInputBorder(
              borderRadius: BorderRadius.all(
                Radius.circular(30.0),
              ),
              borderSide: BorderSide(color: Colors.blue),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
          ),
        ),
      ),
    ]
  );
}
