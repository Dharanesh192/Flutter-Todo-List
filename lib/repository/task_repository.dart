import 'package:connectivity_plus/connectivity_plus.dart'; // To check the internet connection
import 'package:path/path.dart'; // This package is used to write the file path as per the OS (Andiroid, iOS, web) and it is used in the line 31 to join the path of the internal storage and the name of the database file
import 'package:path_provider/path_provider.dart'; // To get the path of the internal storage in mobile and it is used in the line 30 to get the path of the internal storage
import 'package:sembast/sembast_io.dart'; // Sembast Database for mobile
import 'package:sembast_web/sembast_web.dart'; // Database for web
import 'package:flutter/foundation.dart'; // Used to check the platform (web or mobile) and it is used in the line 22 to check the platform and initialize the database accordingly
import 'package:supabase_flutter/supabase_flutter.dart'; // To use the features of Supabase
import 'package:uuid/uuid.dart'; // To generate unique ID
import 'package:to_do_list/models/task_model.dart'; // File path to the task model to convert the list data into the map data

class TaskRepository 
{
  // Variable declaration
  static Database? _db; //initialize the variable for database with the database type and it is a static variable it means one database can be used across multi object and can be null
  final _table = stringMapStoreFactory.store('tasks'); // To create a table in the database with the name tasks
  final _supabase = Supabase.instance.client; // Declare variable to use the supabase function
  final _uuid = const Uuid(); // Declare a variable to use the UUID function to generate unique ID for each task

  // Database initialization
  Future<Database> get dbcreation async {
    if (_db != null) {// check the database is created or not
    return _db!; // If created retruns it otherwise move to the next if statement and that (_) means it is private variable and (!) means it can't a null value
    } 

    if (kIsWeb) // Check if the application is running in web browser or not
    {
      _db = await databaseFactoryWeb.openDatabase('tasks.db'); // declare the database in the bulid-in browser database (IndexedDB)
    } 
    else { // If the application runs in moblie
      final appDir = await getApplicationDocumentsDirectory(); //Get the internal storage path as (/data/data/com.Task_Managment/app_flutter/tasks_data.db) which is not directly visible in file manager
      final dbPath = join(appDir.path, 'tasks_data.db'); //Append the appdir path with tasks (Internal storage/Android/Data/tasks_data)
      _db = await databaseFactoryIo.openDatabase(dbPath); // Declare the database in the provided path
    }
    return _db!; // If created retruns it otherwise move to the next if statement and that (_) means it is private variable and (!) means it guarantee this is not null right now
  }

  // Add Task
  Future<void> addTask(TaskModel task) async { //This function is called from the add_task.dart file to add tasks in the local database
    final db = await dbcreation; // Initialize the database

    task.taskId = _uuid.v4(); // create a Unique ID for each task
    task.createdAt = DateTime.now(); // Assign the current time of the task creatation
    task.userId = _supabase.auth.currentUser?.id; // To get the User ID
    task.isSynced = false; // Initial value is because it is not synced with supabase
    task.updatedAt = DateTime.now(); // Assign the current time of the task creatation or edited


    await _table.record(task.taskId).put(db, task.toMap()); // Save to sembast first (offline first approch!)

    // Check internet connection and sync it the supabase
    final connectivity = await Connectivity().checkConnectivity(); //  Create a variable for Connectivity function
    if (connectivity != ConnectivityResult.none) { // If the internet connected
      await _syncTask(task); // It call the Synctask function
    }
  }

  // Sync single task to Supabase
  Future<void> _syncTask(TaskModel task) async {

    if(_supabase.auth.currentUser == null) return;

    try { //Try we try-catch block to avoid crashing the application

      task.userId = _supabase.auth.currentUser!.id; // To get the User ID
      await _supabase.from('focus_hub').upsert(task.toSupabaseMap());
      task.isSynced = true; // If sync Success → update isSynced = true in local database (sembast)

      final db = await dbcreation; // db (local variable) is killed at end of function but _db (static variable) stays alive entire app lifetime (both db and _db are different)
      await _table.record(task.taskId).put(db, task.toMap()); // Updating the value

    } catch (e) {
      debugPrint('Sync failed: $e'); // isSynced stays false — will retry later and tells what goes wrong
    }
  }

