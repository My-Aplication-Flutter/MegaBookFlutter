import 'package:flutter/material.dart';
import 'menu.dart';

class MyHomePage extends StatelessWidget {
  final String title;
  const MyHomePage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      drawer: const SideMenu(),
      body: const Center(
        child: Text('Hello, World!'),
      ),
    );
  }
}
