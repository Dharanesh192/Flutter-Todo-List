import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:to_do_list/repository/task_repository.dart';
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

class TaskSubtitle extends StatelessWidget {
  final String? category;
  final DateTime? deadline;
  final String? datecolor;

  const TaskSubtitle({
    required this.category,
    required this.deadline,
    required this.datecolor,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = [
      if (category != null)
        Text(
          '$category   ',
          style: const TextStyle(color: Colors.white70),
        ),
      if (deadline != null)
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.calendar_today, size: 14, color: datecolor == 'green' ? Colors.green : datecolor == 'orange' ? Colors.orange : Colors.red),
            Text(
              ' ${deadline.toString().replaceAll(' 00:00:00.000', '')}',
              style: TextStyle(color : datecolor == 'grey' ? Colors.grey : datecolor == 'green' ? Colors.green : datecolor == 'orange' ? Colors.orange : Colors.red, fontWeight: FontWeight.bold),
            ),
          ],
        ),
    ];

    if (children.isEmpty) return const SizedBox.shrink();

    return MediaQuery.of(context).size.width > 410
        ? Row(children: children)
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          );
  }
}

class Editortextstyler extends StatelessWidget {

  final TextEditingController controller;
  final String hint;

  const Editortextstyler({
    required this.controller,
    required this.hint,
    super.key
  });
  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: true,
      style: const TextStyle(color: Colors.white54),
      decoration: InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white54),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.white54),
        borderRadius: BorderRadius.circular(10),),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Color(0xFF00BBFF)),
        borderRadius: BorderRadius.circular(10),
      ),),);
  }
}

class Logscreen extends StatefulWidget {

  final String textword;
  final bool method;

  const Logscreen({
    required this.textword,
    required this.method,
    super.key});

  @override
  State<Logscreen> createState() => _LogscreenState();
}

class _LogscreenState extends State<Logscreen> {
  final _supabase = Supabase.instance.client;
  bool _isLoading = false;
  bool guest = true;

  Future<void> googleSignIn() async {
    setState(() => _isLoading = true);
    try {
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb ? '${Uri.base.origin}/' : 'io.supabase.focushub://login-callback');  
    }
     catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> googleSignout() async {
    setState(() => _isLoading = true);
    try {
      await TaskRepository().deleteusertask();
      await _supabase.auth.signOut();
      setState(() {});
      if (mounted) Navigator.pop(context);
    } 
    catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logout failed: $e')),
        );
      }
    } 
    finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> syncoutprocess() async {
    setState(() => _isLoading = true);
    try {
      await TaskRepository().pullTasksFromSupabase();
      await TaskRepository().syncPendingTasks();
      await TaskRepository().deleteusertask();
      await _supabase.auth.signOut();   

      Navigator.pop(context);
    }
    catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sync task failed: $e')),
        );
      }
    }
    finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> syncdisplaybutton() async{
    final result =  await TaskRepository().guesttask();
    setState(() => guest = result); 
  }

  @override
  void initState(){
    syncdisplaybutton();
    super.initState();
  } 


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 13, 17, 23),
      body: Center (
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Focus Hub",
              style: TextStyle(
                fontFamily: 'Teko',
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Color(0xFF00FF00),
              ),
            ),
            const SizedBox(height: 10),
            
            Text( widget.method ? "Backup your task efficiently" : widget.method == false && guest ? "Wait Sync the task's if you don't \n\nThen we will \"Meet again Bye\"" : "Then we will Meet again Bye",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white54,
                ),
              ),
             
            const SizedBox(height: 60),
            _isLoading
                ? const CircularProgressIndicator(color: Color(0xFF00FF00))
                : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.method == false && guest)
                        ElevatedButton.icon(
                          onPressed: syncoutprocess,
                          icon: Icon(Icons.sync_rounded, color: Colors.black),
                          label: Text("Sync",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00FF00),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),

                    const SizedBox(width: 20),

                    ElevatedButton.icon(
                        onPressed: widget.method ? googleSignIn : googleSignout,
                        icon: Icon(widget.method ? Icons.login_outlined : Icons.logout_outlined, color: Colors.black),
                        label: Text(widget.textword,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00FF00),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                  ],
                ),
          ],
        ),
      ),
    );
  }
}

class Syncscreen extends StatefulWidget {
  const Syncscreen({super.key});

  @override
  State<Syncscreen> createState() => SyncscreenState();
}

class SyncscreenState extends State<Syncscreen> {
  bool _isLoading = false;

  Future<void> syncprocess() async {
    setState(() => _isLoading = true);
    try {
      await TaskRepository().pullTasksFromSupabase();
      await TaskRepository().syncPendingTasks();
      if(mounted) Navigator.pop(context);
    }
    catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sync task failed: $e')),
        );
      }
    }
    finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 13, 17, 23),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Focus Hub",
              style: TextStyle(
                fontFamily: 'Teko',
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Color(0xFF00FF00),
              ),
            ),
            const SizedBox(height: 10),
             Text("Should I sync your local task",
              style: TextStyle(
                fontSize: 16,
                color: Colors.white54,
              ),
            ),
            const SizedBox(height: 60),
            _isLoading
                ? const CircularProgressIndicator(color: Color(0xFF00FF00))
                : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                        onPressed: syncprocess,
                        icon: Icon(Icons.sync_rounded, color: Colors.black),
                        label: Text("Sync",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00FF00),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),

                    const SizedBox(width: 20,),

                    TextButton(
                      onPressed: () async {
                        await TaskRepository().pullTasksFromSupabase();
                        Navigator.pop(context);
                      },
                      child: const Text(
                        "Maybe later",
                        style: TextStyle(color: Colors.white54),
                      ),
                    ),
                  ],
                ),
          ],
        ),
      ),
    );
  }
}