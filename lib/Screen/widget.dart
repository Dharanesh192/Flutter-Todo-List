import 'package:flutter/material.dart';
import 'package:to_do_list/main.dart'; // import scaffoldMessengerKey
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:to_do_list/repository/task_repository.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart'; // ← add at top of widget.dart

enum SnackbarType { success, warning, info, error}

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
      autofocus: true,
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
        showLocalSnackbar(
          context,
          message: 'Login failed. Try again later 😑',
          type: SnackbarType.error,
        );
      debugPrint("Error in login : $e");
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
        showLocalSnackbar(
          context,
          message: 'Logout failed. I itself don\'t know why 🤔',
          type: SnackbarType.error,
        );
      debugPrint("Error in logout : $e");
    } 
    finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> syncsignoutprocess() async {
    setState(() => _isLoading = true);
    try {
      await TaskRepository().pullTasksFromSupabase();
      await TaskRepository().syncPendingTasks();
      await TaskRepository().deleteusertask();
      await _supabase.auth.signOut();   

      Navigator.pop(context);
    }
    catch (e) {
        showLocalSnackbar(
          context,
          message: 'Mission failed: Something went wrong 🤫',
          type: SnackbarType.error,
        );
      debugPrint("Error in sync and logout : $e");
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
                          onPressed: syncsignoutprocess,
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
        showLocalSnackbar(
          context,
          message: 'Mission failed: Sync task failed 🫡',
          type: SnackbarType.error,
        );
      
      debugPrint("Error in sync and logout : $e");
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
            _isLoading ? const CircularProgressIndicator(color: Color(0xFF00FF00))
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

void showLocalSnackbar(
  BuildContext context, {
  required String message,
  required SnackbarType type,
  Duration duration = const Duration(seconds: 3),
}) {
  Color accent = const Color(0xFFFF4D4F);
  IconData icon = Icons.error_outline_rounded;

  switch (type) {
    case SnackbarType.success:
      accent = const Color(0xFF00FF38);
      icon = Icons.check_circle_outline_rounded;
      break;
    case SnackbarType.warning:
      accent = const Color(0xFFFFC107);
      icon = Icons.warning_amber_rounded;
      break;
    case SnackbarType.info:
      accent = const Color(0xFF3B82F6);
      icon = Icons.info_outline_rounded;
      break;
    case SnackbarType.error:
      accent = const Color(0xFFFF4D4F);
      icon = Icons.error_outline_rounded;
      break;
  }

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        duration: duration,
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        margin: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF22252B),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: accent, width: 1.3),
            boxShadow: [
              BoxShadow(
                color: accent.withOpacity(.25),
                blurRadius: 18,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(icon, color: accent, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

class LoadingDialog extends StatelessWidget {
  final String message;
  const LoadingDialog({required this.message, super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 220,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 22, 27, 34),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            // Spinkit hourglass animation
            const SpinKitPouringHourGlassRefined(
              color: Color(0xFF00FF00),
              size: 80.0,
            ),

            const SizedBox(height: 24),

            // Focus Hub title
            const Text(
              'Focus Hub',
              style: TextStyle(
                fontFamily: 'Teko',
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF00FF00),
              ),
            ),

            const SizedBox(height: 8),

            // Dynamic message passed in
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 14,
              ),
            ),

          ],
        ),
      ),
    );
  }
}