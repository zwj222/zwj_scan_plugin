import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:zwj_scan_plugin/zwj_scan_plugin.dart';

import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ZwjScanPlugin scanKit;

  String code = "";

  @override
  void initState() {
    super.initState();

    scanKit = ZwjScanPlugin();
    scanKit.addResultListen((val) {
      debugPrint("scanning result:$val");
      setState(() {
        code = val ?? "";
      });
    });

    //请求权限
    requestPermission();
  }

  //请求相机 相册权限
  void requestPermission() async {
    // You can request multiple permissions at once.
    Map<Permission, PermissionStatus> statuses = await [
      Permission.camera,
      Permission.storage
    ].request();
    print(statuses[Permission.location]);
  }

  @override
  void dispose() {
    scanKit.dispose();
    super.dispose();
  }

  Future<void> startScan() async {
    try {
      await scanKit.startScan(scanTypes: [ScanTypes.ALL]);
    } on PlatformException {

    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('ZWJScanPlugin example app'),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(code),
              SizedBox(height: 32,),
              ElevatedButton(
                child: Text("Scan code"),
                onPressed: () {
                  startScan();
                },
              )
            ],
          ),
        ),
      ),
    );
  }
}
