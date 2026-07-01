import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:to_do_list/repository/task_repository.dart';
import 'package:to_do_list/models/task_model.dart';
import 'package:to_do_list/Screen/edit_screen.dart';
// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'widget.dart';
import 'dart:async';

class Taskview extends StatefulWidget {
  const Taskview({super.key});

  @override
  TaskviewState createState() => TaskviewState();
}

class TaskviewState extends State<Taskview> with WidgetsBindingObserver {
  final _table = TaskRepository();
  List<TaskModel> tasks = [];
  List<TaskModel> filtertask = [];
  List<TaskModel> pendingtasks = [];
  List<TaskModel> completedtasks = [];  
  DateTime currentDate = DateTime.now();
  late Timer _timer;
  String selectedFilter = 'All';
  String searchKeyword = '';
  bool category = false;
  bool _completetask = false;
  RealtimeChannel? _channel;
  StreamSubscription? _visibilitySubscription;


  Future<void> taskdata() async {
    tasks = await _table.getAllTasks();
    _filter(selectedFilter, searchKeyword, category);
    WidgetsBinding.instance.scheduleFrame();
  }

  void search(String filter, String keyword, bool iscategory) {
    selectedFilter = filter;
    searchKeyword = keyword;
    category = iscategory;
    _filter(selectedFilter, searchKeyword, category);
  }

