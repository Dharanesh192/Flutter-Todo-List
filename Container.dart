import 'package:flutter/material.dart';

void main() {
  runApp(const Taskview());
}

class Taskview extends StatefulWidget {
  const Taskview({super.key});

  @override
  State<Taskview> createState() => _TaskviewState();
}

class _TaskviewState extends State<Taskview>{
  @override
  Widget build(BuildContext context) {
    return Container(
                margin: EdgeInsets.only(top: 20),
                width: MediaQuery.of(context).size.width * 0.8,
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 22, 27, 34),
                  borderRadius: BorderRadius.circular(10),
                ),
                height: 500,
                child: Center(
                  child: Text("No tasks yet",
                  style: TextStyle(
                    color: Color.fromARGB(255, 255, 255, 255),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),),
                ),
              );
}}