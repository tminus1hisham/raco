import 'package:flutter/cupertino.dart';

class ActionDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmText;
  final String cancelText;
  final VoidCallback onConfirm;

  const ActionDialog({
    super.key,
    required this.title,
    required this.message,
    required this.onConfirm,
    this.confirmText = "Confirm",
    this.cancelText = "Cancel",
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      content: Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: Text(message),
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.pop(context),
          isDestructiveAction: false,
          child: Text(cancelText),
        ),
        CupertinoDialogAction(
          onPressed: () {
            Navigator.pop(context);
            onConfirm();
          },
          isDestructiveAction: true,
          child: Text(confirmText),
        ),
      ],
    );
  }
}
