import 'dart:async';

import 'package:connectivity/connectivity.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:track/map_view.dart';
import 'package:share/share.dart';
import 'package:track/profile_page.dart';


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
final DatabaseRef= FirebaseDatabase.instance.ref('users');

String? userName = FirebaseAuth.instance.currentUser?.displayName;
String? userEmail = FirebaseAuth.instance.currentUser?.email;
String? pictureUrl = FirebaseAuth.instance.currentUser?.photoURL;

String greetingMessage = '';
late Timer _timer;
Timer? trackingInterval;

int currentIndex = 0;

final List<Widget> _screens=[
  const MapView(),
  const MapView(),
  const MapView(),
  const ProfilePage(),
 
];

  @override
  void initState() {
    super.initState();

    // Set the initial greeting
    _updateGreetingMessage();

    // Start a timer to update the greeting message every minute
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _updateGreetingMessage();
    });

    extractFirstName();
  }

  @override
  void dispose() {
    // Cancel the timer when the widget is disposed
    _timer.cancel();
    super.dispose();
  }

  void _updateGreetingMessage() {
    final currentTime = DateTime.now();
    final hour = currentTime.hour;

  setState(() {
      if (hour >= 5 && hour < 12) {
        greetingMessage = 'Good Morning';
      } else if (hour >= 12 && hour < 17) {
        greetingMessage = 'Good Afternoon';
      } else if (hour >= 17 && hour < 20) {
        greetingMessage = 'Good Evening';
      } else {
        greetingMessage = 'Good Night';
      }
    });
  }

 String? firstName;

void extractFirstName() {
    // Extract the first name
    if (userName != null) {
      List<String> nameParts = userName!.split(' ');
      if (nameParts.isNotEmpty) {
        firstName = nameParts[0];
      }
    }
  }


  @override
  Widget build(BuildContext context) {

    extractFirstName();
    
    return MaterialApp(      
      home: DefaultTabController(
        length: 3,
        child: Scaffold(

          drawer: Drawer(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
                  decoration: const BoxDecoration(
                    color: Colors.indigo,
                  ),
                  child:SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundImage: pictureUrl != null
                            ? NetworkImage(pictureUrl!) as ImageProvider<Object>?
                            : const AssetImage('assets/images/girl_avatar.png'),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '$userName',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                        ),
                      ),
                      Text(
                        '$userEmail',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.settings),
                  title: const Text('Settings'),
                  onTap: () {
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.exit_to_app),
                  title: const Text('Logout'),
                  onTap: () {
                    // Show a confirmation dialog
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('Confirm Logout'),
                          content: const Text('Are you sure you want to logout?'),
                          actions: <Widget>[
                            TextButton(
                              onPressed: () {
                                Navigator.pop(context); // Close the dialog
                              },
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () async {
                                // User confirmed, proceed with logout
                                Navigator.pop(context); // Close the dialog
                                await FirebaseAuth.instance.signOut();
                                    await _saveUserLoggedIn(false);
                                // After signing out, navigate to the login or authentication screen.
                                // You can replace '/signin' with the screen you want to navigate to.
                                Navigator.pushReplacementNamed(context, '/signin');
                              },
                              child: const Text('Logout'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
                 ListTile(
                  leading: const Icon(Icons.share, color: Colors.green,),
                  title: const Text('Share'),
                  titleTextStyle: const TextStyle(color: Colors.green, fontSize: 15),
                  onTap: () {
                    // Implement share functionality here
                     const String message = 'Check out this awesome app! Locify';
                     const String subject = 'App Recommendation';

                    Share.share(message, subject: subject);
                  },
                )
              ],
            ),
          ),


          appBar: AppBar(
            toolbarHeight: 100,
            backgroundColor: Colors.indigo,
            title: Row(
              children: <Widget> [
                const Padding(padding: EdgeInsets.all(1.0)),
                  CircleAvatar(
                  radius: 35,
                  backgroundImage: pictureUrl != null
                      ? NetworkImage(pictureUrl!) as ImageProvider<Object>?
                      : const AssetImage('assets/images/girl_avatar.png'), // Placeholder image or null
                ), 
                const SizedBox(width: 20,),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Hii,',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                      ),
                    ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 500),
                      child: Column(
                        key: ValueKey<String>(greetingMessage),
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            ' $firstName,',
                            style: const TextStyle(
                              fontSize: 16.0,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            greetingMessage,
                            style: const TextStyle(
                              fontSize: 15.0,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    )
                  ],
                ),
                const SizedBox(width: 15,),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children:[
                      FutureBuilder<ConnectivityResult>(
                      future: Connectivity().checkConnectivity(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const CircularProgressIndicator(); // Show loading indicator if checking connectivity
                        } else {
                          bool isConnected = snapshot.data == ConnectivityResult.mobile ||
                              snapshot.data == ConnectivityResult.wifi;
                          return Icon(
                            isConnected ? Icons.wifi : Icons.signal_wifi_off,
                            color: isConnected ? Colors.green : Colors.red,
                            size: 30,
                          );
                        }
                      },
                    ),
                   // const Text('Internet'),
                  ]
                )
              ]              
            ),
            actions: <Widget>[
              IconButton(
                onPressed: (){

                }, 
                icon: const Icon(Icons.notification_add,color: Colors.white,)
                ),
                
            ],
          ),
        

        body: _screens[currentIndex],

        bottomNavigationBar: SafeArea(
        child:Container(
        height: 90,
        padding: const EdgeInsets.all(12.0),
        margin: const EdgeInsets.symmetric(horizontal: 9.0),
        
        child: ClipRRect(
        borderRadius: BorderRadius.circular(22.0),
        
        child:BottomNavigationBar(
          elevation: 10.0,
          selectedFontSize: 15,
          selectedIconTheme: const IconThemeData(color:Color.fromARGB(221, 233, 30, 98)) ,
          unselectedIconTheme: const IconThemeData(size:25),
          unselectedFontSize: 14,
          iconSize: 30,
          backgroundColor: const Color.fromARGB(22, 0, 0, 0),
          unselectedItemColor: Colors.white,
          selectedItemColor: const Color.fromARGB(255, 233, 30, 98),
          type: BottomNavigationBarType.fixed,
          currentIndex: currentIndex,
          onTap: (int index) {
            setState(() {
            currentIndex = index;
            });
          },
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home'
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.analytics),
              label: 'Analytics'
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.auto_graph),
              label: 'Graphs'
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'Settings'             
            )
          ],
          ),  
         ),
        ),
        ),

       ),  
     ),
    );
  }


}

  Future<void> _saveUserLoggedIn(bool value) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', value);
  }





