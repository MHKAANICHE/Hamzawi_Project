#property strict

// Trade action constants
#define EA_NONE        0
#define EA_BUY         1
#define EA_SELL        2
#define EA_CLOSE_BUY   3
#define EA_CLOSE_SELL  4

#import "ea_core.dll"
   int     EA_CreateContext();
   void    EA_DestroyContext(int handle);
   int     EA_Init(int handle, string symbol, int magic, int digits, double point);
   void    EA_Reset(int handle);
   int     EA_OnTick(int handle, double bid, double ask, long time_epoch_sec, int hasOpenPosition, int &action_out);
   int     EA_PlanOrdersCount(int handle);
   int     EA_PlanOrderGet(int handle, int index, double &entry, double &sl, double &tp, double &lots, int &qual);
   void    EA_OnOrderPlaced(int handle, int ticket, int qual);
   void    EA_OnOrderFilled(int handle, int ticket, double fill_price);
   void    EA_OnOrderClosed(int handle, int ticket, int closed_by_tp, int closed_by_sl);
   int     EA_CurrentLevel(int handle);
   void    EA_ApplyLevel(int handle, int level);
   int     EA_AdviseSL(int handle, double current_price, double &new_sl_out, int &should_modify_out);
   void    EA_SetFlag(int handle, string key, int value);
   void    EA_SetParamDouble(int handle, string key, double value);
   string  EA_LastError(int handle);
   string  EA_Version();
#import

class CMT4Adapter {
   int m_h;
   int m_magic;
   
public:
   bool Create(int magic){
      m_magic = magic;
      m_h = EA_CreateContext();
      if(m_h<=0) return false;
      return (EA_Init(m_h, Symbol(), magic, (int)MarketInfo(Symbol(), MODE_DIGITS), Point)==1);
   }
   
   void Destroy(){ 
      if(m_h>0){ 
         EA_DestroyContext(m_h); 
         m_h=0; 
      } 
   }
   
   bool OnTick(int &action, double &price, double &sl, double &tp){
      int hasPos = hasOurTrades()?1:0;
      if(EA_OnTick(m_h, Bid, Ask, TimeCurrent(), hasPos, action)==1){
         if(action >= EA_BUY && action <= EA_CLOSE_SELL){
            // For now use basic price levels
            price = (action == EA_BUY) ? Ask : Bid;
            // TODO: Get SL/TP from DLL
            sl = 0;
            tp = 0;
            return true;
         }
      }
      return false;
   }
   
   string LastError(){ return EA_LastError(m_h); }
   string Version(){ return EA_Version(); }
   
private:
   bool hasOurTrades(){
      for(int i=OrdersTotal()-1;i>=0;--i){
         if(OrderSelect(i, SELECT_BY_POS, MODE_TRADES)
            && OrderSymbol()==Symbol()
            && OrderMagicNumber()==m_magic)
            return true;
      }
      return false;
   }
};
