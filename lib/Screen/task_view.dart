import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:to_do_list/repository/task_repository.dart';
import 'package:to_do_list/models/task_model.dart';
import 'package:to_do_list/Screen/edit_screen.dart';
import 'widget.dart';
import 'dart:async';

class Taskview extends StatefulWidget {
  const Taskview({super.key});

  @override
  TaskviewState createState() => TaskviewState();
}

class TaskviewState extends State<Taskview>{

  final _table = TaskRepository();
  int taskcount = 0;
  List<TaskModel> tasks = [];
  List<TaskModel> filtertask = [];
  DateTime currentDate = DateTime.now();
  late Timer _timer;
  String selectedFilter = 'All';
  String searchKeyword = '';
  bool category = false;
  late final RealtimeChannel? _channel;

  Future<void> taskdata() async {
    final value = await _table.getTaskCount();
    tasks = await _table.getAllTasks();
    setState(() {
      taskcount = value;
      filtertask = tasks;
    });
    search(selectedFilter, searchKeyword, category);
    WidgetsBinding.instance.scheduleFrame();
  }

  void search(String filter,String keyword,bool iscategory){
    selectedFilter = filter;
    searchKeyword = keyword;
    category = iscategory;
    _filter(selectedFilter,searchKeyword,category);
  }

  void _filter(String filter,String keyword,bool iscategory){
    setState((){
      var temp = tasks;
      if(filter == 'All'){
        temp = tasks; // If the filter is 'All', show all tasks
      }
      else if(filter == 'Completed'){
        temp = tasks.where((task) => task.isComplete).toList(); // Show only completed tasks
      }
      else if(filter == 'Pending'){
        temp = tasks.where((task) => !task.isComplete).toList(); // Show only incomplete tasks
      }
      else if(filter == 'High'){
        temp = tasks.where((task) => task.priority == 'High').toList(); // Show only high-priority tasks
      }
      else if(filter == 'Medium'){
        temp = tasks.where((task) => task.priority == 'Medium').toList(); // Show only Medium priority tasks
      }
      else if(filter == 'Low'){
        temp = tasks.where((task) => task.priority == 'Low').toList(); // Show only Low priority tasks
      }
        if(iscategory){
          temp = temp.where((task) => task.category!=null ? task.category!.toLowerCase().contains(keyword.toLowerCase()) : false).toList();
        }
        else{
          temp = temp.where((task) => task.taskName.toLowerCase().contains(keyword.toLowerCase())).toList();
        }
      filtertask = temp;
    });
  }

  void _midnighttimer() {
    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    final durationUntilMidnight = nextMidnight.difference(now);

    _timer = Timer(durationUntilMidnight, () {
      setState(() {
        currentDate = DateTime.now(); // Update the current date at midnight
      });
      _midnighttimer(); // Reschedule the timer for the next midnight
    });
  }

