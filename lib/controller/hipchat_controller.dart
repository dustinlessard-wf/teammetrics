import 'metrics.dart';
import 'package:w_transport/w_transport.dart' as transport;
import 'package:w_transport/vm.dart';

/// This class handles setting up this application.
///
/// Override methods from [RequestSink] to set up the resources your
/// application uses and the routes it exposes.
///
/// See the documentation in this file for the constructor, [setupRouter] and [willOpen]
/// for the purpose and order of the initialization methods.
///
/// Instances of this class are the type argument to [Application].
/// See http://aqueduct.io/docs/http/request_sink
/// for more details.
class MetricsSink extends RequestSink {
  /// Constructor called for each isolate run by an [Application].
  ///
  /// This constructor is called for each isolate an [Application] creates to serve requests.
  /// The [appConfig] is made up of command line arguments from `aqueduct serve`.
  ///
  /// Configuration of database connections, [HTTPCodecRepository] and other per-isolate resources should be done in this constructor.
  MetricsSink(ApplicationConfiguration appConfig) : super(appConfig) {
    configureWTransportForVM();
    logger.onRecord.listen((rec) => print("$rec ${rec.error ?? ""} ${rec.stackTrace ?? ""}"));
  }

  /// All routes must be configured in this method.
  ///
  /// This method is invoked after the constructor and before [willOpen] Routes must be set up in this method, as
  /// the router gets 'compiled' after this method completes and routes cannot be added later.
  @override
  void setupRouter(Router router) {
    // Prefer to use `pipe` and `generate` instead of `listen`.
    // See: https://aqueduct.io/docs/http/request_controller/
    router
      .route("/example")
      .listen((request) async {
        String response = await test();


        return new Response.ok(response);
      });
  }

  List<String> teamPeople = ['AaronLademann', 'ClaireSarsam', 'CorwinSheahan',
  'DustinLessard', 'EvanWeible', 'JaceHensley', 'JayUdey', 'MaxPeterson',
  'ToddBeckman', 'SebastianMalysa', 'TrentGrover'];

  Future parseForTeamBreakdown(r) async{
    transport.Response response = r;
    Map<String, dynamic> responseBody = response.body.asJson();
    List<dynamic> items = responseBody['items'];
    Map<String, dynamic> personToCount = {};
    personToCount['count'] = items.length;
    bool foundPeople = false;

    personToCount['start'] = items[0]['date'];
    personToCount['end'] = items[items.length-1]['date'];


    items.forEach((Map<String, dynamic> item){
      String from;
      if(item.containsKey('from')){
        from = item['from'];
        if(item['from'] is !String){
          from = item['from']['mention_name'];
        }
        if(!teamPeople.contains(from)){
            foundPeople = true;
            if(personToCount.containsKey(from)){
              personToCount[from]++;
            }
            else{
              personToCount[from]=1;
            }
          }

      }
      //personToCount[item['from']] = 0;

    });

    personToCount['foundPeople'] = foundPeople;
    return personToCount;
  }

  Future parseForDailyStats(r) async{
    transport.Response response = r;
    Map<String, dynamic> responseBody = response.body.asJson();
    List<dynamic> items = responseBody['items'];

    String message;
    String dateString;
    Map<String, int> datesToCounts = {};


    items.forEach((Map<String, dynamic> item){
      message = item['message'];
      if(teamPeople.contains(item['from']['mention_name'])){

      } else {
        if(message.contains('?')){
          dateString = item['date'];
          DateTime dt = DateTime.parse(dateString);
          String dtString = '${dt.month}-${dt.day}-${dt.year}';
          if(datesToCounts.containsKey(dtString)){
            datesToCounts[dtString]++;
          }
          else{
            datesToCounts[dtString] = 1;
          }
        }
      }
    });

    String dtc = '';
    datesToCounts.forEach((String key, int value){
      dtc += '$key,$value ';
    });

    return dtc;
  }



  Future test() async {
    Map<String, String> headers = {'Authorization':'Bearer R54dpHZGQV8HUAtjUIaEqlpCYEboJwEPl63AfZIz'};
    return transport.Http.get(Uri.parse(
        'https://api.hipchat.com/v2/room/2750828/history?max-results=1000&date=2018-01-11T01:53:07+00:00'),headers:headers)
        .then(parseForTeamBreakdown);
  }
  /// Final initialization method for this instance.
  ///
  /// This method allows any resources that require asynchronous initialization to complete their
  /// initialization process. This method is invoked after [setupRouter] and prior to this
  /// instance receiving any requests.
  @override
  Future willOpen() async {}
}