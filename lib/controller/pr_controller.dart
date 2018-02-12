import 'dart:async';
import 'dart:io';

import 'package:aqueduct/aqueduct.dart';
import 'package:github/server.dart' as git;

import '../service/github_service.dart';

class PrController extends HTTPController {
  GithubService githubService;

  PrController(this.githubService) : super() {
    responseContentType = ContentType.HTML;
  }

  @httpGet
  Future<Response> getPrs(@HTTPQuery("repos") String repos,
      {@HTTPQuery("ignoreAuthors") String ignoreAuthors: ''}) async {
    // Create a List of pull request authors to ignore.
    List<String> ignoreAuthorsList = ignoreAuthors.split(',');

    // Create a List of repositories in which to fetch their pull requests.
    List<String> repoList = repos.split(",");
    List<git.PullRequest> pullRequests = await githubService.getRepositoriesPullRequests(repoList);

    // Filter the pull requests to just those open and not with an ignored author.
    List<git.PullRequest> prs = pullRequests.where((git.PullRequest pr) {
      return pr.state == 'open' && ignoreAuthorsList.indexOf(pr.user.login) == -1;
    }).toList();
    // Sort the pull requests by the data created.
    prs.sort((git.PullRequest a, git.PullRequest b) {
      return a.createdAt.compareTo(b.createdAt);
    });

    String prHtml = '';
    String headHtml =
        '<head><link rel="stylesheet" href="https://cdn.wdesk.com/home/3.0.13/packages/web_skin/dist/css/web-skin.min.css"></head>';

    String panelclass = 'panel-warning';
    DateTime now = new DateTime.now();
    prs.forEach((git.PullRequest pr) {
      int days = now.difference(pr.createdAt).inDays;

      String age = ' is $days days old!!';
      if (days >= 7) {
        panelclass = 'panel-danger';
      } else if (days <= 2) {
        panelclass = 'panel-success';
        age = '';
      }

      prHtml +=
          '<div class="panel ${panelclass}"><div class="panel-heading">${pr.title}$age</div><div class="panel-body"><label>created at:</label> ${pr.createdAt}<br/><label>url:</label> <a target="_blank" href="${pr.htmlUrl}">${pr.htmlUrl}</a></div></div>';
    });

    return new Response.ok('<html>${headHtml}<body><h1>Pull Requests!</h1>${prHtml}</body></html>');
  }
}
