// @dart=2.9

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_file_manager/flutter_file_manager.dart';
import 'package:flutter_full_pdf_viewer/full_pdf_viewer_scaffold.dart';
import 'package:path_provider_ex/path_provider_ex.dart';
import 'package:share/share.dart';
//import package files

class FileEx extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MyPDFList() //call MyPDF List file
        ;
  }
}

//apply this class on home: attribute at MaterialApp()
class MyPDFList extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _MyPDFList(); //create state
  }
}

class _MyPDFList extends State<MyPDFList> {
  var files;

  void getFiles() async {
    //asyn function to get list of files
    List<StorageInfo> storageInfo = await PathProviderEx.getStorageInfo();
    var root = storageInfo[0]
        .rootDir; //storageInfo[1] for SD card, geting the root directory
    var fm = FileManager(
        root: Directory(
            "/storage/emulated/0/Android/data/com.example.scanbot_onescan_flutter/files/my-custom-storage/sbsdk-plugin-storage/")); //
    files = await fm.filesTree(
        excludedPaths: ["/storage/emulated/0/Android/"],
        sortedBy: FileManagerSorting.Alpha,
        extensions: ["pdf"] //optional, to filter files, list only pdf files
        );
    setState(() {}); //update the UI
  }

  @override
  void initState() {
    getFiles(); //call getFiles() function on initial state.
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            title: Text("PDF File list from SD Card"),
            backgroundColor: Colors.blueAccent),
        body: files == null
            ? Text("Searching Files")
            : ListView.builder(
                //if file/folder list is grabbed, then show here
                itemCount: files?.length ?? 0,
                itemBuilder: (context, index) {
                  return Card(
                      child: ListTile(
                    title: Text(files[index].path.split('/').last),
                    leading: Icon(Icons.picture_as_pdf),
                    trailing: Icon(
                      Icons.arrow_forward,
                      color: Colors.blueAccent,
                    ),
                    onTap: () {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (context) {
                        return ViewPDF(pathPDF: files[index].path.toString());
                        //open viewPDF page on click
                      }));
                    },
                  ));
                },
              ));
  }
}

class ViewPDF extends StatelessWidget {
  String pathPDF = "";
  ViewPDF({this.pathPDF});

  @override
  Widget build(BuildContext context) {
    return PDFViewerScaffold(
        //view PDF
        appBar: AppBar(
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: InkWell(
                onTap: () {
                  Share.shareFiles([pathPDF.toString()]);
                },
                child: Icon(
                  Icons.share,
                  color: Colors.white,
                ),
              ),
            ),
          ],
          title: Text("Document Viewer"),
          backgroundColor: Colors.blueAccent,
        ),
        path: pathPDF);
  }
}
