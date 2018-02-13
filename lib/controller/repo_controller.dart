import 'dart:async';
import 'dart:io';
import 'package:aqueduct/aqueduct.dart';
import 'package:github/server.dart' as git;

// aaronlademann-wf,clairesarsam-wf,dustinlessard-wf,evanweible-wf,greglittlefield-wf,jacehensley-wf,jayudey-wf,maxwellpeterson-wf,toddbeckman-wf,corwinsheahan-wf,sebastianmalysa-wf
// app_intelligence_dart,dart_storybook,dart_to_js_script_rewriter,dart_transformer_utils,fluri,frugal,key_binder,over_react,over_react_test,platform_detect,state_machine,truss,w_common,w_context_menu,w_flux,w_input_validation,w_module,w_oauth2,w_router,w_session,w_transport,w_virtual_components,wdesk,web_skin_dart

class RepoController extends HTTPController {
  static final headHtml =
      '<head><link rel="stylesheet" href="https://cdn.wdesk.com/home/3.0.13/packages/web_skin/dist/css/web-skin.min.css"></head>';

  RepoController() : super() {
    responseContentType = ContentType.HTML;
    Logger.root.onRecord.listen((rec) => print("$rec ${rec.error ?? ""} ${rec.stackTrace ?? ""}"));
  }

  String generateTableHtmlStart(List<String> people) {
    String peopleHtml = '';
    people.forEach((String name) {
      peopleHtml +=
          '<th style="-webkit-transform: rotate(-90deg); font-size: 10px; height:100px;"><span style="display:inline-block; height:80px;">$name</span></th>';
    });
    return '<table class="table table-bordered" style="margin:20px; width:80%;"><tr><th style="height:50px;font-size: 10px;"></th>$peopleHtml';
  }

  /// Get ContributorStatistics for repos
  Future<List<List<git.ContributorStatistics>>> getStatsForRepos(List<String> repos, String token) async {
    final github = git.createGitHubClient(auth: new git.Authentication.withToken(token));
    Logger.root.info('created client');
    List<Future<List<git.ContributorStatistics>>> asyncWork = [];

//    github.repositories
//          .listContributorStats(new git.RepositorySlug('Workiva', 'app_intelligence_dart')).then((List<git.ContributorStatistics> things){
//       print('got something');
//    });

    repos.forEach((String repoName) {
      print('adding work for $repoName');
      asyncWork.add(github.repositories.listContributorStats(new git.RepositorySlug('Workiva', repoName)));
    });

    return Future.wait(asyncWork).catchError((e, s) {
      print(e);
      print(s);
    });
  }

  Map<String, dynamic> generateRepoAndPeopleMapsBasedOnAdditions(List<List<git.ContributorStatistics>> statsList,
      List<String> people, List<String> repoList, DateTime start, DateTime end) {
    int repoListIndex = 0;
    Map<String, int> peopleToCommits = {};
    Map<String, Map<String, int>> repoToPeople = {};
    if (statsList != null) {
      statsList.forEach((List<git.ContributorStatistics> stats) {
        String repoName = repoList[repoListIndex];
        // process each repo's contributors
        peopleToCommits = {};
        people.forEach((String name) {
          peopleToCommits[name] = 0;
        });
        stats.forEach((git.ContributorStatistics stat) {
          if (people.contains(stat.author.login)) {
            print('processing ${stat.author.login}');
            stat.weeks.forEach((git.ContributorWeekStatistics week) {
              print('weekstart:${week.start}:');
              String weekStartString = week.start;
              int intStart = int.parse(weekStartString.toString());

              DateTime weekstart = new DateTime.fromMillisecondsSinceEpoch(intStart * 1000);
              print(weekstart.toIso8601String());
              if (weekstart.isAfter(start) && weekstart.isBefore(end)) {
                peopleToCommits[stat.author.login] += week.additions;
              }
            });
          }
        });
        print('have stats for $repoName');
        repoToPeople[repoName] = peopleToCommits;

        repoListIndex++;
      });
    }
    return {'repoToPeople': repoToPeople, 'peopleToCommits': peopleToCommits};
  }

