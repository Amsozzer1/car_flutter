import 'dart:convert';
import 'dart:ffi';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class AppPage extends StatefulWidget {
  final BluetoothDevice server;

  const AppPage({this.server});

  @override
  _AppPage createState() => new _AppPage();
}


class _AppPage extends State<AppPage> {
  BluetoothConnection connection;

  String _messageBuffer = '';
  String message = ": :";


  bool isConnecting = true;
  bool get isConnected => connection != null && connection.isConnected;

  bool isDisconnecting = false;

  @override
  void initState() {
    super.initState();

    BluetoothConnection.toAddress(widget.server.address).then((_connection) {
      print('Connected to the device');
      connection = _connection;
      setState(() {
        isConnecting = false;
        isDisconnecting = false;
      });

      connection.input.listen(_onDataReceived).onDone(() {
        // Example: Detect which side closed the connection
        // There should be `isDisconnecting` flag to show are we are (locally)
        // in middle of disconnecting process, should be set before calling
        // `dispose`, `finish` or `close`, which all causes to disconnect.
        // If we except the disconnection, `onDone` should be fired as result.
        // If we didn't except this (no flag set), it means closing by remote.
        if (isDisconnecting) {
          print('Disconnecting locally!');
        } else {
          print('Disconnected remotely!');
        }
        if (this.mounted) {
          setState(() {});
        }
      });
    }).catchError((error) {
      print('Cannot connect, exception occured');
      print(error);
    });
  }

  @override
  void dispose() {
    // Avoid memory leak (`setState` after dispose) and disconnect
    if (isConnected) {
      isDisconnecting = true;
      connection.dispose();
      connection = null;
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String speed = message.split(":")[0];
    String direction = message.split(":")[1];
    String distance = message.split(":")[2];
    final Text command = Text("Speed: " + speed.toString(),style: TextStyle(
      color: Color.fromRGBO(17, 35, 236, 0.6), fontSize: 25));
    final Text directionText = Text("Direction: " + direction.toString(),style: TextStyle(
      color: Color.fromRGBO(17, 35, 236, 0.6), fontSize: 25));
    final Text DistanceText = Text("Distance To object is "+distance.toString()+" cm",style: TextStyle(
      color: Color.fromRGBO(17, 35, 236, 0.6), fontSize: 25));

      
      return Scaffold(
      appBar: AppBar(
        title: Text("RC Car Controller"),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
      ),
      body: SafeArea(
        child: Container(
          padding: EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              command,
              SizedBox(height: 8),
              directionText,
              SizedBox(height: 8),
              DistanceText,
              SizedBox(height: 20),
              Center(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: <Widget>[
                        ElevatedButton.icon(
                          icon: Icon(Icons.arrow_back),
                          label: Text('Left'),
                          onPressed: () => _sendMessage("D"),
                          style: ElevatedButton.styleFrom(
                            primary: Colors.deepPurple,
                            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                          ),
                        ),
                        ElevatedButton(
                          child: Text('Stop'),
                          onPressed: () => _sendMessage("B"),
                          style: ElevatedButton.styleFrom(
                            primary: Colors.red,
                            padding: EdgeInsets.symmetric(horizontal: 25, vertical: 20),
                          ),
                        ),
                        ElevatedButton.icon(
                          icon: Icon(Icons.arrow_forward),
                          label: Text('Right'),
                          onPressed: () => _sendMessage("E"),
                          style: ElevatedButton.styleFrom(
                            primary: Colors.deepPurple,
                            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      child: Text('Forward'),
                      onPressed: () => _sendMessage("A"),
                      style: ElevatedButton.styleFrom(
                        primary: Colors.green,
                        padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                      ),
                    ),
                    SizedBox(height: 10),
                    ElevatedButton(
                      child: Text('Reverse'),
                      onPressed: () => _sendMessage("C"),
                      style: ElevatedButton.styleFrom(
                        primary: Colors.blue,
                        padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  void _onDataReceived(Uint8List data) {
    // Allocate buffer for parsed data
    int backspacesCounter = 0;
    data.forEach((byte) {
      if (byte == 8 || byte == 127) {
        backspacesCounter++;
      }
    });
    Uint8List buffer = Uint8List(data.length - backspacesCounter);
    int bufferIndex = buffer.length;

    // Apply backspace control character
    backspacesCounter = 0;
    for (int i = data.length - 1; i >= 0; i--) {
      if (data[i] == 8 || data[i] == 127) {
        backspacesCounter++;
      } else {
        if (backspacesCounter > 0) {
          backspacesCounter--;
        } else {
          buffer[--bufferIndex] = data[i];
        }
      }
    }
    
    // Create message if there is new line character
    String dataString = String.fromCharCodes(buffer);
    int index = buffer.indexOf(13);
    message  = dataString;
    //print(dataString);
    if (~index != 0) {
      setState(() {
        //message = buffer.toString();
        
        
        //print(message);
        // message = backspacesCounter > 0
        //         ? _messageBuffer.substring(
        //             0, _messageBuffer.length - backspacesCounter)
        //         : _messageBuffer + dataString.substring(0, index);
        
        _messageBuffer = dataString.substring(index);
      });
    } else {
      _messageBuffer = (backspacesCounter > 0
          ? _messageBuffer.substring(
              0, _messageBuffer.length - backspacesCounter)
          : _messageBuffer + dataString);
    }
  }

  void _sendMessage(String text) async {
    text = text.trim();

    if (text.length > 0) {
      try {
        connection.output.add(utf8.encode(text + "\r\n"));
        await connection.output.allSent;

      } catch (e) {
        // Ignore error, but notify state
        setState(() {});
      }
    }
  }
}
