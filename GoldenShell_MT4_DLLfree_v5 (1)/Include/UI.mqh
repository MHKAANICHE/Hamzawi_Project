#property strict
#ifndef __UI_MQH__
#define __UI_MQH__

#include "Utils.mqh"
#include "Indicators.mqh"

// GUI elements
string PANEL_NAME   = "GS_PANEL";
string TXT_STATUS   = "GS_TXT_STATUS";
string BTN_MODE     = "GS_BTN_MODE";
string BTN_APPLY    = "GS_BTN_APPLY";
string BTN_L_PREFIX = "GS_BTN_L_";

void UI_Create(bool show, int currentLevel, int plannedLevel, int mode)
{
   // Fixed panel at bottom-right with background box
   int x=00, y=00, w=210, h=130;
   string chartID = PANEL_NAME;

   ObjectCreate(0, PANEL_NAME, OBJ_LABEL, 0, 0, 0);
   ObjectSetText(PANEL_NAME, "", 10, "Arial", clrNONE);
   ObjectSet(PANEL_NAME, OBJPROP_CORNER, 0); // right-top
   ObjectSet(PANEL_NAME, OBJPROP_XDISTANCE, 10);
   ObjectSet(PANEL_NAME, OBJPROP_YDISTANCE, 30);

   // status text
   ObjectCreate(0, TXT_STATUS, OBJ_LABEL, 0, 0, 0);
   ObjectSet(TXT_STATUS, OBJPROP_CORNER, 0);
   ObjectSet(TXT_STATUS, OBJPROP_XDISTANCE, 14);
   ObjectSet(TXT_STATUS, OBJPROP_YDISTANCE, 34);
   ObjectSetText(TXT_STATUS, "", 9, "Arial", clrWhite);

   // mode button (Force vs Plan)
   ObjectCreate(0, BTN_MODE, OBJ_BUTTON, 0, 0, 0);
   ObjectSet(BTN_MODE, OBJPROP_CORNER, 0);
   ObjectSet(BTN_MODE, OBJPROP_XDISTANCE, 14);
   ObjectSet(BTN_MODE, OBJPROP_YDISTANCE, 90);
   ObjectSet(BTN_MODE, OBJPROP_XSIZE, 80);
   ObjectSet(BTN_MODE, OBJPROP_YSIZE, 18);
   ObjectSetText(BTN_MODE, mode==0?"Force":"Plan", 9, "Arial", clrBlack);

   // apply button (apply planned→active now)
   ObjectCreate(0, BTN_APPLY, OBJ_BUTTON, 0, 0, 0);
   ObjectSet(BTN_APPLY, OBJPROP_CORNER, 0);
   ObjectSet(BTN_APPLY, OBJPROP_XDISTANCE, 100);
   ObjectSet(BTN_APPLY, OBJPROP_YDISTANCE, 90);
   ObjectSet(BTN_APPLY, OBJPROP_XSIZE, 80);
   ObjectSet(BTN_APPLY, OBJPROP_YSIZE, 18);
   ObjectSetText(BTN_APPLY, "Apply", 9, "Arial", clrBlack);

   // quick level buttons L1..L6 only (to keep compact), user can set higher via planned input or later extension
   int ybtn=115, xbtn=14;
   for(int L=1; L<=6; L++)
   {
      string name = BTN_L_PREFIX + IntegerToString(L);
      ObjectCreate(0, name, OBJ_BUTTON, 0, 0, 0);
      ObjectSet(name, OBJPROP_CORNER, 0);
      ObjectSet(name, OBJPROP_XDISTANCE, xbtn);
      ObjectSet(name, OBJPROP_YDISTANCE, ybtn);
      ObjectSet(name, OBJPROP_XSIZE, 24);
      ObjectSet(name, OBJPROP_YSIZE, 16);
      ObjectSetText(name, IntegerToString(L), 8, "Arial", clrBlack);
      xbtn += 26;
   }

   if(!show)
   {
      ObjectSetInteger(0, PANEL_NAME, OBJPROP_HIDDEN, true);
      ObjectSetInteger(0, TXT_STATUS, OBJPROP_HIDDEN, true);
      ObjectSetInteger(0, BTN_MODE, OBJPROP_HIDDEN, true);
      ObjectSetInteger(0, BTN_APPLY, OBJPROP_HIDDEN, true);
      for(int L=1; L<=6; L++) ObjectSetInteger(0, BTN_L_PREFIX+IntegerToString(L), OBJPROP_HIDDEN, true);
   }
}

void UI_Destroy()
{
   // delete everything
   string names[10];
   int k=0;
   names[k++]=PANEL_NAME; names[k++]=TXT_STATUS; names[k++]=BTN_MODE; names[k++]=BTN_APPLY;
   for(int L=1; L<=6; L++) names[k++]=BTN_L_PREFIX+IntegerToString(L);

   for(int i=0;i<k;i++)
      if(ObjectFind(0, names[i])>=0) ObjectDelete(0, names[i]);
}

void UI_Update(SignalInfo &sig, int currentLevel, int plannedLevel, int mode)
{
   if(ObjectFind(0, TXT_STATUS)<0) return;
   string s = StringFormat("GS | L:%d  Plan:%s  Mode:%s\nDir:%s  Entry:%.2f  Close:%.2f",
                           currentLevel, plannedLevel>0?IntegerToString(plannedLevel):"-",
                           mode==0?"Force":"Plan",
                           sig.dir>0?"BUY":(sig.dir<0?"SELL":"-"),
                           sig.entryPrice, sig.baseClose);
   ObjectSetText(TXT_STATUS, s, 9, "Arial", clrWhite);
}

// Return true if consumed the event and updated variables
bool UI_HandleEvent(const int id, const long lparam, const double dparam, const string sparam,
                    int &currentLevel, int &plannedLevel, int &mode)
{
   if(id!=CHARTEVENT_OBJECT_CLICK) return false;
   if(sparam==BTN_MODE)
   {
      mode = (mode==0?1:0);
      ObjectSetText(BTN_MODE, mode==0?"Force":"Plan", 9, "Arial", clrBlack);
      return true;
   }
   if(sparam==BTN_APPLY)
   {
      if(plannedLevel>0) { currentLevel = plannedLevel; plannedLevel=0; }
      return true;
   }
   // Level buttons
   for(int L=1; L<=6; L++)
   {
      string name = BTN_L_PREFIX+IntegerToString(L);
      if(sparam==name)
      {
         // set planned to this quick level
         plannedLevel = L;
         return true;
      }
   }
   return false;
}

#endif
