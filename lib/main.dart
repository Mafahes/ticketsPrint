// @dart=2.9
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:signalr_netcore/hub_connection_builder.dart';
import 'dart:math' as math;

import 'package:window_manager/window_manager.dart';
void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  MyApp({Key key}) : super(key: key);

  @override
  _MyAppState createState() {
    return _MyAppState();
  }
}

class _MyAppState extends State<MyApp> {
  TextEditingController text = TextEditingController();
  final hubConnection = HubConnectionBuilder()
      .withUrl('https://electronicqueue.3dcafe.ru/workspace').build();
  @override
  void initState() {
    invoking();
    // checkLocal();
    windowHide();
    super.initState();
  }
  checkLocal() async {
    SharedPreferences sh = await SharedPreferences.getInstance();
    if(sh.getInt('roomId') != null) {
      setState(() {
        text.text = '${sh.getInt('roomId')}';
      });
    }
  }
  windowHide() async {
    WidgetsFlutterBinding.ensureInitialized();
    // Must add this line.
    await windowManager.ensureInitialized();

    // Use it only after calling `hiddenWindowAtLaunch`
    windowManager.waitUntilReadyToShow().then((_) async{
      windowManager.hide();
      // windowManager.unmaximize();
    });
  }
  @override
  void dispose() {
    super.dispose();
  }
  invoking() async {
    await hubConnection.start();
    hubConnection.on('register', (arguments) async {
      // SharedPreferences sh = await SharedPreferences.getInstance();
      // if(sh.getInt('roomId') != null && (arguments[0] as dynamic)['roomId'] != sh.getInt('roomId')) {
      //   return;
      // }
      printInvoke((arguments[0] as dynamic)['name'], (arguments[0] as dynamic)['service']['name'], (arguments[0] as dynamic)['dateAdd'], (arguments[1] as dynamic)['count']);
    });
  }
  printInvoke(title, service, String dateT, pos) async {
    DateTime date = DateTime.parse(dateT);
    date = date.add(Duration(hours: 3));
    var doc = pw.Document();
    var font = await rootBundle.load("lib/assets/OpenSans-Regular.ttf");
    var font2 = await rootBundle.load("lib/assets/OpenSans-Bold.ttf");

    var ttf = pw.Font.ttf(font);
    var ttf2 = pw.Font.ttf(font2);
    doc.addPage(pw.Page(
      pageFormat: const PdfPageFormat(76 * (72.0 / 25.4), double.infinity, marginAll: 5 * (72.0 / 25.4)),
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Transform.rotate(
              angle: math.pi / 1,
              child: pw.Container(
                  padding: const pw.EdgeInsets.symmetric(vertical: 30),
                  child: pw.Column(
                      children: [
                        pw.Text('ГБУ «Ритуал»', textAlign: pw.TextAlign.center, style: pw.TextStyle(font: ttf, fontWeight: pw.FontWeight.bold, fontSize: 20)),
                        pw.SizedBox(height: 30),
                        pw.Text(title, textAlign: pw.TextAlign.center, style: pw.TextStyle(font: ttf2, fontSize: 60)),
                        pw.Text(service, textAlign: pw.TextAlign.center, style: pw.TextStyle(font: ttf, fontSize: 20)),
                        pw.Text('Номер в очереди: $pos', textAlign: pw.TextAlign.center, style: pw.TextStyle(font: ttf, fontSize: 9)),
                        pw.SizedBox(height: 35),
                        pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text('Дата: ${date.day}.${date.month}.${date.year}', style: pw.TextStyle(fontSize: 9, font: ttf)),
                              pw.Text('Время: ${date.hour}:${date.minute < 10 ? '0${date.minute}' : date.minute}', style: pw.TextStyle(fontSize: 9, font: ttf)),
                              pw.SizedBox(width: 5),
                            ]
                        ),
                        pw.SizedBox(height: 10),
                      ]
                  )
              )
            ),
          );
        }));
    await Printing.sharePdf(bytes: await doc.save(), filename: 'my-document.pdf');
    // Printing.listPrinters().then((value) {
    //   Printing.directPrintPdf(
    //     printer: value[0], onLayout: (format) async => doc.save());
    // });
  }
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return MaterialApp(
      home: Scaffold(
        body: Container(
          child: FutureBuilder(future: Printing.listPrinters(), builder: (ctx, snap) {
            if(!snap.hasData) {
              return Center(
                child: Text('Загрузка'),
              );
            }
            return Center(
              child: GestureDetector(
                onTap: () {
                  // windowHide();
                  printInvoke('Д5', 'Другие вопросы', '2021-11-30T18:12:09.1352922+03:00', 5);
                },
                child: Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: Container(
                        margin: EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Укажите идентификатор комнаты в которой будет стоять терминал'),
                            SizedBox(height: 5),
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(width: 1.0, color: Colors.grey)
                              ),
                              padding: const EdgeInsets.all(10),
                              child: TextField(
                                controller: text,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration.collapsed(
                                    hintText: 'ID помещения'
                                ),
                              ),
                            ),
                            SizedBox(height: 10),
                            Container(
                              child: ElevatedButton(
                                  onPressed: () async {
                                    SharedPreferences sh = await SharedPreferences.getInstance();
                                    print(sh.get('roomId'));
                                    if(int.tryParse(text.text) != null) {
                                      sh.setInt('roomId', int.parse(text.text));
                                    }
                                  },
                                  child: Text('Сохранить')),
                            )
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: snap.data.map<Widget>((e) => Text(e.name)).toList(),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            );
          },),
        ),
      ),
    );
  }
}