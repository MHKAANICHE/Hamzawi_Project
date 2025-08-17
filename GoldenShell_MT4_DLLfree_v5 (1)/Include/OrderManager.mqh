#property strict
#ifndef __ORDERMANAGER_MQH__
#define __ORDERMANAGER_MQH__

#include "Utils.mqh"

// Adjust SL/TP if too close (error 130 prevention)
void OM_AdjustStopsFor130(int type,double &sl,double &tp,double entry)
{
   int stoplvl = (int)MarketInfo(Symbol(), MODE_STOPLEVEL);
   double stopDist = stoplvl * Point;

   if(type==OP_BUYSTOP)
   {
      // SL must be below entry by stopDist
      if(entry - sl < stopDist) sl = entry - stopDist;
      // TP must be above entry by stopDist
      if(tp - entry < stopDist) tp = entry + stopDist;
   }
   else if(type==OP_SELLSTOP)
   {
      if(sl - entry < stopDist) sl = entry + stopDist;
      if(entry - tp < stopDist) tp = entry - stopDist;
   }

   sl = NormalizeDouble(sl, Digits);
   tp = NormalizeDouble(tp, Digits);
}

// Count active orders for this EA
int OM_ActiveOrdersCount(int magic)
{
   return CountOrdersForMagic(magic);
}

// Delete opposite pending when reversal happens
void OM_CancelOppositePending(int direction,int magic)
{
   for(int i=OrdersTotal()-1; i>=0; i--)
   {
      if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
      if(OrderSymbol()!=Symbol() || OrderMagicNumber()!=magic) continue;

      if(direction>0 && (OrderType()==OP_SELLSTOP || OrderType()==OP_SELLLIMIT))
         OrderDelete(OrderTicket());
      if(direction<0 && (OrderType()==OP_BUYSTOP || OrderType()==OP_BUYLIMIT))
         OrderDelete(OrderTicket());
   }
}

// Place N split pendings atomically (one batch). Returns true if at least one sent OK.
bool OM_PlaceBatchPending(int direction, double entry, double slBase, double &rr[], double &lots[], int parts,
                          int magic, int slippage, string commentPrefix, bool debugPrint=false)
{
   if(parts<=0) return false;
   if(CountOrdersForMagic(magic)>0) return false; // ensure no previous orders

   bool any=false;
   int type = (direction>0)?OP_BUYSTOP:OP_SELLSTOP;

   for(int i=0;i<parts;i++)
   {
      double tp = (direction>0) ? (entry + rr[i]*PointsToPrice(BaseSLPips)) 
                                : (entry - rr[i]*PointsToPrice(BaseSLPips));
      double sl = slBase;
      OM_AdjustStopsFor130(type, sl, tp, entry);

      string cmt = StringFormat("%s part#%d RR=%.1f", commentPrefix, i+1, rr[i]);
      int ticket = OrderSend(Symbol(), type, lots[i], entry, slippage, sl, tp, cmt, magic, 0, clrDodgerBlue);
      if(ticket<0)
      {
         int err=GetLastError();
         if(debugPrint) Print("OrderSend failed part ",i+1," err=",err);
      }
      else
      {
         any=true;
         if(debugPrint) Print("open #", ticket, " ", (direction>0?"buy":"sell"), " stop ", lots[i], " at ", entry,
                              " sl: ", sl, " tp: ", tp, " ok");
      }
   }
   return any;
}

// Close all for magic
void OM_CloseAllForMagic(int magic)
{
   CloseAllForMagic(magic);
}

#endif
