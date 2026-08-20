# Automated Test Matrix

This app contains **37 automated tests**. Each test codeunit requires function-level isolation.

| Codeunit | Test |
|---|---|
| SCAAgentTests | `MissingAgentConfigurationReturnsFriendlyError` |
| SCAAgentTests | `StaleAgentGuidReturnsFriendlyError` |
| SCADemandTests | `NoInboundSupplyCreatesCriticalException` |
| SCADemandTests | `SmallNoInboundShortageIsAtLeastHigh` |
| SCADemandTests | `OnTimePurchaseSupplyEliminatesShortage` |
| SCADemandTests | `PartialOnTimeSupplyCreatesInventoryShortage` |
| SCADemandTests | `LateFuturePurchaseSupplyCreatesLateInboundException` |
| SCADemandTests | `OverduePurchaseSupplyCreatesLateInboundException` |
| SCADemandTests | `CurrentInventoryEliminatesShortage` |
| SCADemandTests | `PartialInventoryCreatesShortage` |
| SCADemandTests | `CumulativeDemandAcrossOrdersUsesSameStock` |
| SCADemandTests | `InventoryIsLocationSpecific` |
| SCADemandTests | `PurchaseSupplyIsLocationSpecific` |
| SCADemandTests | `PastDueDemandOneDayIsMedium` |
| SCADemandTests | `PastDueDemandFourDaysIsHigh` |
| SCADemandTests | `PastDueDemandEightDaysIsCritical` |
| SCADemandTests | `FutureDemandBeyondHorizonIsIgnored` |
| SCADemandTests | `ReleasedSalesOrderIsIncludedByDefault` |
| SCADemandTests | `ReleasedSalesOrderCanBeExcluded` |
| SCADemandTests | `ZeroOutstandingQuantityIsIgnored` |
| SCADemandTests | `BlankDemandDateStillScansSupplyRisk` |
| SCADemandTests | `ReleasedPurchaseOrderSupplyIsIncludedByDefault` |
| SCADemandTests | `ReleasedPurchaseOrderCanBeExcluded` |
| SCADemandTests | `LateReceiptWithinGraceIsInventoryShortageNotLateInbound` |
| SCADemandTests | `MinimumShortageThresholdSuppressesTinyShortage` |
| SCADemandTests | `PurchaseSupplyIsVariantSpecific` |
| SCAExtensibilityTests | `AdditionalSupplyEventCanCoverShortage` |
| SCAExtensibilityTests | `SalesDemandEventCanExcludeLine` |
| SCAFullScanTests | `OverduePurchaseSupplyAppearsInFullScan` |
| SCAFullScanTests | `FullScanMarksTruncatedAtConfiguredLimit` |
| SCAFullScanTests | `PeakShortageIsNotDoubleCountedForSameItem` |
| SCAFullScanTests | `LatestAnalysisReturnsNewestSalesOrderAnalysis` |
| SCASetupTests | `DefaultSetupValuesAreInitialized` |
| SCASetupTests | `CriticalShortageBelowHighIsRejected` |
| SCASetupTests | `CriticalPastDueBelowHighIsRejected` |
| SCASetupTests | `EqualThresholdsAreAllowed` |
| SCASetupTests | `RiskRankOrdersLowToCritical` |
