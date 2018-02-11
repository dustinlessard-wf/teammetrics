import 'dart:async';
import 'dart:io';

import 'package:aqueduct/aqueduct.dart';
import 'package:github/server.dart' as git;

import '../service/github_service.dart';

class PrController extends HTTPController {
  PrController(this.githubService) : super() {
    responseContentType = ContentType.HTML;
  }

  GithubService githubService;

  @httpGet
  Future<Response> getPrs(@HTTPQuery("repos") String repos, { @HTTPQuery("ignoreAuthors") String ignoreAuthors: '' }) async {
    List<String> ignoreAuthorsList = ignoreAuthors.split(',');
    final github = githubService.client;
      
    List<String> repoList = repos.split(",");
    List<git.PullRequest> prs = [];
    
    for (var repoName in repoList) {
      final repoSlug = new git.RepositorySlug("workiva", repoName);
      final rawPullRequests = github.pullRequests.list(repoSlug);
      List<git.PullRequest> pullRequests = await rawPullRequests.toList();
      
      prs.addAll(pullRequests.where((git.PullRequest pr) {
        return pr.state == 'open' &&
            ignoreAuthorsList.indexOf(pr.user.login) == -1;
      }));
    }

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
    }

    if (days <= 2) {
      panelclass = 'panel-success';
      age = '';
    }

    prHtml +=
      '<div class="panel ${panelclass}"><div class="panel-heading">${pr.title}$age</div><div class="panel-body"><label>created at:</label> ${pr.createdAt}<br/><label>url:</label> <a target="_blank" href="${pr.htmlUrl}">${pr.htmlUrl}</a></div></div>';
    });

    return new Response.ok(
      '<html>${headHtml}<body><h1>Pull Requests!</h1>${prHtml}</body></html>');
  }
}
