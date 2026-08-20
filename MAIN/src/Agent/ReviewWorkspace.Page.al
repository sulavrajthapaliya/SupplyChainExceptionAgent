namespace SupplyChain.ExceptionAgent;

using Microsoft.Purchases.Document;
using Microsoft.Sales.Document;

page 50304 "SCAReviewWorkspace"
{
    AdditionalSearchTerms = 'supply chain agent workspace, current shortages, late purchase orders';
    ApplicationArea = All;
    Caption = 'Current Supply Chain Exceptions';
    Editable = false;
    PageType = List;
    SourceTable = "SCAExceptionLine";
    UsageCategory = Tasks;

    layout
    {
        area(Content)
        {
            repeater(Exceptions)
            {
                field("Risk Level"; Rec."Risk Level") { ApplicationArea = All; }
                field("Exception Type"; Rec."Exception Type") { ApplicationArea = All; }
                field("Item No."; Rec."Item No.") { ApplicationArea = All; }
                field(Description; Rec.Description) { ApplicationArea = All; }
                field("Location Code"; Rec."Location Code") { ApplicationArea = All; }
                field("Demand Document No."; Rec."Demand Document No.") { ApplicationArea = All; }
                field("Demand Date"; Rec."Demand Date") { ApplicationArea = All; }
                field("Shortage Qty. (Base)"; Rec."Shortage Qty. (Base)") { ApplicationArea = All; }
                field("Source Purchase Order No."; Rec."Source Purchase Order No.") { ApplicationArea = All; }
                field("Expected Receipt Date"; Rec."Expected Receipt Date") { ApplicationArea = All; }
                field("Days Late"; Rec."Days Late") { ApplicationArea = All; }
                field(Reason; Rec.Reason) { ApplicationArea = All; }
                field(Recommendation; Rec.Recommendation) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(RunFullScan)
            {
                ApplicationArea = All;
                Caption = 'Run Full Scan';
                Image = AnalysisView;
                trigger OnAction()
                var
                    Engine: Codeunit "SCAExceptionEngine";
                begin
                    Engine.RunFullScan(false);
                    ApplyLatestAnalysisFilter();
                    CurrPage.Update(false);
                end;
            }
            action(OpenDemandOrder)
            {
                ApplicationArea = All;
                Caption = 'Open Demand Order';
                Enabled = Rec."Demand Document No." <> '';
                Image = Document;
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

    trigger OnOpenPage()
    begin
        ApplyLatestAnalysisFilter();
    end;

    local procedure ApplyLatestAnalysisFilter()
    var
        AnalysisHeader: Record "SCAAnalysisHeader";
    begin
        AnalysisHeader.SetRange(Scope, AnalysisHeader.Scope::"Full Scan");
        if AnalysisHeader.FindLast() then
            Rec.SetRange("Analysis Entry No.", AnalysisHeader."Entry No.")
        else
            Rec.SetRange("Analysis Entry No.", 0);
    end;
}
