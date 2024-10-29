import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ramble/signup.dart';
import 'package:ramble/login.dart';
import 'package:ramble/homepage.dart';

Future<void> main() async {
  // Preserving the SplashScreen even after Flutter has initialized to check if use has logged in.
  WidgetsBinding bindings = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: bindings);

  // Obtain shared preferences.
  final SharedPreferences prefs = await SharedPreferences.getInstance();

  bool? isLoggedIn = prefs.getBool('isLoggedIn');
  bool Loggedinstate = isLoggedIn ?? false;

  FlutterNativeSplash.remove();
  runApp(MyApp(isLoggedIn: Loggedinstate));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  const MyApp({required this.isLoggedIn, super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a purple toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        // colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: isLoggedIn ? const HomePage() : const LandingPage(),
    );
  }
}

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Color.fromRGBO(62, 110, 162, 1),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
                padding: EdgeInsets.fromLTRB(51, 60, 51, 0),
                child: Container(
                    alignment: Alignment.center,
                    constraints: BoxConstraints(minWidth: 300, minHeight: 100),
                    child: Text('Ramble',
                        style: GoogleFonts.yaldevi(
                          textStyle: const TextStyle(
                            fontSize: 64,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        )))),
            Padding(
                padding: EdgeInsets.fromLTRB(51, 96, 51, 0),
                child: Image.asset(
                  'assets/images/social_asset.png',
                  fit: BoxFit.contain,
                  height: 200,
                  width: 300,
                )),
            Padding(
              padding: EdgeInsets.fromLTRB(51, 97, 51, 0),
              child: Column(
                children: [
                  ElevatedButton(
                      onPressed: () => Navigator.pushReplacement(context,
                          MaterialPageRoute(builder: (context) => SignUp())),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color.fromRGBO(0, 174, 240, 1),
                        minimumSize: Size(150, 45),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                      ),
                      child: Text(
                        'Signup',
                        style: GoogleFonts.yaldevi(
                            textStyle: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        )),
                      )),
                  Padding(padding: EdgeInsets.only(top: 32)),
                  ElevatedButton(
                      onPressed: () {
                        Navigator.pushReplacement(context,
                            MaterialPageRoute(builder: (context) => Login()));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color.fromRGBO(0, 174, 240, 1),
                        minimumSize: Size(150, 45),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                      ),
                      child: Text(
                        'Login',
                        style: GoogleFonts.yaldevi(
                            textStyle: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        )),
                      )),
                ],
              ),
            )
          ],
        ));
  }
}


