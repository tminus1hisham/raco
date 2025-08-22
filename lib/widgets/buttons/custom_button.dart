import 'package:flutter/material.dart';

class CustomButton extends StatefulWidget {
  CustomButton({
    required this.callBackFunction,
    required this.label,
    required this.backgroundColor,
    required this.txtColor,
  });

  final VoidCallback callBackFunction;
  final String label;
  final Color backgroundColor;
  final Color txtColor;

  @override
  _CustomButtonState createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        borderRadius: BorderRadius.circular(15.0),
      ),
      child: ElevatedButton(
        onPressed: widget.callBackFunction,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15.0),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            widget.label,
            style: TextStyle(color: widget.txtColor, fontSize: 16),
          ),
        ),
      ),
    );
  }
}