import 'package:flutter/material.dart';
import 'package:neom_commons/ui/theme/app_theme.dart';

Widget buildEntryField(String hint, {required TextEditingController controller,
  bool isPassword = false, bool isEmail = false}) {
  return Container(
    margin: const EdgeInsets.symmetric(vertical: 15),
    decoration: AppTheme.kBoxDecorationStyle,
    child: TextField(
      controller: controller,
      keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
      style: const TextStyle(
        fontStyle: FontStyle.normal,
        fontWeight: FontWeight.normal,
      ),
      obscureText: isPassword,
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
  required BuildContext fieldsContext}) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Container(
        width: AppTheme.fullWidth(fieldsContext)/2.5,
        margin: const EdgeInsets.symmetric(vertical: 15),
        decoration: AppTheme.kBoxDecorationStyle,
        child: TextField(
          controller: firstController,
          style: const TextStyle(
            fontStyle: FontStyle.normal,
            fontWeight: FontWeight.normal,
          ),
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
        width: AppTheme.fullWidth(fieldsContext)/2.5,
        margin: const EdgeInsets.symmetric(vertical: 15),
        decoration: AppTheme.kBoxDecorationStyle,
        child: TextField(
          controller: secondController,
          style: const TextStyle(
            fontStyle: FontStyle.normal,
            fontWeight: FontWeight.normal,
          ),
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
