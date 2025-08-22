import 'package:flutter/material.dart';

class CustomBorderButton extends StatefulWidget {
  CustomBorderButton({
    required this.callBackFunction,
    required this.label,
    required this.borderColor,
    required this.txtColor,
  });

  final VoidCallback callBackFunction;
  final String label;
  final Color borderColor;
  final Color txtColor;

  @override
  _CustomBorderButtonState createState() => _CustomBorderButtonState();
}

class _CustomBorderButtonState extends State<CustomBorderButton> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: widget.borderColor, width: 1.5),
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