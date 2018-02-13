import 'dart:async';

import 'package:github/server.dart' as git;

import '../configuration/github_configuration.dart';

class GithubService {
  GithubConfiguration config;

  git.GitHub _client;

  GithubService(this.config) {
    this._client = git.createGitHubClient(
        auth: new git.Authentication.withToken(config.apiConfig.clientSecret), endpoint: config.apiConfig.baseURL);
  }

  git.GitHub get client => this._client;

  Future<List<git.PullRequest>> getRepositoriesPullRequests(List<String> repositories) async {
    List<git.PullRequest> pullRequests = [];

    for (var repo in repositories) {
      final repoSlug = new git.RepositorySlug(config.owner, repo);
      var pullRequestStream = _client.pullRequests.list(repoSlug);
      var fetchedPullRequests = await pullRequestStream.toList();
      pullRequests.addAll(fetchedPullRequests);
    }

    return pullRequests;
  }
}