  // ✅ Sync all pending tasks (called when internet returns)
  Future<void> syncPendingTasks() async {
    final db = await dbcreation; // Call the database db store the object of the database not the actual database

    if(_supabase.auth.currentUser == null) return;

    final findcase = Finder( filter: Filter.equals('isSynced', false),); // The finder is a in-build function in the sembast and filter is the in-built function in finder to find all tasks where isSynced = false
    final records = await _table.find(db, finder: findcase); //This statement takes all records from the table (tasks) table in the Sembast database that match the condition defined in the finder (i.e., isSynced = false), and stores them in the records variable
    final pendingTasks = records.map((r) => TaskModel.fromMap(r.value)).toList(); /* This statement convert the list of map data in the records into the list of task model data and store it in the pendingTasks variable 
    where records.map() is used to iterate through each record and r.value is the actual value of the record that is converted into the task model data using the fromMap function and then convert it into the list using toList() function*/

    for (var task in pendingTasks) // call the syncTask function until all task are synced
    {
      await _syncTask(task);
    }
  }

  // Get all tasks
  Future<List<TaskModel>> getAllTasks() async {
    final db = await dbcreation; // database object

    final finder = Finder(sortOrders: [SortOrder('isComplete',true),SortOrder('createdAt', false)],); // Sort by createdAt — newest first
    final records = await _table.find(db, finder: finder); 
    return records.map((r) => TaskModel.fromMap(r.value)).toList();
  }

  // Delete task
  Future<void> deleteTask(String taskId) async { // In this function it comes with a task ID 
    final db = await dbcreation;

    await _table.record(taskId).delete(db); // Delete that task from sembast

    
    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity != ConnectivityResult.none) // Delete from Supabase if internet available
     {
      await _supabase.from('focus_hub').delete().eq('Task_id', taskId); // It means from the table focus_hub delete a task which task ID is equal to the given task_ID
    }
  }

  // Complete task
  Future<void> completeTask(TaskModel task) async {
    final db = await dbcreation;

    task.isSynced = false; // And sync as false to move it to the pending list

    await _table.record(task.taskId).put(db, task.toMap()); // Update sembast 

    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity != ConnectivityResult.none) {
      await _syncTask(task); // Sync to the supabase if internet available
    }
  }

  Future<void> editTask(TaskModel task) async {
    final db = await dbcreation;
    
    task.isSynced = false; // And sync as false to move it to the pending list

    await _table.record(task.taskId).put(db, task.toMap()); // Update sembast 

    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity != ConnectivityResult.none) {
      await _syncTask(task); // Sync to the supabase if internet available
    }
  }

  // Add this function
    Future<int> getTaskCount() async {
      final db = await dbcreation;
      final records = await _table.find(db);
      return records.length;
  }
  
  Future<void> pullTasksFromSupabase() async {
    if (_supabase.auth.currentUser == null) return;
    final db = await dbcreation;
    final response = await _supabase
        .from('focus_hub')
        .select()
        .eq('User_id', _supabase.auth.currentUser!.id);

    for (var row in response) {
      final existingRecord = await _table.record(row['Task_id']).get(db);
      final task = TaskModel.fromSupabaseMap(row);
    // 👉 if not exists → insert
    // 👉 if exists → update ONLY if newer
    if (existingRecord != null) {
      final localTask = TaskModel.fromMap(existingRecord);

      // 🧠 only update if server version is newer
      if (task.updatedAt.isAfter(localTask.updatedAt)) {
        await _table.record(task.taskId).put(db, task.toMap());
      }
    } 
    else {
      await _table.record(task.taskId).put(db, task.toMap());
    }
    }}

  Future<bool> guesttask()async {
    final db = await dbcreation;
    final task = Finder(filter: Filter.isNull('userId'));
    final record = await _table.find(db,finder: task);
    return record.isNotEmpty;
  }

  Future<int> guesttaskcount()async {
    final db = await dbcreation;
    final task = Finder(filter: Filter.isNull('userId'));
    final record = await _table.find(db,finder: task);
    return record.length;
  }

  Future<void> deleteusertask()async {
    final db = await dbcreation;
    final task = Finder(filter: Filter.notNull('userId'));
    await _table.delete(db,finder: task);
  }

  }

  