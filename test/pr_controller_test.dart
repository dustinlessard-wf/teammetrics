import 'harness/app.dart';

Future main() async {
  TestApplication app = new TestApplication();
  MockHTTPServer mockGithubServer = new MockHTTPServer(9000);

  setUpAll(() async {
    await app.start();
    await mockGithubServer.open();
  });

  tearDownAll(() async {
    await app.stop();
    await mockGithubServer.close();
  });

  group('Successful fetching of team pull requests', () {
    test('creates a list of open PRs for repos within query params', () async {
      mockGithubServer.queueResponse(new Response.ok([{
        'created_at': '2017-12-28T20:30:11Z',
        'user': {
          'login': 'teammetrics-wf'
        },
        'state': 'open',
        'title': 'A PR title for a test',
        'html_url':'https://notgithub.com/workiva/test_repo/pull/812'
      }]));

      var response = await app.client.request('/prs?repos=test_repo').get();
      // var githubApiRequest = await mockGithubServer.next();
      
      // expect(githubApiRequest.method, "GET");
      // expect(githubApiRequest.path, "/repos/workiva/test_repo/pulls?state=open");
      expect(response, hasResponse(200, contains('Pull Requests!')));
    });
  });
}
