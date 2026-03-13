import 'package:flutter/material.dart';

class Textstyler extends StatelessWidget {

  final TextEditingController controller;
  final String hint;

  const Textstyler({
    required this.controller,
    required this.hint,
    super.key
  });
  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white54),
      decoration: InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white54),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.white54),
        borderRadius: BorderRadius.circular(10),),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Color(0xFF00FF00)),
        borderRadius: BorderRadius.circular(10),
      ),),);
  }
}
