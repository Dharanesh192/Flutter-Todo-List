class TaskModel // This is a custom database for this project
 {
  String taskId;           // UUID — Supabase sync
  String? userId;          // Logged in user ID
  String taskName;         // Compulsory
  String priority;         // High, Medium, Low
  String? category;        // category is Optional but it has a default value as (Medium)
  DateTime? deadline;      // Optional
  bool isComplete;         // It is a binary value as (True/False)
  bool isSynced;           // It is a binary value as (True/False)
  DateTime createdAt;      // It inputs are date and time
  DateTime updatedAt;      // It inputs are date and time

  TaskModel({
    required this.taskId,  // It is compelsory to give value
    this.userId,           // It is a optional input value
    required this.taskName,
    required this.priority,
    this.category,
    this.deadline,
    this.isComplete = false,   // Initially it has a (False) value 
    this.isSynced = false,     // Initially it has a (False) value 
    required this.createdAt,
    required this.updatedAt,
  });

  // Sembast stores Map — convert to Map
  Map<String, dynamic> toMap() {
    return {
      'taskId': taskId,
      'userId': userId,
      'taskName': taskName,
      'priority': priority,
      'category': category,
      'deadline': deadline?.toIso8601String(),
      'isComplete': isComplete,
      'isSynced': isSynced,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Map from Sembast → convert back to TaskModel
  factory TaskModel.fromMap(Map<String, dynamic> map) {
    return TaskModel(
      taskId: map['taskId'],
      userId: map['userId'],
      taskName: map['taskName'],
      priority: map['priority'],
      category: map['category'],
      deadline: map['deadline'] != null 
          ? DateTime.parse(map['deadline']) 
          : null,
      isComplete: map['isComplete'] ?? false,
      isSynced: map['isSynced'] ?? false,
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),

    );
  }

  Map<String, dynamic> toSupabaseMap() {
  return {
    'Task_id': taskId,
    'User_id': userId,
    'Task_name': taskName,
    'Deadline': deadline?.toIso8601String(),
    'Category': category,
    'Priority': priority,
    'is_complete': isComplete,
    'Created_date': createdAt.toIso8601String(),
    'Updated_at': updatedAt.toIso8601String(),
  };
}

  factory TaskModel.fromSupabaseMap(Map<String, dynamic> row) {
  return TaskModel(
    taskId: row['Task_id'],
    userId: row['User_id'],
    taskName: row['Task_name'],
    priority: row['Priority'],
    category: row['Category'],
    deadline: row['Deadline'] != null ? DateTime.parse(row['Deadline']) : null,
    isComplete: row['is_complete'] ?? false,
    isSynced: true,            // always true — just came from Supabase
    createdAt: DateTime.parse(row['Created_date']),
    updatedAt: DateTime.parse(row['Updated_at']),
  );
}

}