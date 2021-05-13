import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:scanbot_sdk/barcode_scanning_data.dart';
import 'package:scanbot_sdk/common_data.dart';
import 'package:scanbot_sdk/document_scan_data.dart';
import 'package:scanbot_sdk/ehic_scanning_data.dart';
import 'package:scanbot_sdk/mrz_scanning_data.dart';
import 'package:scanbot_sdk/scanbot_sdk.dart';
import 'package:scanbot_sdk/scanbot_sdk_models.dart';
import 'package:scanbot_sdk/scanbot_sdk_ui.dart';
import 'package:scanbot_sdk_example_flutter/fileexplorer.dart';
import 'package:scanbot_sdk_example_flutter/ui/barcode_preview.dart';
import 'package:scanbot_sdk_example_flutter/ui/preview_document_widget.dart';
import 'package:scanbot_sdk_example_flutter/ui/progress_dialog.dart';

import 'pages_repository.dart';
import 'ui/menu_items.dart';
import 'ui/utils.dart';

/// true - if you need to enable encryption for example app
bool shouldInitWithEncryption = false;

void main() => runApp(MyApp());

// TODO add the Scanbot SDK license key here.
// Please note: The Scanbot SDK will run without a license key for one minute per session!
// After the trial period is over all Scanbot SDK functions as well as the UI components will stop working
// or may be terminated. You can get an unrestricted "no-strings-attached" 30 day trial license key for free.
// Please submit the trial license form (https://scanbot.io/en/sdk/demo/trial) on our website by using
// the app identifier "io.scanbot.example.sdk.flutter" of this example app or of your app.
const SCANBOT_SDK_LICENSE_KEY = "T+/Le6fMmd55Fv+wqrmuVziU6bHDIj" +
    "Qa4VBIpWNhkLpVdNdK9WOVV9W1TvvL" +
    "LuJ6aSEcwJwpNcU/urvG8V2YDvxMGG" +
    "wltG9MrqFeidMQOWqfL4eAfoooie0x" +
    "qU1CpnROvqnF9lhE1OnCa/+Lfz8P3R" +
    "lwliY/LIs1jG5PP8hlTt9gkrAlJe7C" +
    "jCP1upED9d397oGpNdkO+GFkn7Vkfm" +
    "VwBtqx6WSAksSkTzilP3Dlxh0HDXqS" +
    "ApfG8DE1DvGUS2Hrkt9ZaB2V6dKSbA" +
    "ZAVNZG1bGD5bV2g6w7WB6zyZHaj7ki" +
    "xu2fA0ZxD/wMaTEQr0sxVmHlWkztL9" +
    "cXRhRwrhRPBw==\nU2NhbmJvdFNESw" +
    "pjb20uZXhhbXBsZS5zY2FuYm90X29u" +
    "ZXNjYW5fZmx1dHRlcgoxNjIzMTEwMz" +
    "k5CjU5MAoz\n";

Future<void> _initScanbotSdk() async {
  // Consider adjusting this optional storageBaseDirectory - see the comments below.
  final customStorageBaseDirectory = await getDemoStorageBaseDirectory();

  final encryptionParams = _getEncryptionParams();

  var config = ScanbotSdkConfig(
      loggingEnabled: true,
      // Consider switching logging OFF in production builds for security and performance reasons.
      licenseKey: SCANBOT_SDK_LICENSE_KEY,
      imageFormat: ImageFormat.JPG,
      imageQuality: 80,
      storageBaseDirectory: customStorageBaseDirectory,
      documentDetectorMode: DocumentDetectorMode.ML_BASED,
      encryptionParameters: encryptionParams);
  try {
    await ScanbotSdk.initScanbotSdk(config);
    await PageRepository().loadPages();
  } catch (e) {
    Logger.root.severe(e);
  }
}

EncryptionParameters? _getEncryptionParams() {
  EncryptionParameters? encryptionParams;
  if (shouldInitWithEncryption) {
    encryptionParams = EncryptionParameters(
      password: 'SomeSecretPa\$\$w0rdForFileEncryption',
      mode: FileEncryptionMode.AES256,
    );
  }
  return encryptionParams;
}

