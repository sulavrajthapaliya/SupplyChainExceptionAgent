# Architecture

## Deterministic layer

`SCAExceptionEngine` owns all quantities, dates and risk calculations.

For sales demand the engine computes:

- current inventory for the Item/Location/Variant,
- cumulative open sales demand up to the need date,
- non-overdue open purchase supply expected by the need date,
- additional supply contributed by subscribers,
- projected availability,
- shortage,
- risk,
- exception type.

For purchase supply it also creates standalone exceptions for overdue open purchase lines.

## Agent layer

The agent is deliberately read-oriented:

- reads the current analysis,
- summarizes Critical/High exceptions,
- explains operational impact,
- proposes human next steps,
- never changes core documents.

This separation makes the app easier to audit and test.

## Why cumulative demand matters

A naive per-line calculation can overstate availability when several sales lines compete for the same inventory. This app compares supply against cumulative sales demand for the same Item/Location/Variant up to each line's need date.

## v1 limitation

The standard engine does not replace Order Planning/MRP/MPS. Transfer, production and assembly supply are outside the standard v1 supply set unless another extension contributes them through `OnCalculateAdditionalSupplyBase`.

## Overdue purchase supply

An outstanding purchase line whose Expected Receipt Date is before Work Date is not counted as reliable supply by the demand date. It is surfaced as overdue/late supply instead.
