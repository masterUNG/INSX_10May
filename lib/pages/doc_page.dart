import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:psinsx/models/get_date_model.dart';
import 'package:psinsx/models/insx_check_model.dart';
import 'package:psinsx/models/insx_model.dart';
import 'package:psinsx/pages/insx_showdata_check.dart';
import 'package:psinsx/utility/my_style.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DocPage extends StatefulWidget {
  DocPage({Key key}) : super(key: key);

  @override
  _DocPageState createState() => _DocPageState();
}

class _DocPageState extends State<DocPage> {
  bool loadStatus = true; //โหลด
  bool status = true; //มีข้อมูล
  List<InsxModel> insxModels = List();
  List<InsxCheckModel> insxCheckModels = [];
  List<GetDatModel> getDateModels = [];
  List<Color> colorIcons = List();
  List<File> files = List();
  String urlImage;

  @override
  void initState() {
    super.initState();
    readDate();
    readInsx();
  }

  void setToOrigin() {
    loadStatus = true;
    status = true;
    insxCheckModels.clear();
    getDateModels.clear();
    colorIcons.clear();
    files.clear();
  }

  Future<Null> readDate() async {
    String url = 'https://pea23.com/apipsinsx/getDate.php';

    //print('url ====>>> $url');
    await Dio().get(url).then((value) {
      setState(() {
        loadStatus = false;
      });

      if (value.toString() != 'null') {
        var result = json.decode(value.data);
        for (var map in result) {
          //print('map  ====>>> $map');
          GetDatModel getDatModel = GetDatModel.fromJson(map);
          //print('map  ====>>> $map');
          setState(() {
            getDateModels.add(getDatModel);
          });
        }
      } else {
        setState(() {
          status = false;
        });
      }
    });
  }

  Future<Null> readInsx() async {
    if (insxCheckModels.length != 0) {
      setToOrigin();
    }
    SharedPreferences preferences = await SharedPreferences.getInstance();
    String userId = preferences.getString('id');
    String stafName = preferences.getString('staffname');
    //print('userId === $userId');
    //print('staffName === $stafName');

    String url =
        'https://pea23.com/apipsinsx/getDocWhereUserSuccess.php?isAdd=true&user_id=$userId';

    print('url ====>>> $url');
    await Dio().get(url).then((value) {
      setState(() {
        loadStatus = false;
      });

      if (value.toString() != 'null') {
        var result = json.decode(value.data);
        for (var map in result) {
          //print('map  ====>>> $map');
          InsxCheckModel insxCheckModel = InsxCheckModel.fromJson(map);

          setState(() {
            insxCheckModels.add(insxCheckModel);
          });
        }
      } else {
        setState(() {
          status = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(100.0),
        child: AppBar(
          toolbarHeight: 100,
          title: Text('ผลการตรวจสอบ'),
        ),
      ),
      body:
          loadStatus ? Center(child: MyStyle().showProgress()) : showContent(),
    );
  }

  Widget showContent() {
    return status
        ? showListInsx()
        : Container(
            child: Center(
              child: Text(
                'No Data',
                style: TextTheme().bodyText1,
              ),
            ),
          );
  }

  Widget showListInsx() => SingleChildScrollView(
        child: Column(
          children: [
            ListView.builder(
              itemCount: getDateModels.length,
              shrinkWrap: true,
              itemBuilder: (context, index) =>
                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Center(child: Text(getDateModels[index].getDatList)),
                  ),
            ),
            Card(
              child: ListTile(
                title: Text(insxCheckModels.length == 0
                    ? 'เสร็จสมบูรณ์ : ? รายการ'
                    : 'เสร็จสมบูรณ์ : ${insxCheckModels.length} รายการ'),
              ),
            ),
            ListView.builder(
              itemCount: insxCheckModels.length,
              shrinkWrap: true,
              physics: ScrollPhysics(),
              itemBuilder: (context, index) => GestureDetector(
                onTap: () {
                  MaterialPageRoute route = MaterialPageRoute(
                    builder: (context) => InsxShowDataCheck(
                      insxCheckModels: insxCheckModels[index],
                    ),
                  );
                  Navigator.push(context, route);
                },
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: ListTile(
                      // leading: Image.network(
                      //   insxCheckModels[index].imageInsx,
                      //   fit: BoxFit.cover,
                      //   width: 50,
                      //   height: 50,
                      // ),
                      leading: Icon(Icons.check),
                      title: Text(
                        insxCheckModels[index].ca,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        '${insxCheckModels[index].cusName} \n${insxCheckModels[index].imgDate} ',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
}
