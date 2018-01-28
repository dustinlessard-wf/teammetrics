import 'package:aqueduct/aqueduct.dart';
import 'dart:async';
import 'dart:io';
import 'package:github/server.dart' as git;

class PrtrendController extends HTTPController {
  PrtrendController() : super() {
    responseContentType = ContentType.HTML;
  }

  @httpGet
  Future<Response> getPrtrend(@HTTPQuery("repos") String repos,
      @HTTPQuery("token") String token) async {
    List<String> repoList = repos.split(",");
    final github =
    git.createGitHubClient(auth: new git.Authentication.withToken("0307ef3bbe0a06bb92c487cdd9f14b456551cb5e"));
    // date : average minutes to merge

    Map<DateTime, List<int>> datesToMinutes = {}; //{'':[4, 40, 2]}
    Map<DateTime, int> averagedValues = {};
    int lastMonthAverage = 0;
    int thisMonthAverage = 0;
    List<int>lastMonthDays = [];
    List<int>thisMonthDays = [];
    for (var repoName in repoList) {
      final repoSlug = new git.RepositorySlug("workiva", repoName);
      final rawPullRequests = github.pullRequests.list(repoSlug, state:'closed');
      List<git.PullRequest> pullRequests = await rawPullRequests.toList();
      print('count: ${pullRequests.length}');
      pullRequests.forEach((git.PullRequest pr){
        if(pr.mergedAt != null){
          List<int> value = datesToMinutes[new DateTime(pr.mergedAt.year, pr.mergedAt.month, pr.mergedAt.day)];
          if(value == null) value =[];

          value.add(pr.mergedAt.difference(pr.createdAt).inMinutes);
          datesToMinutes[new DateTime(pr.mergedAt.year, pr.mergedAt.month, pr.mergedAt.day)] = value;
            //print('${pr.mergedAt.day}-${pr.mergedAt.month}-${pr.mergedAt.year}:${pr.mergedAt.difference(pr.createdAt).inMinutes}');
        }
      });
      //

      datesToMinutes.forEach((DateTime date, List<int> values){
        int sum = 0;
        values.forEach((int i){
          sum += i;
        });
        int average = (sum/values.length).round();
        averagedValues[date] = average;
        var now = new DateTime.now();
        if(date.month == now.month && date.year == now.year){
          thisMonthDays.add(average);
        }
        if(date.month == 12 && date.year == 2017){
          lastMonthDays.add(average);
        }
      });

      print(averagedValues);
    }
lastMonthAverage = sum(lastMonthDays);
    thisMonthAverage = sum(thisMonthDays);

    String headHtml =
        '<head><script type="text/javascript" src="https://www.gstatic.com/charts/loader.js"></script>'
        '<div id="piechart" style="width: 900px; height: 500px;"></div></head>';

    String pToM = '';

    averagedValues.forEach((DateTime key, dynamic value) {
      pToM += '[new Date(${key.year},${key.month},${key.day}), $value],';
    });

    String js = "google.charts.load('current', {packages: ['corechart', 'line']});google.charts.setOnLoadCallback(drawBasic);function drawBasic() {var data = new google.visualization.DataTable();data.addColumn('date', 'X');data.addColumn('number', 'time to merge');data.addRows([$pToM]);data.sort([{column: 0}]);var dateFormatter = new google.visualization.DateFormat({dateFormat: 'dd.MM.yy hh:mm'});dateFormatter.format(data, 0); var options = {trendlines: { 1: {} }, hAxis: {title: 'Time',hAxis: { format: 'MMM yyyy' }},vAxis: {title: 'Pr created to merge'}}; var chart = new google.visualization.LineChart(document.getElementById('chart_div'));chart.draw(data, options);}";

    return new Response.ok(
        '<html>${headHtml}<script type="application/javascript">${js}</script><body><h2>Average Last Month: ${lastMonthAverage*0.0166667} hours</h2><h2>Average This Month: ${thisMonthAverage*0.0166667} hours</h2><div id="chart_div"></div></body></html>');
  }

  int sum(List<int> values){
    int sum = 0;
    values.forEach((int value){sum+=value;});
    return (sum/values.length).round();
  }
}