  void _filter(String filter, String keyword, bool iscategory) {
    setState(() {
      var temp = tasks;
      if (filter == 'Deadline') {
        temp = tasks.where((v) => v.deadline != null && v.isComplete == false).toList(); // Show only incomplete tasks
        temp.sort((a, b) =>   a.deadline!.compareTo(b.deadline!),);
      } else if (filter == 'High') {
        temp = tasks.where((task) => task.priority == 'High').toList(); // Show only high-priority tasks
      } else if (filter == 'Medium') {
        temp = tasks.where((task) => task.priority == 'Medium').toList(); // Show only Medium priority tasks
      } else if (filter == 'Low') {
        temp = tasks.where((task) => task.priority == 'Low').toList(); // Show only Low priority tasks
      } else {
        temp = tasks; // If the filter is 'All', show all tasks
      } 
      if (iscategory) {
        temp = temp.where((task) => task.category != null ? task.category!.toLowerCase().contains(keyword.toLowerCase()) : false).toList();
      } else {
        temp = temp.where((task) => task.taskName.toLowerCase().contains(keyword.toLowerCase())).toList();
      }
      filtertask = temp;
      pendingtasks = filtertask.where((task) => !task.isComplete).toList();
      completedtasks = filtertask.where((task) => task.isComplete).toList();

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

  void _setupVisibilityListener() {
    _visibilitySubscription = html.document.onVisibilityChange.listen((event) {
      if (html.document.visibilityState == 'visible') {
        if (mounted) {
          taskdata();
        }
      }
    });
  }

  void listenRealtime() {
    final supabase = Supabase.instance.client;
    if (supabase.auth.currentUser == null) return;

    if (_channel != null) {
      supabase.removeChannel(_channel!);
      _channel = null;
    }

    _channel = supabase
        .channel('task_changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'focus_hub',
          filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'User_id', value: supabase.auth.currentUser!.id),
          callback: (payload) async {
            if (!mounted) return;

            // ✅ 1. Background sync to keep sembast consistent
            unawaited(_table.pullTasksFromSupabase());

            // ✅ 2. Parse the websocket payload for immediate UI update
            final eventType = payload.eventType;
            final newRecord = payload.newRecord;
            final oldRecord = payload.oldRecord;

            setState(() {
              if (eventType == PostgresChangeEvent.insert && newRecord.isNotEmpty) {
                // ✅ FIX: Use fromSupabaseMap instead of fromJson
                final newTask = TaskModel.fromSupabaseMap(newRecord);

                // Prevent duplicates
                tasks.removeWhere((t) => t.taskId == newTask.taskId);
                tasks.add(newTask);
              } else if (eventType == PostgresChangeEvent.update && newRecord.isNotEmpty) {
                // ✅ FIX: Use fromSupabaseMap
                final updatedTask = TaskModel.fromSupabaseMap(newRecord);

                int index = tasks.indexWhere((t) => t.taskId == updatedTask.taskId);
                if (index != -1) {
                  tasks[index] = updatedTask;
                } else {
                  // Task wasn't in local list, add it
                  tasks.add(updatedTask);
                }
              } else if (eventType == PostgresChangeEvent.delete && oldRecord.isNotEmpty) {
                // ✅ FIX: Use Task_id to match your Supabase column name
                final targetId = oldRecord['Task_id'];
                tasks.removeWhere((t) => t.taskId == targetId);
              }

              // ✅ 3. Re-apply current filter and update count
              _filter(selectedFilter, searchKeyword, category);
            });
          },
        )
        .subscribe();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      if (mounted) {
        taskdata();
      }
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    taskdata();
    _midnighttimer(); // Start the midnight timer
    listenRealtime();
    _setupVisibilityListener();
    currentDate = DateTime.now(); // Initialize currentDate with the current date
  }

  @override
  void dispose() {
    if (_channel != null) {
      Supabase.instance.client.removeChannel(_channel!);
    }
    _timer.cancel(); // Cancel the timer when the widget is disposed
    WidgetsBinding.instance.removeObserver(this);
    _visibilitySubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 20, bottom: 20),
      width: (MediaQuery.of(context).size.width * 0.95).clamp(100, 1200),
      decoration: BoxDecoration(color: const Color.fromARGB(255, 22, 27, 34), borderRadius: BorderRadius.circular(15)),
        child: filtertask.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_task_rounded, color: Colors.white54, size: 100),
                      SizedBox(height: 15),
                      Text('No tasks is added yet', style: TextStyle(color: Colors.white54, fontSize: 20)),
                    ],
                  ),
                )
              : Column(children:[
                const SizedBox(height: 10),
                Expanded(child: /* Must use Expanded as its parent. Because Listview is rollable so it ask inifinite height from its parent widget,
                for this one Expanded is used to give it a fixed height if we use column it depends the child height so then it show nothing */
                
                  ListView.builder(
                    itemCount: pendingtasks.length  + 1 + (_completetask ? completedtasks.length : 0),
                    itemBuilder: (context, index) {
                      if (index == pendingtasks.length) { // This if-condition is to place the complete header in place after displaying all the pending task 
                        return Container(
                          color: const Color.fromARGB(255, 22, 27, 34),
                          child: ListTile(
                            title: Text('Completed (${completedtasks.length})', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                            leading: IconButton(
                              icon: Icon(_completetask ? Icons.expand_less : Icons.expand_more, color: Colors.white),
                              onPressed: () {
                                setState(() {
                                  _completetask = !_completetask;
                                });
                              },
                            ),
                          ),
                        );
                      }
                      if(index > pendingtasks.length) 
                      {
                        index = index -1;
                      }
                      /* After placing the complete header the index value is increased by 1 
                      which leads to not displaying the first one task in the completed task list
                      So to fix this issue I decrease the index value by (-1) 
                      Example: 
                      1.) Total task -> 7, pending -> 4, completed -> 3 and _completetask = true
                      2.) itemconut = 4 + 1 + 3 = 8
                      3.) index: [0,1,2,3,4,5,6,7] -> this leads to out of range because filtertask has [0,1,2,3,4,5,6] only 7 task
                      4.) The first (if-statement) execute when the index = 4
                      5.) So then the value in the filtertask[4] will not displayed
                      6.) So that's why I use this second (if-statement) to solve this
                      */
                        return Container(
                        constraints: const BoxConstraints(minHeight: 100), // Set a minimum height 100 for the container to ensure it doesn't shrink too much and this make the container expandable when needed
                        margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: filtertask[index].deadline == null
                                ? Colors.grey
                                : filtertask[index].deadline!.difference(currentDate).inHours <= 96 && filtertask[index].deadline!.difference(currentDate).inHours > 0 && filtertask[index].isComplete == false
                                ? Colors.orange
                                : filtertask[index].deadline!.difference(currentDate).inHours > 0 || filtertask[index].isComplete == true
                                ? Colors.green
                                : Colors.red,
                            width: MediaQuery.of(context).size.width > 620 ? 2 : 1.5,
                          ),
                          color: const Color.fromARGB(255, 13, 17, 23),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                          child: Row(
                            children: [
                              IconButton(
                                icon: Icon(filtertask[index].isComplete ? Icons.task_alt : Icons.circle_outlined),
                                color: filtertask[index].deadline == null
                                    ? Colors.green
                                    : filtertask[index].deadline!.difference(currentDate).inHours <= 96 && filtertask[index].deadline!.difference(currentDate).inHours > 0 && filtertask[index].isComplete == false
                                    ? Colors.orange
                                    : filtertask[index].deadline!.difference(currentDate).inHours > 0 || filtertask[index].isComplete == true
                                    ? Colors.green
                                    : Colors.red,
                                onPressed: () async {
                                  setState(() {
                                    filtertask[index].isComplete = !filtertask[index].isComplete;
                                  });
                                  await _table.completeTask(TaskModel(taskId: filtertask[index].taskId, taskName: filtertask[index].taskName, priority: filtertask[index].priority, createdAt: filtertask[index].createdAt, updatedAt: filtertask[index].updatedAt, deadline: filtertask[index].deadline, category: filtertask[index].category, isComplete: filtertask[index].isComplete, isSynced: filtertask[index].isSynced, userId: filtertask[index].userId));
                                  taskdata();
                                },
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min, // We not set the min height of the parent container so to avoid the text overflow we use this property to make the column height as minimum as possible
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                         Text(
                                            filtertask[index].taskName, // Use the task title from the list
                                            style: const TextStyle(height: 1.3, color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                          ),
                                    
                                    const SizedBox(height: 5),
                                    TaskSubtitle(
                                      category: filtertask[index].category, // Use the task category from the list
                                      deadline: filtertask[index].deadline, // Use the task deadline from the list
                                      datecolor: filtertask[index].deadline == null
                                          ? 'grey'
                                          : filtertask[index].deadline!.difference(currentDate).inHours <= 96 && filtertask[index].deadline!.difference(currentDate).inHours > 0 && filtertask[index].isComplete == false
                                          ? 'orange'
                                          : filtertask[index].deadline!.difference(currentDate).inHours > 96 || filtertask[index].isComplete == true
                                          ? 'green'
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
                                  color: filtertask[index].priority == 'High'
                                      ? Colors.red
                                      : filtertask[index].priority == 'Medium'
                                      ? Colors.orange
                                      : Colors.green,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Theme(
                                data: Theme.of(context).copyWith(splashColor: Colors.transparent, highlightColor: Color(0x26FFFFFF)),
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
                                          Text('Edit', style: TextStyle(color: Colors.white)),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete, color: Colors.red),
                                          SizedBox(width: 10),
                                          Text('Delete', style: TextStyle(color: Colors.white)),
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
                                          child: Container(
                                            clipBehavior: Clip.hardEdge, // it prevents the content from Addtask is overflowing outside the container when the keyboard appears
                                            decoration: BoxDecoration(color: Color.fromARGB(255, 13, 17, 23), borderRadius: BorderRadius.circular(15)),
                                            width: (MediaQuery.of(context).size.width * 0.75).clamp(100, 475),
                                            height: (MediaQuery.of(context).size.height * 0.6).clamp(420, 475),
                                            child: Edittask(currenttask: filtertask[index].taskName, currentpriority: filtertask[index].priority, currentcategory: filtertask[index].category, currentdeadline: filtertask[index].deadline, created: filtertask[index].createdAt, taskId: filtertask[index].taskId, completion: filtertask[index].isComplete),
                                          ),
                                        ),
                                      );
                                      if (edited == true) {
                                        taskdata(); // Refresh the task list after editing
                                      }
                                    } else if (value == 'delete') {
                                      final removedtask = filtertask[index];
                                      setState(() {
                                        filtertask.removeAt(index); // Remove the task from the list
                                        pendingtasks = filtertask.where((task) => !task.isComplete).toList();
                                        completedtasks = filtertask.where((task) => task.isComplete).toList();
                                      });
                                      try {
                                        await _table.deleteTask(removedtask.taskId); // Delete the task from the database
                                      } catch (e) {
                                        setState(() {
                                          filtertask.insert(index, removedtask); // Revert the UI change if deletion fails
                                        });
                                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete task. Please try again.')));
                                      }
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ]
            )       
    );
  }
}
