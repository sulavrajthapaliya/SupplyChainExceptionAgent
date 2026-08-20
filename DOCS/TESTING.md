# Manual acceptance tests

## 1. No shortage
Given inventory is sufficient for cumulative sales demand  
When a sales order is analyzed  
Then no shortage exception is created for that demand line.

## 2. Inventory shortage
Given inventory plus purchase supply by the demand date is below cumulative demand  
When the order is analyzed  
Then an Inventory Shortage exception is created with a positive shortage quantity.

## 3. No inbound supply
Given a shortage exists and no dated open purchase supply exists  
When the order is analyzed  
Then the primary exception is No Inbound Supply and risk is at least High.

## 4. Late inbound supply
Given a shortage exists by the demand date and the next purchase receipt is after the demand date plus grace days  
When the order is analyzed  
Then the exception is Late Inbound Supply and identifies the next PO/date.

## 5. Past due demand
Given outstanding sales demand has a shipment date before Work Date  
When analyzed  
Then Past Due Demand is created even if inventory is sufficient.

## 6. Critical past due
Given demand is at least Critical Past Due Days late  
When analyzed  
Then risk is Critical.

## 7. High shortage percentage
Given shortage percentage reaches High Shortage % but is below Critical Shortage %  
When analyzed  
Then risk is High.

## 8. Critical shortage percentage
Given shortage percentage reaches Critical Shortage %  
When analyzed  
Then risk is Critical.

## 9. Cumulative demand
Given two sales lines for the same Item/Location/Variant compete for the same stock  
When the later line is analyzed  
Then cumulative demand includes the earlier qualifying line.

## 10. PO supply by need date
Given open purchase supply is expected on or before the sales demand date and is not already overdue at Work Date  
When analyzed  
Then that outstanding base quantity is included in PO Supply by Need Date.

## 11. Future PO
Given open purchase supply is expected after the demand date  
When analyzed  
Then it is not included in supply by need date and can be captured as Next Inbound Date.

## 12. Overdue purchase supply
Given an open/released purchase line has outstanding quantity and expected receipt date before Work Date  
When a full scan runs  
Then an Overdue Purchase Supply exception is created and that overdue line is not counted as reliable PO supply for sales-demand projection.

## 13. Status filters
Given setup excludes Open or Released orders  
When a scan runs  
Then documents with excluded status do not contribute demand/supply.

## 14. Additional supply event
Given a subscriber contributes 10 base units of additional supply  
When a line is analyzed  
Then Additional Supply = 10 and projected availability uses it.

## 15. Demand exclusion event
Given a subscriber sets IncludeLine = false  
When scanning  
Then no exception is created for that line.

## 16. Maximum exceptions
Given more candidate exceptions exist than Maximum Exceptions Per Scan  
When a scan runs  
Then the analysis is marked Was Truncated.

## 17. Sales-order action
Given a sales order exists  
When Analyze Supply Risk is selected  
Then a Sales Order scoped analysis is created and opened.

## 18. Agent not configured
Given no SCAAgentInstance exists  
When Send to Agent is selected  
Then a friendly configuration error is shown.

## 19. Agent inactive/missing
Given a stored agent GUID is missing or inactive  
When Send to Agent is selected  
Then a friendly missing/archived/inactive error is shown instead of direct Agent table access.

## 20. Agent task
Given an active configured agent and an analysis  
When Send to Agent is selected  
Then an Agent Task is created and Agent Task ID is stored on the analysis.

## 21. Agent safety
Given the agent is active  
When it reviews an exception  
Then it can read deterministic pages but cannot directly modify standard Sales/Purchase documents through this app permission set.
