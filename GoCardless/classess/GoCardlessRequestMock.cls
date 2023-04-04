@isTest
global class GoCardlessRequestMock implements HttpCalloutMock {
  global HTTPResponse respond(HTTPRequest req) {
    HTTPResponse res = new HTTPResponse();
    res.setHeader('Content-Type', 'application/json');

    // Determine which mock response to send based on the endpoint
    String endpoint = req.getEndpoint();
    if (endpoint.contains('billing_requests')) {
      res.setBody('{"billing_request_flows": {"links": {"billing_request": "BR12345"}}}');
      res.setStatusCode(200);
    } else if (endpoint.contains('billing_request_flows')) {
      res.setBody('{"mandate_request_flows": {"links": {"mandate_request": "MR12345"}}}');
      res.setStatusCode(200);
    } else if (endpoint.contains('billing_requests/BR')) {
      res.setBody('{"billing_requests": {"mandate_request": {"links": {"mandate": "MA12345"}},"id":"BR12345"}}');
      res.setStatusCode(200);
    } else if (endpoint.contains('payments')) {
      res.setBody('{"payments": {"id": "PM12345"}}');
      res.setStatusCode(200);
    } else {
      res.setBody('{"error": "Endpoint not found"}');
      res.setStatusCode(404);
    }

    return res;
  }
}