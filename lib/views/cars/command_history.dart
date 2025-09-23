import 'package:atom/config/constants.dart';
import 'package:atom/widgets/cards/command_card.dart';
import 'package:atom/widgets/custom_header.dart';
import 'package:flutter/material.dart';

class CommandHistory extends StatefulWidget {
  const CommandHistory({super.key});

  @override
  State<CommandHistory> createState() => _CommandHistoryState();
}

class _CommandHistoryState extends State<CommandHistory> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgGrey,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: 10),
            customHeader(
              label: "Command History",
              icon: Icons.directions_car,
              showBackButton: true,
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            Expanded(
              child: ListView(
                children: [
                  CarInfoCard(
                    issuedBy: "Admin",
                    date: "2/3/25",
                    status: 'success',
                    command: "Lock Vehicle",
                  ),
                  CarInfoCard(
                    issuedBy: "Admin",
                    date: "2/3/25",
                    status: 'success',
                    command: "Restart Device",
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
