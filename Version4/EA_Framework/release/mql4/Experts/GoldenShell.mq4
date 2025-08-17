#property strict
#include <MT4Adapter.mqh>

// ---- Inputs (client spec) ----
input double LotSize      = 0.01;   // fixed per spec, used per planned order
input int    BaseSL       = 10000;  // points (for UI info only; logic in DLL)
input bool   AutoTrading  = true;
input int    Magic        = 26012025;

CMT4Adapter Core;

int OnInit(){
   if(!Core.Create(Magic)){
      Print("Core init failed: ", Core.LastError());
      return(INIT_FAILED);
   }
   Print("Core version: ", Core.Version());
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason){
   Core.Destroy();
}

void OnTick(){
   int action=0; double price=0, sl=0, tp=0;
   if(Core.OnTick(action, price, sl, tp)){
      if(!AutoTrading) { Comment("Signal: ", action, " (auto trading OFF)"); return; }

      // Exécution minimale (à adapter suivant broker)
      if(action==EA_BUY){
         trade(OP_BUY, price, sl, tp);
      } else if(action==EA_SELL){
         trade(OP_SELL, price, sl, tp);
      } else if(action==EA_CLOSE_BUY){
         close_by_type(OP_BUY);
      } else if(action==EA_CLOSE_SELL){
         close_by_type(OP_SELL);
      }
   }
}

void trade(int type, double price, double sl, double tp){
   int slip = 5;
   int ticket = OrderSend(Symbol(), type, LotSize, price, slip, sl, tp, "EA_Core", Magic, 0, clrDodgerBlue);
   if(ticket<0) Print("OrderSend error: ", GetLastError());
}

void close_by_type(int type){
   for(int i=OrdersTotal()-1; i>=0; --i){
      if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES) && OrderSymbol()==Symbol() && OrderMagicNumber()==Magic && OrderType()==type){
         bool ok=false;
         if(type==OP_BUY) ok=OrderClose(OrderTicket(), OrderLots(), Bid, 5, clrRed);
         else if(type==OP_SELL) ok=OrderClose(OrderTicket(), OrderLots(), Ask, 5, clrRed);
         if(!ok) Print("OrderClose error: ", GetLastError());
      }
   }
}
