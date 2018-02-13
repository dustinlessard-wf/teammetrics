import 'package:aqueduct/aqueduct.dart';

class GithubConfiguration extends ConfigurationItem {
  APIConfiguration apiConfig;

  @optionalConfiguration
  String owner;
}