  Map<String, dynamic> generateRepoAndPeopleMapsBasedOnCommits(
      List<List<git.ContributorStatistics>> statsList, List<String> people, List<String> repoList) {
    int repoListIndex = 0;
    Map<String, int> peopleToCommits = {};
    Map<String, Map<String, int>> repoToPeople = {};
    if (statsList != null) {
      statsList.forEach((List<git.ContributorStatistics> stats) {
        String repoName = repoList[repoListIndex];
        // process each repo's contributors
        peopleToCommits = {};
        people.forEach((String name) {
          peopleToCommits[name] = 0;
        });
        stats.forEach((git.ContributorStatistics stat) {
          if (people.contains(stat.author.login)) {
            peopleToCommits[stat.author.login] = stat.total;
          }
        });
        print('have stats for $repoName');
        repoToPeople[repoName] = peopleToCommits;

        repoListIndex++;
      });
    }
    return {'repoToPeople': repoToPeople, 'peopleToCommits': peopleToCommits};
  }

  String generateRepoToPeopleHtmlBasedOnAdditions(
      Map<String, Map<String, int>> repoToPeople, Map<String, int> peopleToCommits) {
    print('generateRepoToPeopleHtml');
    String repohtml = '';
    repoToPeople.forEach((String repoName, dynamic peopleToCommits) {
      repohtml += '<tr><th style="font-size: 10px;">$repoName</th>';
      String color = 'red';
      peopleToCommits.forEach((String name, int value) {
        if (value == 0) {
          color = 'red';
        } else if (value < 1000) {
          color = 'orange';
        } else {
          color = 'green';
        }
        repohtml += '<td style="background-color:$color; width:10px; height:10px;" alt="$value">&nbsp;</td>';
      });
      repohtml += '</tr>';
    });
    return repohtml;
  }

  String generateRepoToPeopleHtmlBasedOnCommits(
      Map<String, Map<String, int>> repoToPeople, Map<String, int> peopleToCommits) {
    print('generateRepoToPeopleHtml');
    String repohtml = '';
    repoToPeople.forEach((String repoName, dynamic peopleToCommits) {
      repohtml += '<tr><th style="font-size: 10px;">$repoName</th>';
      String color = 'red';
      peopleToCommits.forEach((String name, int value) {
        if (value == 0) {
          color = 'red';
        } else if (value < 10) {
          color = 'orange';
        } else {
          color = 'green';
        }
        repohtml += '<td style="background-color:$color; width:10px; height:10px;" alt="$value">&nbsp;</td>';
      });
      repohtml += '</tr>';
    });
    return repohtml;
  }

  @httpGet
  Future<Response> getRepo(@HTTPQuery("repos") String repos, @HTTPQuery("authors") String authors,
      @HTTPQuery("token") String token, @HTTPQuery("start") String start, @HTTPQuery("end") String end) async {
    List<String> people = authors.split(',');
    List<String> repoList = repos.split(',');
    List<List<git.ContributorStatistics>> statsList = await getStatsForRepos(repoList, token);

    Map<String, dynamic> repoAndPeopleMaps = generateRepoAndPeopleMapsBasedOnAdditions(
        statsList, people, repoList, DateTime.parse(start), DateTime.parse(end));

    print(repoAndPeopleMaps);

    String repoHtml = generateRepoToPeopleHtmlBasedOnAdditions(
        repoAndPeopleMaps['repoToPeople'], repoAndPeopleMaps['peopleToCommits']);

    return new Response.ok(
        '<html>${headHtml}<body><h1>People and Repos!</h1>${generateTableHtmlStart(people)}</tr>${repoHtml}</table></body></html>');
  }
}
