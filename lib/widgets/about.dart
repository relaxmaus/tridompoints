import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class About extends StatelessWidget {
  const About({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.tr('about.title')),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.blue.shade100, Colors.blue.shade400],
            ),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const CircleAvatar(
                    radius: 50,
                    backgroundImage: AssetImage('assets/icons/icon.png'),
                  ),
                  const SizedBox(height: 20),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.info_outline_rounded),
                      title: Text(
                        context.tr('about.description'),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Version: ${context.tr('version')}',
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    context.tr('about.author'),
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => Navigator.pop(context),
          child: const Icon(Icons.close),
        ),
      ),
    );
  }
}