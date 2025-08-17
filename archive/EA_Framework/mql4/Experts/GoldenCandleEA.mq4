#property strict
#include <MT4Adapter.mqh>

// ---- Inputs (client spec) ----
input double LotSize      = 0.01;   // fixed per spec, used per planned order
input int    BaseSL       = 10000;  // points (for UI info only; logic in DLL)
input bool   AutoTrading  = true;
input int    Magic        = 26012025;

CMT4Adapter Core;

int OnInit(){
   if(Symbol()!="BTCUSD"){ Print("Warning: spec targets BTCUSD"); }
   if(!Core.Create(Magic)){ Print("Core init failed: ", EA_LastError(0)); return(INIT_FAILED); }
   Print("Core version: ", EA_Version());
   return(INIT_SUCCEEDED);
}
void OnDeinit(const int){ Core.Destroy(); Comment(""); }

void OnTick(){
   if(!AutoTrading){ Comment("Paused (AutoTrading=false). Level=", Core.Level()); return; }

   int planned=0;
   if(Core.PlanIfSignal(planned)){
      // Place pending BuyStops per plan (one trade at a time is enforced by DLL and shell)
      for(int i=0;i<planned;i++){
         double entry, sl, tp, lots; int qual;
         if(!Core.GetPlan(i, entry, sl, tp, lots, qual)) continue;
         double useLots = LotSize; // fixed lots per spec
         int slip = 5;

         // ensure price > Ask for BuyStop
         if(entry <= Ask){ entry = NormalizeDouble(Ask + 10*Point, (int)MarketInfo(Symbol(),MODE_DIGITS)); }

         int ticket = OrderSend(Symbol(), OP_BUYSTOP, useLots, entry, slip, sl, tp,
                                "GC:"+IntegerToString(qual), Magic, 0, clrYellow);
         if(ticket<0) Print("OrderSend error: ", GetLastError());
         else EA_OnOrderPlaced(0, ticket, qual);
      }
   }

   // Optional: simple SL advisory hook (left no-op by core for now)
}

void OnTrade(){
   // reflect closures to core for level progression
   for(int i=OrdersHistoryTotal()-1;i>=0;i--){
      if(OrderSelect(i, SELECT_BY_POS, MODE_HISTORY)
         && OrderSymbol()==Symbol() && OrderMagicNumber()==Magic){
         bool byTP = (OrderClosePrice()==OrderTakeProfit());
         bool bySL = (OrderClosePrice()==OrderStopLoss());
         Core.OnClosed(OrderTicket(), byTP, bySL);
         break;
      }
   }
}
