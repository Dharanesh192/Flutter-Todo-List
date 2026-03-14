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
    return Column(
            children: [
              Container(
  margin: EdgeInsets.only(top: 20),
  width: MediaQuery.of(context).size.width * 0.8,
  decoration: BoxDecoration(
    color: const Color.fromARGB(255, 22, 27, 34),
    borderRadius: BorderRadius.circular(10),
  ),
  height: MediaQuery.of(context).size.width > 600
      ? MediaQuery.of(context).size.height * 0.7 
      : MediaQuery.of(context).size.height * 0.6, 
                    child: ListView.builder(
                      itemCount: 10,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text('Task ${index + 1}'),
                          subtitle: Text('Task description'),
                          leading: Icon(Icons.check_circle_outline),
                        );
                      },
                    ),
              ),
      ],
    );
}}