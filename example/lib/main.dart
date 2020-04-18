// Copyright (c) 2020
// Author: Hugo Pointcheval
import 'dart:developer';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:native_crypto/symmetric_crypto.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final textController = TextEditingController();
  String _output = 'none';
  String _bench;

  AES aes = AES();
  List<Uint8List> encryptedPayload;
  Uint8List decryptedPayload;

  void _generateKey() async {
    // You can also generate key before creating aes object.
    // Uint8List aeskey = await KeyGenerator().secretKey(keySize: KeySize.bits256);
    // AES aes = AES(key: aeskey);
    await aes.init(KeySize.bits256);
    setState(() {
      _output = 'Key generated. Length: ${aes.key.length}';
    });
  }

  void _encrypt() async {
    final plainText = textController.text.trim();

    var output;
    if (plainText.isEmpty) {
      output = 'Entry is empty';
    } else {
      var stringToBytes = TypeHelper().stringToBytes(plainText);
      // You can also pass a specific key.
      // encryptedPayload = await AES().encrypt(stringToBytes, key: aeskey);
      encryptedPayload = await aes.encrypt(stringToBytes);
      output = 'String successfully encrypted.';
    }
    setState(() {
      _output = output;
    });
  }

  void _decrypt() async {
    var output;
    if (encryptedPayload == null || encryptedPayload[0].isEmpty) {
      output = 'Encrypt before decrypting!';
    } else {
      // You can also pass a specific key.
      // decryptedPayload = await AES().decrypt(encryptedPayload, key: aeskey);
      decryptedPayload = await aes.decrypt(encryptedPayload);
      var bytesToString = TypeHelper().bytesToString(decryptedPayload);
      output = 'String successfully decrypted:\n\n$bytesToString';
    }
    setState(() {
      _output = output;
    });
  }

  Future<String> _benchmark(int megabytes) async {
    String output;
    var bigFile = Uint8List(megabytes * 1000000);

    var before = DateTime.now();
    var encryptedBigFile = await aes.encrypt(bigFile);
    var after = DateTime.now();

    var benchmark =
        after.millisecondsSinceEpoch - before.millisecondsSinceEpoch;

    output = '$megabytes MB\nAES Encryption: $benchmark ms\n';

    before = DateTime.now();
    await aes.decrypt(encryptedBigFile);
    after = DateTime.now();

    benchmark = after.millisecondsSinceEpoch - before.millisecondsSinceEpoch;

    output += 'AES Decryption: $benchmark ms\n\n';

    return output;
  }

  void _testPerf({int megabytes}) async {
    var output = '';
    if (megabytes != null) {
      output = await _benchmark(megabytes);
      setState(() {
      _output = output;
    });
    } else {
      setState(() {
        _bench = 'Open the logcat!';
      });
      for (int i=1;i<=50;i+=10) {
        var benchmark = await _benchmark(i);
        log(benchmark, name: 'fr.pointcheval.native_crypto');
      }
    }
    
  }

  @override
  void initState() {
    // Generate AES instance on init.
    _generateKey();
    super.initState();
  }

  void dispose() {
    // Clean up the controller when the widget is disposed.
    textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          centerTitle: true,
          title: const Text('Native Crypto'),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 10, 20),
            child: Center(
              child: Column(
                children: <Widget>[
                  TextField(
                    controller: textController,
                    decoration: InputDecoration(
                      hintText: 'Text to encrypt.',
                    ),
                  ),
                  SizedBox(height: 20),
                  FlatButton(
                      onPressed: _encrypt,
                      color: Colors.blue,
                      child: Text(
                        'Encrypt String',
                        style: TextStyle(color: Colors.white),
                      )),
                  FlatButton(
                      onPressed: _decrypt,
                      color: Colors.blue,
                      child: Text(
                        'Decrypt String',
                        style: TextStyle(color: Colors.white),
                      )),
                  SizedBox(height: 20),
                  // Output
                  Text(
                    _output,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 20),
                  FlatButton(
                      onPressed: () {
                        _testPerf(megabytes: 1);
                      },
                      color: Colors.blue,
                      child: Text(
                        'Benchmark 1 MB',
                        style: TextStyle(color: Colors.white),
                      )),
                  FlatButton(
                      onPressed: () {
                        _testPerf(megabytes: 10);
                      },
                      color: Colors.blue,
                      child: Text(
                        'Benchmark 10 MB',
                        style: TextStyle(color: Colors.white),
                      )),
                  FlatButton(
                      onPressed: () {
                        _testPerf(megabytes: 50);
                      },
                      color: Colors.blue,
                      child: Text(
                        'Benchmark 50 MB',
                        style: TextStyle(color: Colors.white),
                      )),
                  SizedBox(height: 20),
                  FlatButton(
                      onPressed: () {
                        _testPerf();
                      },
                      color: Colors.blue,
                      child: Text(
                        'Full benchmark',
                        style: TextStyle(color: Colors.white),
                      )),

                  (_bench != null && _bench.isNotEmpty)
                      ? Text(_bench)
                      : Container(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Contains some useful functions.
class TypeHelper {
  /// Returns bytes `Uint8List` from a `String`.
  Uint8List stringToBytes(String source) {
    var list = source.runes.toList();
    var bytes = Uint8List.fromList(list);
    return bytes;
  }

  /// Returns a `String` from bytes `Uint8List`.
  String bytesToString(Uint8List bytes) {
    var string = String.fromCharCodes(bytes);
    return string;
  }
}
