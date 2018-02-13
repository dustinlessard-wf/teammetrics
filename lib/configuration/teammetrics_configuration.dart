import 'package:aqueduct/aqueduct.dart';

import './github_configuration.dart';

class TeammetricsConfiguration extends ConfigurationItem {
  TeammetricsConfiguration(String path) : super.fromFile(path);

  GithubConfiguration github;
}