Future<String> getDemoStorageBaseDirectory() async {
  // !! Please note !!
  // It is strongly recommended to use the default (secure) storage location of the Scanbot SDK.
  // However, for demo purposes we overwrite the "storageBaseDirectory" of the Scanbot SDK by a custom storage directory.
  //
  // On Android we use the "ExternalStorageDirectory" which is a public(!) folder.
  // All image files and export files (PDF, TIFF, etc) created by the Scanbot SDK in this demo app will be stored
  // in this public storage directory and will be accessible for every(!) app having external storage permissions!
  // Again, this is only for demo purposes, which allows us to easily fetch and check the generated files
  // via Android "adb" CLI tools, Android File Transfer app, Android Studio, etc.
  //
  // On iOS we use the "ApplicationDocumentsDirectory" which is accessible via iTunes file sharing.
  //
  // For more details about the storage system of the Scanbot SDK Flutter Plugin please see our docs:
  // - https://scanbotsdk.github.io/documentation/flutter/
  //
  // For more details about the file system on Android and iOS we also recommend to check out:
  // - https://developer.android.com/guide/topics/data/data-storage
  // - https://developer.apple.com/library/archive/documentation/FileManagement/Conceptual/FileSystemProgrammingGuide/FileSystemOverview/FileSystemOverview.html

  Directory storageDirectory;
  if (Platform.isAndroid) {
    storageDirectory = (await getExternalStorageDirectory())!;
  } else if (Platform.isIOS) {
    storageDirectory = await getApplicationDocumentsDirectory();
  } else {
    throw ('Unsupported platform');
  }

  return '${storageDirectory.path}/my-custom-storage';
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() {
    _initScanbotSdk();
    return _MyAppState();
  }
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: new ThemeData(canvasColor: Colors.white),
      home: MainPageWidget(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainPageWidget extends StatefulWidget {
  @override
  _MainPageWidgetState createState() => _MainPageWidgetState();
}

class _MainPageWidgetState extends State<MainPageWidget> {
  final PageRepository _pageRepository = PageRepository();

  @override
  void initState() {
    super.initState();
    // add some custom init code here
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        // Add a ListView to the drawer. This ensures the user can scroll
        // through the options in the drawer if there isn't enough vertical
        // space to fit everything.
        child: ListView(
          // Important: Remove any padding from the ListView.
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              child: Column(
                children: [
                  Text(
                    "OneScan",
                    style:
                        GoogleFonts.pacifico(color: Colors.black, fontSize: 20),
                  ),
                  Container(
                    height: 102,
                    child: Image.asset(
                      'assets/images/pic.png',
                    ),
                  ),
                ],
              ),
              decoration: BoxDecoration(color: Colors.white),
            ),
            ListTile(
              title: Text(
                'Open Recent Created PDFs',
                style:
                    TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              ),
              onTap: () {
                Navigator.pop(context);

                Navigator.push(
                    context, MaterialPageRoute(builder: (context) => FileEx()));
                // ...
              },
            ),
            ListTile(
              title: Text(
                'About App',
                style:
                    TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              ),
              onTap: () {
                Navigator.pop(context);
                showDialog(
                    context: (context),
                    builder: (context) {
                      return AlertDialog(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                        content: Container(
                          width: MediaQuery.of(context).size.width,
                          height: 140,
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  FittedBox(
                                    fit: BoxFit.fitWidth,
                                    child: Text(
                                      "One",
                                      style: GoogleFonts.pacifico(
                                          color: Colors.black, fontSize: 25),
                                    ),
                                  ),
                                  FittedBox(
                                    fit: BoxFit.fitWidth,
                                    child: Text(
                                      "Scan",
                                      style: GoogleFonts.pacifico(
                                          color: Colors.black, fontSize: 25),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(
                                height: 8,
                              ),
                              FittedBox(
                                fit: BoxFit.fitWidth,
                                child: Text(
                                  'Version 1.0',
                                ),
                              ),
                              SizedBox(
                                height: 8,
                              ),
                              FittedBox(
                                fit: BoxFit.fitWidth,
                                child: Text(
                                  'All In One Document Scanner',
                                  style: TextStyle(
                                      fontFamily: 'Montserrat',
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Theme.of(context).accentColor),
                                ),
                              ),
                              SizedBox(
                                height: 8,
                              ),
                              FittedBox(
                                fit: BoxFit.fitWidth,
                                child: Text(
                                  "Developed on Flutter",
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    });

                // ...
              },
            ),
          ],
        ),
      ),
      appBar: AppBar(
        iconTheme: IconThemeData(color: Colors.black),
        elevation: 0.0,
        actions: [],
        backgroundColor: Colors.white,
        title: Text(
          'OneScan',
          style: GoogleFonts.pacifico(color: Colors.black, fontSize: 30),
        ),
      ),
      body: Container(
        color: Colors.white,
        child: Container(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 15.0),
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      InkWell(
                        onTap: () {
                          _startDocumentScanning();
                        },
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Container(
                                child: Image.asset(
                                  'assets/images/scan.gif',
                                ),
                                decoration: BoxDecoration(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(20)),
                                ),
                                width: 90,
                                height: 90,
                              ),
                            ),
                            Text(
                              "Scan",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            )
                          ],
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          _startQRScanner();
                        },
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Container(
                                child: Image.asset(
                                  'assets/images/qr.gif',
                                ),
                                decoration: BoxDecoration(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(20)),
                                ),
                                width: 90,
                                height: 90,
                              ),
                            ),
                            Text(
                              "QR Scan ",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            )
                          ],
                        ),
                      ),
                    ]),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    InkWell(
                      onTap: () {
                        showModalBottomSheet<void>(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25.0),
                          ),
                          context: context,
                          builder: (BuildContext context) {
                            return Container(
                              decoration: BoxDecoration(
                                color: Color(0xfffdfcfa),
                                borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(25.0),
                                    topRight: const Radius.circular(25.0)),
                              ),
                              height: 200,
                              child: ListView(
                                children: [
                                  MenuItemWidget(
                                    "Single Barcode Scan",
                                    endIcon: Icons.arrow_forward,
                                    onTap: () {
                                      _startBarcodeScanner();
                                    },
                                  ),
                                  MenuItemWidget(
                                    "Batch Barcode Scan",
                                    endIcon: Icons.arrow_forward,
                                    onTap: () {
                                      _startBatchBarcodeScanner();
                                    },
                                  ),
                                  MenuItemWidget(
                                    " Detect Barcode On Image",
                                    endIcon: Icons.arrow_forward,
                                    onTap: () {
                                      _detectBarcodeOnImage();
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Container(
                              child: Image.asset(
                                'assets/images/tenor.gif',
                              ),
                              decoration: BoxDecoration(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(20)),
                              ),
                              width: 90,
                              height: 90,
                            ),
                          ),
                          Text(
                            "Barcode",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          )
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        _importImage();
                      },
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Container(
                              child: Image.asset(
                                'assets/images/gallery.gif',
                              ),
                              decoration: BoxDecoration(
                                borderRadius:
                                    BorderRadius.all(Radius.circular(20)),
                              ),
                              width: 90,
                              height: 90,
                            ),
                          ),
                          Text(
                            "Import Image",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 20.0),
                      child: InkWell(
                        onTap: () {
                          _gotoImagesView();
                        },
                        child: Container(
                          child: Image.asset(
                            'assets/images/doc.gif',
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(25),
                            color: Colors.white70,
                          ),
                          height: 90,
                          width: MediaQuery.of(context).size.width,
                        ),
                      ),
                    ),
                  ),
                  Text(
                    "View Image Results",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Container(
                    height: 200,
                    child: Image.asset(
                      'assets/images/pic.png',
                    ),
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _getOcrConfigs() async {
    try {
      final result = await ScanbotSdk.getOcrConfigs();
      await showAlertDialog(context, jsonEncode(result), title: 'OCR Configs');
    } catch (e) {
      Logger.root.severe(e);
      await showAlertDialog(context, 'Error getting license status');
    }
  }

  Future<void> _getLicenseStatus() async {
    try {
      final result = await ScanbotSdk.getLicenseStatus();
      await showAlertDialog(context, jsonEncode(result),
          title: 'License Status');
    } catch (e) {
      Logger.root.severe(e);
      await showAlertDialog(context, 'Error getting OCR configs');
    }
  }

  Future<void> _importImage() async {
    try {
      final image = await ImagePicker().getImage(source: ImageSource.gallery);
      await _createPage(Uri.file(image?.path ?? ''));
      await _gotoImagesView();
    } catch (e) {
      Logger.root.severe(e);
    }
  }

  Future<void> _createPage(Uri uri) async {
    if (!await checkLicenseStatus(context)) {
      return;
    }

    final dialog = ProgressDialog(context,
        type: ProgressDialogType.Normal, isDismissible: false);
    dialog.style(message: 'Processing');
    dialog.show();
    try {
      var page = await ScanbotSdk.createPage(uri, false);
      page = await ScanbotSdk.detectDocument(page);
      await _pageRepository.addPage(page);
    } catch (e) {
      Logger.root.severe(e);
    } finally {
      await dialog.hide();
    }
  }

  Future<void> _startDocumentScanning() async {
    if (!await checkLicenseStatus(context)) {
      return;
    }

    DocumentScanningResult? result;
    try {
      var config = DocumentScannerConfiguration(
        bottomBarBackgroundColor: Colors.blue,
        ignoreBadAspectRatio: true,
        multiPageEnabled: true,
        //maxNumberOfPages: 3,
        //flashEnabled: true,
        //autoSnappingSensitivity: 0.7,
        cameraPreviewMode: CameraPreviewMode.FIT_IN,
        orientationLockMode: CameraOrientationMode.PORTRAIT,
        //documentImageSizeLimit: Size(2000, 3000),
        cancelButtonTitle: 'Cancel',
        pageCounterButtonTitle: '%d Page(s)',
        textHintOK: "Perfect, don't move...",
        //textHintNothingDetected: "Nothing",
        // ...
      );
      result = await ScanbotSdkUi.startDocumentScanner(config);
    } catch (e) {
      Logger.root.severe(e);
    }
    if (result != null) {
      if (isOperationSuccessful(result)) {
        await _pageRepository.addPages(result.pages);
        await _gotoImagesView();
      }
    }
  }

  Future<void> _startBarcodeScanner() async {
    if (!await checkLicenseStatus(context)) {
      return;
    }

    try {
      var config = BarcodeScannerConfiguration(
        topBarBackgroundColor: Colors.blue,
        finderTextHint:
            'Please align any supported barcode in the frame to scan it.',
        // ...
      );
      var result = await ScanbotSdkUi.startBarcodeScanner(config);
      await _showBarcodeScanningResult(result);
    } catch (e) {
      Logger.root.severe(e);
    }
  }

  Future<void> _startBatchBarcodeScanner() async {
    if (!await checkLicenseStatus(context)) {
      return;
    }
    try {
      //var config = BarcodeScannerConfiguration(); // testing default configs
      var config = BatchBarcodeScannerConfiguration(
          barcodeFormatter: (item) async {
            final random = Random();
            final randomNumber = random.nextInt(4) + 2;
            await Future.delayed(Duration(seconds: randomNumber));
            return BarcodeFormattedData(
                title: item.barcodeFormat.toString(),
                subtitle: (item.text ?? '') + 'custom string');
          },
          topBarBackgroundColor: Colors.blueAccent,
          topBarButtonsColor: Colors.white70,
          cameraOverlayColor: Colors.black26,
          finderLineColor: Colors.red,
          finderTextHintColor: Colors.white,
          cancelButtonTitle: 'Cancel',
          enableCameraButtonTitle: 'camera enable',
          enableCameraExplanationText: 'explanation text',
          finderTextHint:
              'Please align any supported barcode in the frame to scan it.',
          // clearButtonTitle: "CCCClear",
          // submitButtonTitle: "Submitt",
          barcodesCountText: '%d codes',
          fetchingStateText: 'might be not needed',
          noBarcodesTitle: 'nothing to see here',
          barcodesCountTextColor: Colors.white,
          finderAspectRatio: FinderAspectRatio(width: 3, height: 2),
          topBarButtonsInactiveColor: Colors.white,
          detailsActionColor: Colors.white,
          detailsBackgroundColor: Colors.blueAccent,
          detailsPrimaryColor: Colors.white,
          finderLineWidth: 7,
          successBeepEnabled: true,
          // flashEnabled: true,
          orientationLockMode: CameraOrientationMode.PORTRAIT,
          barcodeFormats: PredefinedBarcodes.allBarcodeTypes(),
          cancelButtonHidden: false);

      final result = await ScanbotSdkUi.startBatchBarcodeScanner(config);
      if (result.operationResult == OperationResult.SUCCESS) {
        await Navigator.of(context).push(
          MaterialPageRoute(
              builder: (context) => BarcodesResultPreviewWidget(result)),
        );
      }
    } catch (e) {
      Logger.root.severe(e);
    }
  }

  Future<void> _detectBarcodeOnImage() async {
    if (!await checkLicenseStatus(context)) {
      return;
    }
    try {
      var image = await ImagePicker().getImage(source: ImageSource.gallery);

      ///before processing image sdk need storage read permission

      final permissions =
          await [Permission.storage, Permission.photos].request();
      if (permissions[Permission.storage] ==
              PermissionStatus.granted || //android
          permissions[Permission.photos] == PermissionStatus.granted) {
        //ios
        var result = await ScanbotSdk.detectBarcodeFromImageFile(
            Uri.file(image?.path ?? ''),
            PredefinedBarcodes.allBarcodeTypes(),
            true);
        if (result.operationResult == OperationResult.SUCCESS) {
          await Navigator.of(context).push(
            MaterialPageRoute(
                builder: (context) => BarcodesResultPreviewWidget(result)),
          );
        }
      }
    } catch (e) {
      Logger.root.severe(e);
    }
  }

  Future<void> estimateBlurriness() async {
    if (!await checkLicenseStatus(context)) {
      return;
    }
    try {
      var image = await ImagePicker().getImage(source: ImageSource.gallery);

      ///before processing an image the SDK need storage read permission

      var permissions = await [Permission.storage, Permission.photos].request();
      if (permissions[Permission.storage] ==
              PermissionStatus.granted || //android
          permissions[Permission.photos] == PermissionStatus.granted) {
        //ios
        var page =
            await ScanbotSdk.createPage(Uri.file(image?.path ?? ''), true);
        var result = await ScanbotSdk.estimateBlurOnPage(page);
        // set up the button
        showResultTextDialog('Blur value is :${result.toStringAsFixed(2)} ');
      }
    } catch (e) {
      Logger.root.severe(e);
    }
  }

  void showResultTextDialog(result) {
    Widget okButton = TextButton(
      onPressed: () => Navigator.pop(context),
      child: Text('OK'),
    );
    // set up the AlertDialog
    var alert = AlertDialog(
      title: Text('Result'),
      content: Text(result),
      actions: [
        okButton,
      ],
    );

    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  Future<void> _startQRScanner() async {
    if (!await checkLicenseStatus(context)) {
      return;
    }

    try {
      final config = BarcodeScannerConfiguration(
        barcodeFormats: [BarcodeFormat.QR_CODE],
        finderTextHint: 'Please align a QR code in the frame to scan it.',
        // ...
      );
      final result = await ScanbotSdkUi.startBarcodeScanner(config);
      await _showBarcodeScanningResult(result);
    } catch (e) {
      Logger.root.severe(e);
    }
  }

  Future<void> _showBarcodeScanningResult(
      final BarcodeScanningResult result) async {
    if (result.operationResult == OperationResult.SUCCESS) {
      await Navigator.of(context).push(
        MaterialPageRoute(
            builder: (context) => BarcodesResultPreviewWidget(result)),
      );
    }
  }

  Future<void> _startEhicScanner() async {
    if (!await checkLicenseStatus(context)) {
      return;
    }

    HealthInsuranceCardRecognitionResult? result;
    try {
      final config = HealthInsuranceScannerConfiguration(
        topBarBackgroundColor: Colors.blue,
        topBarButtonsColor: Colors.white70,
        // ...
      );
      result = await ScanbotSdkUi.startEhicScanner(config);
    } catch (e) {
      Logger.root.severe(e);
    }
    if (result != null) {
      if (isOperationSuccessful(result)) {
        var concatenate = StringBuffer();
        result.fields
            .map((field) =>
                "${field.type.toString().replaceAll("HealthInsuranceCardFieldType.", "")}:${field.value}\n")
            .forEach((s) {
          concatenate.write(s);
        });
        await showAlertDialog(context, concatenate.toString());
      }
    }
  }

  Future<void> _startMRZScanner() async {
    if (!await checkLicenseStatus(context)) {
      return;
    }

    MrzScanningResult? result;
    try {
      final config = MrzScannerConfiguration(
        topBarBackgroundColor: Colors.blue,
      );
      if (Platform.isIOS) {
        config.finderAspectRatio = FinderAspectRatio(width: 3, height: 1);
      }
      result = await ScanbotSdkUi.startMrzScanner(config);
    } catch (e) {
      Logger.root.severe(e);
    }

    if (result != null && isOperationSuccessful(result)) {
      final concatenate = StringBuffer();
      result.fields
          .map((field) =>
              "${field.name.toString().replaceAll("MRZFieldName.", "")}:${field.value}\n")
          .forEach((s) {
        concatenate.write(s);
      });
      await showAlertDialog(context, concatenate.toString());
    }
  }

  Future<dynamic> _gotoImagesView() async {
    imageCache?.clear();
    return await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => DocumentPreview()),
    );
  }
}