  void listenRealtime() {
  final supabase = Supabase.instance.client;
  if (supabase.auth.currentUser == null) return; // guest users skip this

  _channel = supabase
    .channel('task_changes')          // unique websocket topic name
    .onPostgresChanges(
      event: PostgresChangeEvent.all, // insert + update + delete
      schema: 'public',
      table: 'focus_hub',       // supabase table to watch
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'User_id',
        value: supabase.auth.currentUser!.id, // only MY tasks
      ),
      callback: (payload) async {
        await TaskRepository().pullTasksFromSupabase(); // fetch latest
        if (!mounted) return;
        await taskdata(); // refresh UI
      },
    ).subscribe(); // open websocket + start listening
}

  @override
  void initState() {
    super.initState();
    taskdata();
    _midnighttimer(); // Start the midnight timer
    listenRealtime();
    currentDate = DateTime.now(); // Initialize currentDate with the current date
  }

  @override
  void dispose() {
      if (_channel != null) {
          Supabase.instance.client.removeChannel(_channel);}
      _timer.cancel(); // Cancel the timer when the widget is disposed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
                margin: EdgeInsets.only(top: 20,bottom: 20),
                width: (MediaQuery.of(context).size.width * 0.95).clamp(100, 1150),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 22, 27, 34),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  children: [
                        const SizedBox(height: 10),
                         Expanded(
                           child: filtertask.isEmpty ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                            Icon(Icons.add_task_rounded, color: Colors.white54, size: 100),
                            SizedBox(height: 15),
                            Text(
                              'No tasks is added yet',
                              style: TextStyle(color: Colors.white54, fontSize: 20),
                            ),])
                           )
                           : ListView.builder(
                              itemCount: filtertask.length, // Use the task count from the state
                              itemBuilder: (context, index) {
                                        return Container(
                                          height: 100,
                                          margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(10),
                                            border: Border.all(color: filtertask[index].deadline == null ? Colors.grey 
                                            : filtertask[index].deadline!.difference(currentDate).inHours  <= 96 && filtertask[index].deadline!.difference(currentDate).inHours > 0 && filtertask[index].isComplete == false ? Colors.orange 
                                            : filtertask[index].deadline!.difference(currentDate).inHours > 0 || filtertask[index].isComplete == true ? Colors.green 
                                            : Colors.red,
                                            width: MediaQuery.of(context).size.width > 620 ? 2 : 1.5),
                                            color: const Color.fromARGB(255, 13, 17, 23),
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                            child: Row(
                                              children: [
                                               IconButton(
                                                 icon: Icon(filtertask[index].isComplete ? Icons.task_alt : Icons.circle_outlined),
                                                 color:  filtertask[index].deadline == null ? Colors.green 
                                                : filtertask[index].deadline!.difference(currentDate).inHours  <= 96 && filtertask[index].deadline!.difference(currentDate).inHours > 0 && filtertask[index].isComplete == false ? Colors.orange 
                                                : filtertask[index].deadline!.difference(currentDate).inHours > 0 || filtertask[index].isComplete == true ? Colors.green 
                                                : Colors.red,
                                                 onPressed: () async {
                                                  setState(() {
                                                    filtertask[index].isComplete = !filtertask[index].isComplete; 
                                                  });
                                                   await _table.completeTask(TaskModel(taskId:  filtertask[index].taskId,
                                                    taskName: filtertask[index].taskName,
                                                    priority: filtertask[index].priority,
                                                    createdAt: filtertask[index].createdAt,
                                                    updatedAt: filtertask[index].updatedAt,
                                                    deadline: filtertask[index].deadline,
                                                    category: filtertask[index].category,
                                                    isComplete: filtertask[index].isComplete,
                                                    isSynced: filtertask[index].isSynced,
                                                    userId: filtertask[index].userId,  ));
                                                    taskdata();
                                                  },
                                               ),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: Column(
                                                    mainAxisAlignment: MainAxisAlignment.center,
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      SizedBox(
                                                        height: 25,
                                                        child: SingleChildScrollView(
                                                          physics: ClampingScrollPhysics(),
                                                          child: Text(
                                                            filtertask[index].taskName, // Use the task title from the list
                                                            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(height: 5),
                                                      TaskSubtitle(
                                                        category: filtertask[index].category, // Use the task category from the list
                                                        deadline: filtertask[index].deadline, // Use the task deadline from the list
                                                        datecolor : filtertask[index].deadline == null ? 'grey' 
                                                        : filtertask[index].deadline!.difference(currentDate).inHours <= 96 && filtertask[index].deadline!.difference(currentDate).inHours > 0 && filtertask[index].isComplete == false? 'orange' 
                                                        : filtertask[index].deadline!.difference(currentDate).inHours > 96 || filtertask[index].isComplete == true ? 'green' 
                                                        : 'red',
                                                      ),
                                                    ],
                                                  ),
                                                ),

                                                const SizedBox(width: 10),

                                                Container(
                                                  padding: const EdgeInsets.all(10),
                                                  margin: const EdgeInsets.only(right: 20),
                                                  decoration: BoxDecoration(
                                                    color: filtertask[index].priority == 'High' ? Colors.red
                                                    : filtertask[index].priority == 'Medium' ? Colors.orange 
                                                    : Colors.green,
                                                    shape: BoxShape.circle,
                                                  ),
                                                ),
                                                Theme(
                                                    data: Theme.of(context).copyWith(
                                                      splashColor: Colors.transparent,
                                                      highlightColor: Color(0x26FFFFFF)),
                                                      child: PopupMenuButton<String>(
                                                        color: const Color.fromARGB(255, 22, 27, 34),
                                                        icon: Icon(Icons.more_vert, color: Colors.white), // 3 dots icon
                                                        shape: RoundedRectangleBorder(
                                                          side: BorderSide(color: Colors.white, width: 2),
                                                          borderRadius: BorderRadius.circular(10),
                                                        ),
                                                      
                                                        itemBuilder: (context) => [
                                                          PopupMenuItem(
                                                            value: 'edit',
                                                            child: Row(
                                                              children: [
                                                                Icon(Icons.edit, color: Colors.blue[300]),
                                                                SizedBox(width: 10),
                                                                Text('Edit',style: TextStyle(color: Colors.white),),
                                                              ],
                                                            ),
                                                          ),
                                                          PopupMenuItem(
                                                            value: 'delete',
                                                            child: Row(
                                                              children: [
                                                                Icon(Icons.delete, color: Colors.red),
                                                                SizedBox(width: 10),
                                                                Text('Delete',style: TextStyle(color: Colors.white),),
                                                              ],
                                                            ),
                                                          ),
                                                        ],
                                                      
                                                       onSelected: (value) async {
                                                            if (value == 'edit') {
                                                              final edited = await showModalBottomSheet(
                                                                context: context,
                                                                isScrollControlled: true,
                                                                backgroundColor: Colors.transparent,
                                                                builder: (context) => Center(
                                                                  child: Container (
                                                                    clipBehavior: Clip.hardEdge, // it prevents the content from Addtask is overflowing outside the container when the keyboard appears
                                                                    decoration: BoxDecoration(
                                                                      color: Color.fromARGB(255, 13, 17, 23),
                                                                      borderRadius: BorderRadius.circular(15),
                                                                    ),
                                                                    width: (MediaQuery.of(context).size.width * 0.75).clamp(100, 475),
                                                                    height: (MediaQuery.of(context).size.height * 0.6).clamp(420, 475),
                                                                    child: Edittask(
                                                                    currenttask:filtertask[index].taskName,
                                                                    currentpriority: filtertask[index].priority,
                                                                    currentcategory: filtertask[index].category,
                                                                    currentdeadline: filtertask[index].deadline,
                                                                    created: filtertask[index].createdAt,
                                                                    taskId: filtertask[index].taskId,
                                                                    completion: filtertask[index].isComplete,
                                                                  ),
                                                                  ),
                                                                ),
                                                              );
                                                              if(edited == true){
                                                                taskdata(); // Refresh the task list after editing
                                                              }
                                                            }
                                                            else if (value == 'delete') {
                                                                final removedtask = filtertask[index];
                                                                setState(() {
                                                                filtertask.removeAt(index); // Remove the task from the list
                                                                taskcount--; // Decrease the task count
                                                              });
                                                              try {
                                                                await _table.deleteTask(removedtask.taskId); // Delete the task from the database
                                                              } catch (e) {
                                                                setState(() {
                                                                  filtertask.insert(index, removedtask); // Revert the UI change if deletion fails
                                                                  taskcount++; // Revert the task count
                                                                });
                                                                ScaffoldMessenger.of(context).showSnackBar(
                                                                  SnackBar(content: Text('Failed to delete task. Please try again.')),
                                                                );
                                                              }
                                                          }
                                                        },
                                                      ),
                                                    ),]  
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  ],));}}                