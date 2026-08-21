namespace SupplyChain.ExceptionAgent;

using Microsoft.Purchases.Document;
using Microsoft.Sales.Document;

page 50303 "SCAExceptionLines"
{
    ApplicationArea = All;
    Caption = 'Exceptions';
    Editable = false;
    PageType = ListPart;
    SourceTable = "SCAExceptionLine";
    SourceTableView = sorting("Analysis Entry No.", "Risk Level", "Line No.") order(descending);

    layout
    {
        area(Content)
        {
            repeater(Exceptions)
            {
                field("Risk Level"; Rec."Risk Level")
                {
                    ApplicationArea = All;
                    StyleExpr = RiskStyle;
                }
                field("Exception Type"; Rec."Exception Type") { ApplicationArea = All; }
                field("Item No."; Rec."Item No.") { ApplicationArea = All; }
                field(Description; Rec.Description) { ApplicationArea = All; }
                field("Location Code"; Rec."Location Code") { ApplicationArea = All; }
                field("Demand Document No."; Rec."Demand Document No.") { ApplicationArea = All; }
                field("Customer No."; Rec."Customer No.") { ApplicationArea = All; }
                field("Demand Date"; Rec."Demand Date") { ApplicationArea = All; }
                field("Outstanding Demand Qty. (Base)"; Rec."Outstanding Demand Qty. (Base)") { ApplicationArea = All; }
                field("Current Inventory (Base)"; Rec."Current Inventory (Base)") { ApplicationArea = All; }
                field("PO Supply by Need Date (Base)"; Rec."PO Supply by Need Date (Base)") { ApplicationArea = All; }
                field("Additional Supply (Base)"; Rec."Additional Supply (Base)") { ApplicationArea = All; }
                field("Projected Availability (Base)"; Rec."Projected Availability (Base)") { ApplicationArea = All; }
                field("Shortage Qty. (Base)"; Rec."Shortage Qty. (Base)") { ApplicationArea = All; }
                field("Next Inbound Date"; Rec."Next Inbound Date") { ApplicationArea = All; }
                field("Source Purchase Order No."; Rec."Source Purchase Order No.") { ApplicationArea = All; }
                field("Vendor No."; Rec."Vendor No.") { ApplicationArea = All; }
                field("Expected Receipt Date"; Rec."Expected Receipt Date") { ApplicationArea = All; }
                field("Days Late"; Rec."Days Late") { ApplicationArea = All; }
                field(Reason; Rec.Reason) { ApplicationArea = All; }
                field(Recommendation; Rec.Recommendation) { ApplicationArea = All; }
                field("Resolution Status"; Rec."Resolution Status") { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(OpenDemandOrder)
            {
                ApplicationArea = All;
                Caption = 'Open Demand Order';
                Enabled = Rec."Demand Document No." <> '';
                Image = Document;
                ToolTip = 'Open the sales order that generated the selected demand.';
                trigger OnAction()
                var
                    SalesHeader: Record "Sales Header";
                begin
                    if SalesHeader.Get(SalesHeader."Document Type"::Order, Rec."Demand Document No.") then
                        Page.Run(Page::"Sales Order", SalesHeader);
                end;
            }
            action(OpenPurchaseOrder)
            {
                ApplicationArea = All;
                Caption = 'Open Purchase Order';
                Enabled = Rec."Source Purchase Order No." <> '';
                Image = Document;
                ToolTip = 'Open the purchase order associated with the selected inbound supply.';
                trigger OnAction()
                var
                    PurchaseHeader: Record "Purchase Header";
                begin
                    if PurchaseHeader.Get(PurchaseHeader."Document Type"::Order, Rec."Source Purchase Order No.") then
                        Page.Run(Page::"Purchase Order", PurchaseHeader);
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        case Rec."Risk Level" of
            Rec."Risk Level"::Critical:
                RiskStyle := 'Unfavorable';
            Rec."Risk Level"::High:
                RiskStyle := 'Attention';
            Rec."Risk Level"::Medium:
                RiskStyle := 'Ambiguous';
            else
                RiskStyle := 'Favorable';
        end;
    end;

    var
        RiskStyle: Text;
}
