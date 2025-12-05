import 'package:dominoes/constants.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home Screen'),
        actions: [
          IconButton(
            onPressed: () => context.pushNamed(AppRoutes.settings),
            icon: Icon(Icons.settings),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: Container(color: Colors.red)),
          Expanded(
            flex: 2,
            child: Container(
              color: Colors.blue,
              child: GridView.custom(
                gridDelegate: gridDelegate,
                childrenDelegate: childrenDelegate,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
