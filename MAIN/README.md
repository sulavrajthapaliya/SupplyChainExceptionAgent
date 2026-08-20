# Supply Chain Exception Agent

Version: **1.0.0.0**  
App ID: `4436d2d5-745b-4bf2-89c7-52fa5a5a1191`  
Target: Business Central **28.1+** / runtime **17.0**  
Object range in this development package: **50300..50399**

## What this app does

The app creates deterministic supply-chain exception analyses and lets a native Business Central agent explain and prioritize them.

The v1 deterministic engine scans:

- open/released **Sales Orders** with outstanding Item demand,
- current Item inventory by Location/Variant,
- open/released **Purchase Orders** with outstanding Item supply,
- expected purchase receipt dates,
- overdue purchase supply (treated as an exception, not reliable on-time supply),
- optional extra supply from other extensions through an integration event.

It detects:

- Past Due Demand
- Inventory Shortage
- Late Inbound Supply
- No Inbound Supply
- Overdue Purchase Supply

The AI agent does **not** calculate availability and does **not** modify Business Central documents.

## Important v1 calculation boundary

Projected availability for a sales-demand date is:

`Current Inventory + Reliable PO Supply by Need Date + Additional Supply - Cumulative Sales Demand`

All quantities are base quantities. A purchase line whose Expected Receipt Date is already before Work Date but is still outstanding is treated as **overdue/late supply** and is not counted as reliable available supply for the projection.

The standard engine does **not** natively include transfer, production, assembly or planning supply in v1. Other extensions can add such supply through:

`SCAExceptionEngine.OnCalculateAdditionalSupplyBase(...)`

This makes the calculation explicit and testable instead of pretending to be a full planning-engine replacement.

## Quick test in a sandbox

1. Replace `YOUR PUBLISHER NAME` and placeholder URLs in `app.json`.
2. Connect VS Code to a BC 28.1+ SaaS sandbox.
3. Run `AL: Download Symbols`.
4. Run `AL: Package`.
5. Publish/install the app.
6. Assign `SCAADMIN` to your test user.
7. Search **Supply Chain Exception Setup**.
8. Keep the default horizon at 30 days.
9. Create an Item with little/no inventory.
10. Create a Sales Order with an Item line and Shipment Date inside the horizon.
11. Run **Analyze Supply Risk** from the Sales Order.
12. Confirm an exception analysis is created.
13. Create a Purchase Order for the same Item/Location with Expected Receipt Date after the sales demand date.
14. Re-run analysis and confirm the exception becomes Late Inbound Supply when shortage still exists.
15. Configure the agent from **Supply Chain Exception Setup > Configure Agent**.
16. Activate it in the standard agent setup.
17. Open an analysis and choose **Send to Agent**.

## Agent safety

The agent permission set has read access to standard Sales/Purchase/Item/Customer/Vendor data and write access only to this app's analysis records. It does not receive direct modify permission to Sales Lines or Purchase Lines.

`SCAAgentMgt` uses public `Codeunit Agent.IsActive()` instead of directly reading `Record Agent`.

## Extensibility

### Add extra deterministic supply

Subscribe to:

```al
[EventSubscriber(ObjectType::Codeunit, Codeunit::"SCAExceptionEngine", 'OnCalculateAdditionalSupplyBase', '', false, false)]
local procedure AddProductionOrTransferSupply(
    SalesHeader: Record "Sales Header";
    SalesLine: Record "Sales Line";
    NeedDate: Date;
    var AdditionalSupplyBase: Decimal)
begin
    // Add only supply your extension can deterministically prove will be available by NeedDate.
end;
```

### Exclude demand lines

Subscribe to:

```al
[EventSubscriber(ObjectType::Codeunit, Codeunit::"SCAExceptionEngine", 'OnShouldIncludeSalesDemand', '', false, false)]
local procedure FilterDemand(
    SalesHeader: Record "Sales Header";
    SalesLine: Record "Sales Line";
    var IncludeLine: Boolean)
begin
    // Set IncludeLine := false when your business rules say the line must not be scanned.
end;
```

## AppSource notes

This is source intended for development/testing, not a claim of AppSource certification.

Before Marketplace submission:

- replace development object IDs `50300..50399` with your Microsoft-assigned range,
- register/confirm your publisher affix (`SCA` here is a development prefix),
- replace placeholder publisher/legal/help URLs,
- generate and review translations,
- compile with CodeCop/UICop/AppSourceCop,
- run install/upgrade/uninstall/reinstall tests,
- digitally sign the package,
- validate current Agent SDK/AppSource acceptance requirements.

## Compile status

The source has been statically generated and checked in this environment, but it has **not** been compiled against your exact Business Central symbol packages. Agent SDK signatures are version-sensitive because the feature is still preview-marked.
