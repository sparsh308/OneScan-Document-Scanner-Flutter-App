import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';

class explorer extends StatefulWidget {
  @override
  _explorerState createState() => _explorerState();
}

class _explorerState extends State<explorer> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
      leading: IconButton(
          icon: Icon(
            Icons.menu,
            color: Colors.black,
          ),
          onPressed: () {}),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: Icon(
            Icons.search,
            color: Colors.black,
          ),
        ),
      ],
      backgroundColor: Color(0xfffdfcfa),
      title: Text('File Explorer', style: TextStyle(color: Colors.black)),
    ));
  }
}
