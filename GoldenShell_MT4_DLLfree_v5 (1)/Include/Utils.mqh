#property strict
#ifndef __UTILS_MQH__
#define __UTILS_MQH__

// Helper: is live trading (not tester)
bool IsLiveTrading()
{
   return(!IsTesting());
}

double PointsToPrice(int pts)
{
   return(pts * Point);
}

// Clamp level to [0..25]
int ClampLevel(int L)
{
   if(L<0) return 0;
   if(L>25) return 25;
   return L;
}

// Globals persistency
int LoadLevelFromGlobal(string key, int def)
{
   if(GlobalVariableCheck(key)) return (int)GlobalVariableGet(key);
   return def;
}

void SaveLevelToGlobal(string key, int val)
{
   GlobalVariableSet(key, val);
}

// Count orders
int CountOrdersForMagic(int magic)
{
   int cnt=0;
   for(int i=0;i<OrdersTotal();i++)
   {
      if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
      if(OrderSymbol()!=Symbol()) continue;
      if(OrderMagicNumber()!=magic) continue;
      cnt++;
   }
   return cnt;
}

// Close everything for magic
void CloseAllForMagic(int magic)
{
   // Market positions
   for(int i=OrdersTotal()-1; i>=0; i--)
   {
      if(!OrderSelect(i, SELECT_BY_POS, MODE_TRADES)) continue;
      if(OrderSymbol()!=Symbol() || OrderMagicNumber()!=magic) continue;

      if(OrderType()==OP_BUY || OrderType()==OP_SELL)
      {
         double closePrice = (OrderType()==OP_BUY) ? Bid : Ask;
         bool ok = OrderClose(OrderTicket(), OrderLots(), closePrice, 5, clrRed);
      }
   }
   // Pendings
   for(int j=OrdersTotal()-1; j>=0; j--)
   {
      if(!OrderSelect(j, SELECT_BY_POS, MODE_TRADES)) continue;
      if(OrderSymbol()!=Symbol() || OrderMagicNumber()!=magic) continue;

      if(OrderType()==OP_BUYSTOP || OrderType()==OP_SELLSTOP || OrderType()==OP_BUYLIMIT || OrderType()==OP_SELLLIMIT)
      {
         bool ok2 = OrderDelete(OrderTicket());
      }
   }
}

#endif
