import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200, // Set the width of the button
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.cyan, // Set the background color
          padding: EdgeInsets.symmetric(
              vertical: 15.0, horizontal: 30.0), // Add padding
          shadowColor: Colors.black, // Set the shadow color
          elevation: 10, // Set the elevation to create a shadow
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30.0), // Set the border radius
          ),
        ),
        onPressed: onPressed,
        child: Text(
          text,
          style: TextStyle(
            fontSize: 20, // Font size
            fontWeight: FontWeight.bold, // Font weight
            color: Colors.white, // Font color
          ),
        ),
      ),
    );
  }
}
