import 'package:flutter/cupertino.dart';

class NetworkModal {
  static void showNetworkDialog(BuildContext context) {
    if (context == null) {
      debugPrint('Network dialog context is null');
      return;
    }

    showCupertinoDialog(
      context: context!,
      barrierDismissible: false,
      builder: (ctx) {
        return CupertinoAlertDialog(
          title: const Text("No Internet"),
          content: Column(
            children: const [
              SizedBox(height: 10),
              Text("Please check your internet connection."),
            ],
          ),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () {
                Navigator.of(ctx).pop();
              },
              child: const Text("Okay"),
            ),
          ],
        );
      },
    );
  }
}
