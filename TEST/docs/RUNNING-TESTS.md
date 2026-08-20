# Running the tests in SaaS / CDX

This test app is designed for Business Central 28.1+ sandbox environments and does not require `Tests-TestLibraries`.

## Recommended flow

1. Make sure the production Supply Chain Exception Agent app is installed.
2. Match the publisher in both app.json files.
3. `AL: Download Symbols`.
4. `AL: Package`.
5. Publish to the sandbox.
6. Assign `SCATEST` if required.
7. Use VS Code Test Explorer to discover and run test codeunits 50410-50414. All declare `RequiredTestIsolation = Function`.

## If a test fails

Capture the test name, AL stack trace, error text, and BC application version (for example 28.1/28.2/28.3). Agent SDK signatures can vary across preview/current builds, while the deterministic scanner tests should remain stable.
