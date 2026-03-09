import 'package:flutter/material.dart';

class Addtask extends StatefulWidget {
  const Addtask({super.key});

  @override
  State<Addtask> createState() => _AddtaskState();
}

class _AddtaskState extends State<Addtask> {
  TextEditingController date = TextEditingController();
  FocusNode dateFocus = FocusNode();
  @override
  Widget build(BuildContext context) {
    return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 22, 27, 34),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Add Task",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 28,
                      color: Color(0xFF00FF00),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_circle_right_outlined,size: 40, color: Color(0xFF00FF00)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Task name",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white54,
                  ),
                ),
              ),

              const SizedBox(height: 5),

              TextField(
                style: const TextStyle(color: Colors.white54),
                decoration: InputDecoration(
                  hintText: "Enter your task",
                  hintStyle: const TextStyle(color: Colors.white54),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.white54),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Color(0xFF00FF00)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              
            Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                    Expanded(
                      child : Column(
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text("Priority",style: const TextStyle(color: Colors.white54),)),
                            TextField(
                              style: const TextStyle(color: Colors.white54),
                              decoration: InputDecoration(
                                hintText: "Eg: High, Medium, Low",
                                hintStyle: const TextStyle(color: Colors.white54),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(color: Colors.white54),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderSide: const BorderSide(color: Color(0xFF00FF00)),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),),],),),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text("Category", style: const TextStyle(color: Colors.white54)),
                          ),
                          TextField(
                            style: const TextStyle(color: Colors.white54),
                            decoration: InputDecoration(
                              hintText: "Eg: Work, Personal",
                              hintStyle: const TextStyle(color: Colors.white54),
                              enabledBorder: OutlineInputBorder(
                                borderSide: const BorderSide(color: Colors.white54),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: const BorderSide(color: Color(0xFF00FF00)),
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 20),

              Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Deadline",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white54,
                      ),
                    ),),
                  TextField(
                    controller: date,
                    readOnly: true,
                    focusNode: dateFocus,
                    showCursor: false,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Select date",
                      hintStyle: const TextStyle(color: Colors.white54),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.white54),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Color(0xFF00FF00)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onTap: () async {
                      dateFocus.unfocus();
                      DateTime? pickedDate = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: const ColorScheme.dark(
                                primary: Color(0xFF00FF00),
                                onPrimary: Colors.black,
                                surface: Color.fromARGB(255, 22, 27, 34),
                                onSurface: Colors.white,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );

                      if (pickedDate != null) {
                        date.text = "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";
                      }
                  },),
                ],
              ),

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: () {Navigator.pop(context);},
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00FF00),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  "Add Task",
                  style: TextStyle(color: Colors.black),
                ),
              ),
            ],
          ),
        );
      }
    }