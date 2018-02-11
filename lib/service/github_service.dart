import 'package:github/server.dart' as git;

import '../configuration/github_configuration.dart';

class GithubService {
  GithubService(this.config);

  GithubConfiguration config;

  git.GitHub _client;

  git.GitHub get client {
    if (this._client == null) {
      this._client = git.createGitHubClient(
          auth: new git.Authentication.withToken(config.apiConfig.clientSecret), endpoint: config.apiConfig.baseURL);
    }

    return this._client;
  }
}