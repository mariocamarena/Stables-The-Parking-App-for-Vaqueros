import 'package:flutter/material.dart';

// avatar notes for context of changing 
class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        const Padding(
          padding: EdgeInsets.all(16.0),
          child: CircleAvatar(
  radius: 50, 
  backgroundColor: Color(0xFFFF8200), 
  child: const Icon(
    Icons.account_circle, 
    size: 80, 
    color: Color.fromARGB(255, 255, 255, 255), 
  ),
)

        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Text('Student Name', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Text('student@utrgv.edu', style: TextStyle(fontSize: 18, color: Colors.grey)),
        ),

        // settings here
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
          child: Text('Settings', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ),
        ListTile(
          title: const Text('random'),
          onTap: () {
            
          },
        ),
        ListTile(
          title: const Text('random'),
          onTap: () {
            
          },
        ),
        ListTile(
          title: const Text('random'),
          onTap: () {
            
          },
        ),
        
        
        ListTile(
          title: const Text('random'),
          onTap: () {
            
          },
        ),
        ListTile(
          title: const Text('random'),
          onTap: () {
            
          },
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
          child: Text('App Version 1.0', style: TextStyle(fontSize: 16, color: Colors.grey)),
        ),
      ],
    );
  }
}
