import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:bcrypt/bcrypt.dart';
import 'package:flutter/material.dart';
import 'package:e_season/screens/password_screen.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final DatabaseReference _databaseReference =
      FirebaseDatabase.instance.ref();

  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return null; // The user canceled the sign-in
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user != null) {
        // Check if user already exists in database
        DatabaseEvent event = await _databaseReference
            .child('general_passenger')
            .orderByChild('email')
            .equalTo(user.email)
            .once();

        if (event.snapshot.value == null) {
          // User doesn't exist, create new entry
          await _databaseReference.child('general_passenger').push().set({
            'fullName': user.displayName ?? '',
            'email': user.email ?? '',
            'phone': user.phoneNumber ?? '',
            'createdAt': DateTime.now().toIso8601String(),
            'authProvider': 'google',
          });
        }
      }

      return user;
    } catch (e) {
      print('Error signing in with Google: $e');
      return null;
    }
  }

  Future<void> registerWithGoogle(BuildContext context) async {
    try {
      User? user = await signInWithGoogle();
      if (user != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PasswordScreen(
              userData: {
                'fullName': user.displayName ?? '',
                'email': user.email ?? '',
                'phone': user.phoneNumber ?? '',
              },
            ),
          ),
        );
      }
    } catch (e) {
      print('Error registering with Google: $e');
      throw e;
    }
  }

  Future<void> addPassenger({
    required String fullName,
    required String address,
    required String nic,
    required String email,
    required String phone,
    required String password,
    required BuildContext context,
  }) async {
    try {
      // Hash the password using bcrypt
      String hashedPassword = _hashPassword(password);

      // Store user data in the database
      await _databaseReference.child('general_passenger').push().set({
        'fullName': fullName,
        'address': address,
        'nic': nic,
        'email': email,
        'phone': phone,
        'password': hashedPassword, // Store the hashed password
        'createdAt': DateTime.now().toIso8601String(),
      });

      Navigator.pushReplacementNamed(context, '/dashboard');
    } catch (e) {
      print('Error adding passenger: $e');
      throw e;
    }
  }

  Future<bool> loginUser({
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    try {
      // Retrieve user data from the database
      DatabaseEvent event = await _databaseReference
          .child('general_passenger')
          .orderByChild('email')
          .equalTo(email)
          .once();

      DataSnapshot snapshot = event.snapshot;

      if (snapshot.value != null) {
        Map<dynamic, dynamic> userData =
            snapshot.value as Map<dynamic, dynamic>;
        bool isValidUser = false;
        userData.forEach((key, value) {
          if (BCrypt.checkpw(password, value['password'])) {
            isValidUser = true;
            Navigator.pushReplacementNamed(context, '/dashboard');
          }
        });
        if (!isValidUser) {
          throw Exception('Invalid password');
        }
        return true;
      } else {
        throw Exception('User not found');
      }
    } catch (e) {
      print('Error logging in: $e');
      throw e;
    }
  }

  String _hashPassword(String password) {
    return BCrypt.hashpw(password, BCrypt.gensalt());
  }

  Future<void> signOut(BuildContext context) async {
    await _auth.signOut();
    await _googleSignIn.signOut();
    Navigator.pushReplacementNamed(context, '/');
  }
}
