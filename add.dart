import 'package:flutter/material.dart';
import 'package:to_do_list/widget.dart';

class Addtask extends StatefulWidget {
  const Addtask({super.key});

  @override
  State<Addtask> createState() => _AddtaskState();
}

class _AddtaskState extends State<Addtask> {

  TextEditingController task = TextEditingController();
  String defaultPriority = "Medium"; 
  TextEditingController category = TextEditingController();
  TextEditingController date = TextEditingController();
  FocusNode dateFocus = FocusNode();
  @override
  Widget build(BuildContext context) {

    void display (){
      print(task.text);
      print(defaultPriority);
      print(category.text);
      print(date.text);
    }


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
                child: const Text(
                  "Task name",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white54,
                  ),
                ),
              ),

              const SizedBox(height: 5),

              Textstyler(controller: task, hint: "Enter your task"),

              const SizedBox(height: 20),

              Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                      Expanded(
                        child : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Priority",style: TextStyle(color: Colors.white54),),
                                Theme(
                                  data: Theme.of(context).copyWith(
                                    splashColor: Colors.transparent,
                                    highlightColor: Colors.transparent,
                                  ),
                                  child: DropdownButtonFormField<String>(
                                    isExpanded: true,
                                    initialValue: defaultPriority,
                                    dropdownColor: const Color.fromARGB(255, 22, 27, 34),
                                    borderRadius: BorderRadius.circular(10),
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
                                    ),
                                  
                                    items: ["High", "Medium", "Low"].map((value) {
                                      return DropdownMenuItem(
                                        value: value,
                                        child: Text(value),
                                      );
                                    }).toList(),
                                  
                                    onChanged: (value) {
                                      setState(() {
                                        defaultPriority = value!;
                                      });
                                    },
                                  ),
                                ),
                                    ],),),

                      const SizedBox(width: 10),
                      
                      Expanded(
                        child: Column(
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: const Text("Category", style: TextStyle(color: Colors.white54)),
                            ),
                            Textstyler(controller: category, hint: "Enter your category"),
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
                    child: const Text(
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
                    style: const TextStyle(color: Colors.white54),
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
                            child: Center(
                              child: SizedBox(
                                width: MediaQuery.of(context).size.width * 0.7,
                                height: 550,
                                child: child,
                              ),
                            ),
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
                onPressed: () {display();Navigator.pop(context);},
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