import 'package:flutter/material.dart';
import 'add.dart';
void main(){
  runApp(const Homepage());
}

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _Homepagestate();
}

class _Homepagestate extends State<Homepage>{
  TextEditingController input = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          toolbarHeight: 70,
          title: Text("Tasks",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 40,
            color: Color(0xFF00FF00)
            ),),
          backgroundColor: const Color.fromARGB(255, 22, 27, 34),
          leading: Builder(
          builder: (context) => IconButton(
          icon: Icon(Icons.dashboard,color: Color(0xFF00FF00)),
          onPressed: () =>Scaffold.of(context).openDrawer(),
        ),),),
        drawer: Drawer(
          child: ListView(
            children: [
              const DrawerHeader(
                decoration: BoxDecoration(
                  color: Color.fromARGB(255, 22, 27, 34),
                ),
                child: Align(
                  alignment: Alignment.center,
                  child: Text('Navigation Drawer',
                  style: TextStyle(
                    color: Color(0xFF00FF00),
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),),
              ),),
              Builder(
                builder: (context) => ListTile(
                  leading: const Icon(Icons.task_alt),
                  title: const Text('Tasks'),
                  onTap: () {
                    Navigator.pop(context); 
                  },
                ),
              ),
              Builder(
                builder: (context) => ListTile(
                  leading: const Icon(Icons.analytics),
                  title: const Text('Analytics'),
                  onTap: () {
                    Navigator.pop(context); 
                  },
                ),
              ),
              Builder(
                builder: (context) => ListTile(
                  leading: const Icon(Icons.calendar_month),
                  title: const Text('Calendar'),
                  onTap: () => Navigator.pop(context),
                ),
              ),
            ],
          ),
        ),
        body: Container(
          width: double.infinity,
          height: double.infinity,
          color: const Color.fromARGB(255, 13, 17, 23),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                  width: 400,
                  margin: EdgeInsets.only(top: 20),
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Color.fromARGB(255, 22, 27, 34),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: TextField(
                    controller: input,
                    decoration: InputDecoration(
                      prefixIcon: Icon( Icons.search, color: Color.fromARGB(255, 117, 117, 115)),
                      hintText: 'Search bar',
                      hintStyle: TextStyle(color: Color.fromARGB(255, 117, 117, 115), fontSize: 20, fontWeight: FontWeight.bold),
                      border: InputBorder.none,
                ),style: TextStyle(color: Color.fromARGB(255, 117, 117, 115),fontSize: 20, fontWeight: FontWeight.bold),
                ),),
                ],
              )
              ],
          ),
        ),
        floatingActionButton: Builder(
          builder: (context) => FloatingActionButton(
            onPressed: (){
               showDialog(
                  context: context,
                  builder: (context) => Dialog(
                    backgroundColor: const Color.fromARGB(255, 22, 27, 34),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child:SizedBox(
                      width: MediaQuery.of(context).size.width * 0.4,
                      height: MediaQuery.of(context).size.height * 0.6,
                    child: const Addtask(),
                  ),
                ),);
            },
            backgroundColor: const Color(0xFF00FF00),
            shape: const CircleBorder(),
            child: const Icon(Icons.add_task_sharp, color: Colors.black,size: 35,),
          ),
        ),
      ),
    );
  }
}