import './configuration/teammetrics_configuration.dart';
import './controller/hipchat_controller.dart';
import './controller/pr_controller.dart';
import './controller/prtrend_controller.dart';
import './controller/repo_controller.dart';
import './service/github_service.dart';

import './teammetrics.dart';

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
class TeammetricsSink extends RequestSink {
  /// Constructor called for each isolate run by an [Application].
  ///
  /// This constructor is called for each isolate an [Application] creates to serve requests.
  /// The [appConfig] is made up of command line arguments from `aqueduct serve`.
  ///
  /// Configuration of database connections, [HTTPCodecRepository] and other per-isolate resources should be done in this constructor.
  TeammetricsSink(ApplicationConfiguration appConfig) : super(appConfig) {
    var configFilePath = appConfig.configurationFilePath;
    teamMetricsConfiguration = new TeammetricsConfiguration(configFilePath);

    RequestController.includeErrorDetailsInServerErrorResponses = true;
    logger.onRecord.listen((rec) => print("$rec ${rec.error ?? ""} ${rec.stackTrace ?? ""}"));
  }

  TeammetricsConfiguration teamMetricsConfiguration;

  /// All routes must be configured in this method.
  ///
  /// This method is invoked after the constructor and before [willOpen] Routes must be set up in this method, as
  /// the router gets 'compiled' after this method completes and routes cannot be added later.
  @override
  void setupRouter(Router router) {
    // Prefer to use `pipe` and `generate` instead of `listen`.
    // See: https://aqueduct.io/docs/http/request_controller/
    router.route("/prs").generate(() => new PrController(new GithubService(teamMetricsConfiguration.github)));

    router.route("/prtrend").generate(() => new PrtrendController());
    router.route("/repo").generate(() => new RepoController());
    router.route("/support").generate(() => new HipchatController());
  }

  /// Final initialization method for this instance.
  ///
  /// This method allows any resources that require asynchronous initialization to complete their
  /// initialization process. This method is invoked after [setupRouter] and prior to this
  /// instance receiving any requests.
  @override
  Future willOpen() async {}
}