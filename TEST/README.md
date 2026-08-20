# Supply Chain Exception Agent Tests

Self-contained automated AL test extension for **Supply Chain Exception Agent v1.0.0**.

## Why this version is SaaS/CDX friendly

This project intentionally has **no dependency on `Tests-TestLibraries`, `Library Assert`, `Library - Sales`, or `Library - Inventory`**. It creates the minimum required Business Central records itself and uses a small local assertion codeunit.

The only explicit app dependency is:

- Supply Chain Exception Agent (`4436d2d5-745b-4bf2-89c7-52fa5a5a1191`) v1.0.0.0

If you change the production app publisher from `YOUR PUBLISHER NAME`, update the dependency publisher in this test app's `app.json` to the exact same value.

## Coverage

The project contains **37 `[Test]` methods** covering:

- setup defaults and validation
- risk ranking
- no inbound supply
- on-time, partial, future-late, and overdue purchase supply
- current inventory and partial inventory
- cumulative demand competing for the same stock
- location-specific inventory and purchase supply
- past-due demand risk thresholds
- horizon filtering
- open/released sales-order setup behavior
- released purchase-order inclusion/exclusion
- late-receipt grace classification
- minimum-shortage suppression
- variant-specific supply isolation
- zero outstanding demand
- blank demand dates
- additional-supply integration event
- sales-demand inclusion integration event
- overdue purchase supply in full scan
- maximum-exception truncation
- peak-shortage de-duplication
- latest-analysis retrieval
- missing agent configuration
- stale/non-existent agent GUID handling

## Running in a CDX / SaaS sandbox

1. Publish/install **Supply Chain Exception Agent** first.
2. Open this test project and connect `launch.json` to your CDX sandbox.
3. Run `AL: Download Symbols`.
4. Run `AL: Package`.
5. Publish the test extension to the sandbox.
6. Assign permission set **SCATEST** to the user executing tests if the user is not already SUPER.
7. In VS Code Testing/Test Explorer, discover and run the AL tests.

## Important isolation note

Use a **sandbox/test company**, not production. The tests insert temporary sales, purchase, item, item-ledger and SCA analysis data. Every test codeunit declares `RequiredTestIsolation = Function`, so the BC 28 Test Explorer is instructed to roll back database changes after each test method. A dedicated test company is still the right place to run automated tests.

Test-created item numbers start with `SCTI`, sales orders with `SCTS`, and purchase orders with `SCTP`. Full-scan tests use the app's `OnShouldIncludeSalesDemand` event to ignore unrelated sales demand where possible, and they find their own purchase-order exception rather than assuming the company contains no other POs.

## Agent tests

The automated suite deliberately tests only failure-safe Agent integration cases that are deterministic in any sandbox:

- no configured agent
- stale/non-existent agent GUID

It does **not** auto-create/activate a real Microsoft Agent user because that would make the test suite depend on tenant feature state, Copilot licensing/availability, and agent setup permissions. Test successful task creation manually after configuring the agent.

## Compilation status

The source has been statically checked here, but it has **not been compiled against your exact CDX BC 28.x symbols**. If `AL: Package` reports an exact compiler error, use that error against this source rather than adding Microsoft test-library dependencies.
