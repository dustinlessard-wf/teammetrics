import 'package:aqueduct/aqueduct.dart';
import 'dart:async';
import 'dart:io';
import 'package:w_transport/w_transport.dart' as transport;
import 'package:w_transport/vm.dart';

/// http://localhost:8081/support?room=2750828&team=AaronLademann,ClaireSarsam,CorwinSheahan,DustinLessard,EvanWeible,GregLittlefield,JaceHensley,JayUdey,MaxPeterson,ToddBeckman,TrentGrover,SebastianMalysa
///

class HipchatController extends HTTPController {
  //To get a Hipchat room id, login online and look at the details for a room.  The room-id is in the url.  ie: 2750828

  HipchatController() : super() {
    responseContentType = ContentType.HTML;
    configureWTransportForVM();
    logger.onRecord.listen((rec) => print("$rec ${rec.error ?? ""} ${rec.stackTrace ?? ""}"));
  }

  List<String> teamPeople = [];
  Map<String, String> headers = {'Authorization': 'Bearer R54dpHZGQV8HUAtjUIaEqlpCYEboJwEPl63AfZIz'};

  getRoomName(String roomId) async {
    return transport.Http
        .get(Uri.parse('https://api.hipchat.com/v2/room/$roomId'), headers: headers)
        .then((transport.Response response) {
      return response.body.asJson()['name'];
    });
  }

  @httpGet
  Future<Response> getSupport(@HTTPQuery("room") String room,
      {@HTTPQuery("team") String team, @HTTPQuery("start") String start, @HTTPQuery("end") String end}) async {
    teamPeople = team.split(',');

    DateTime endDate = end != null ? DateTime.parse(end) : new DateTime.now();
    print(endDate.toIso8601String());
    DateTime startDate = start != null ? DateTime.parse(start) : new DateTime.now().subtract(new Duration(days: 30));

    String headHtml = '<head><script type="text/javascript" src="https://www.gstatic.com/charts/loader.js"></script>'
        '<div id="piechart" style="width: 900px; height: 500px;"></div></head>';

    String roomName = await getRoomName(room);
    print('roomName:$roomName');

    Map<String, dynamic> json = await transport.Http
        .get(
            Uri.parse(
                'https://api.hipchat.com/v2/room/$room/history?max-results=1000&date=${endDate.toIso8601String()}&end-date=${startDate.toIso8601String()}'),
            headers: headers)
        .then(parseForTeamBreakdown);

    String pToM = '';
    json.forEach((String key, dynamic value) {
      pToM += '["$key", $value],';
    });
    //print(json);
//        return new Response.ok(json);
    String peopleMessages = pToM; //'["Max", 81],["Aaron", 18]';
    String js =
        "google.charts.load('current', {'packages':['corechart']});google.charts.setOnLoadCallback(drawChart);function drawChart() {var data = google.visualization.arrayToDataTable([['Person', 'Messages  in Support'],$peopleMessages]);var options = {title: 'Support Participation in $roomName'};var chart = new google.visualization.PieChart(document.getElementById('piechart'));chart.draw(data, options);}";

    return new Response.ok('<html>${headHtml}<script type="application/javascript">${js}</script><body></body></html>');
  }

  Future<Map<String, dynamic>> parseForTeamBreakdown(r) async {
    transport.Response response = r;
    Map<String, dynamic> responseBody = response.body.asJson();
    //print(responseBody);
    List<dynamic> items = responseBody['items'];
    Map<String, dynamic> personToCount = {};
//    personToCount['count'] = items.length;
    bool foundPeople = false;

//    personToCount['start'] = items[0]['date'];
//    personToCount['end'] = items[items.length-1]['date'];

    items.forEach((Map<String, dynamic> item) {
      String from;
      if (item.containsKey('from')) {
        from = item['from'];
        if (item['from'] is! String) {
          from = item['from']['mention_name'];
        }
        if (teamPeople.contains(from)) {
          foundPeople = true;
          if (personToCount.containsKey(from)) {
            personToCount[from]++;
          } else {
            personToCount[from] = 1;
          }
        }
      }
      //personToCount[item['from']] = 0;
    });

    //personToCount['foundPeople'] = foundPeople;
    return personToCount;
  }

  Future parseForDailyStats(r) async {
    transport.Response response = r;
    Map<String, dynamic> responseBody = response.body.asJson();
    List<dynamic> items = responseBody['items'];

    String message;
    String dateString;
    Map<String, int> datesToCounts = {};

    items.forEach((Map<String, dynamic> item) {
      message = item['message'];
      if (teamPeople.contains(item['from']['mention_name'])) {} else {
        if (message.contains('?')) {
          dateString = item['date'];
          DateTime dt = DateTime.parse(dateString);
          String dtString = '${dt.month}-${dt.day}-${dt.year}';
          if (datesToCounts.containsKey(dtString)) {
            datesToCounts[dtString]++;
          } else {
            datesToCounts[dtString] = 1;
          }
        }
      }
    });

    String dtc = '';
    datesToCounts.forEach((String key, int value) {
      dtc += '$key,$value ';
    });

    return dtc;
  }
}
