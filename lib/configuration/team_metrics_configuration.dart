import 'package:aqueduct/aqueduct.dart';

import './github_configuration.dart';

class TeamMetricsConfiguration extends ConfigurationItem {
  TeamMetricsConfiguration(String path) : super.fromFile(path);

  GithubConfiguration github;
}
