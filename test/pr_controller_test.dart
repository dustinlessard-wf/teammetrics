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
      Map mockPr = {
        'created_at': '2017-12-28 20:30:11.000Z',
        'state': 'open',
        'title': 'A PR title for a test',
        'html_url': 'https://not.github.com/workiva/test_repo/pull/812',
        'user': {'login': 'teammetrics-wf', 'avatar_url': 'https://not.github.com/images/teammetrics-wf_guapo.gif'}
      };
      mockGithubServer.queueResponse(new Response.ok([mockPr]));

      var response = await app.client.request('/prs?repos=test_repo').get();
      var githubApiRequest = await mockGithubServer.next();

      expect(githubApiRequest.method, 'GET');
      expect(githubApiRequest.path, '/repos/workiva/test_repo/pulls');
      expect(response, hasResponse(200, contains('Pull Requests!')));
      expect(response, hasResponse(200, contains(mockPr['title'])));
      expect(response, hasResponse(200, contains(mockPr['created_at'])));
      expect(response, hasResponse(200, contains(mockPr['html_url'])));
    });
  });
}
