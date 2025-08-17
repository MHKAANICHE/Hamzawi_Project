#property strict

// ================== Inputs (user-configurable) ==================
extern double   LotSizeStart    = 0.01;
extern int      BaseSLPips      = 10000;     // also Golden Candle size in points/pips (broker points)
extern int      EntryPercent    = 35;        // % of base size used to offset entry from baseClose
extern int      Slippage        = 3;
extern int      MagicNumber     = 26012025;

extern double   SAR_Step        = 0.001;
extern double   SAR_Max         = 0.2;

extern int      FastMA_Period   = 1;
extern int      FastMA_Shift    = 0;
extern int      SlowMA_Period   = 3;
extern int      SlowMA_Shift    = 1;

extern bool     ShowOverlay     = true;
extern bool     DebugPrint      = false;

// ============== Includes ==================
#include <stdlib.mqh>
#include <Utils.mqh>
#include <Indicators.mqh>
#include <GoldenCandle.mqh>
#include <LevelSystem.mqh>
#include <OrderManager.mqh>
#include <UI.mqh>

// ============== State ==================
int g_currentLevel = 1;          // active money-management level
int g_plannedLevel = 0;          // 0=none, or 1..25
int g_planningMode = 0;          // 0 = ForceClose+Reopen, 1 = PlanNext
SignalInfo g_lastSignal;

int OnInit()
{
   if(DebugPrint) Print("GoldenShell init");
   g_currentLevel = ClampLevel(LoadLevelFromGlobal("GS_active_level", 1));
   g_plannedLevel = ClampLevel(LoadLevelFromGlobal("GS_planned_level", 0));
   UI_Create(ShowOverlay, g_currentLevel, g_plannedLevel, g_planningMode);
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
   UI_Destroy();
}

// Main tick
void OnTick()
{
   // Compute signal
   SignalInfo sig;
   if(!ComputeSignal(sig, SAR_Step, SAR_Max, FastMA_Period, FastMA_Shift, SlowMA_Period, SlowMA_Shift, BaseSLPips, EntryPercent))
      return;

   g_lastSignal = sig;

   // Cancel opposite pending when reversal happens
   OM_CancelOppositePending(sig.dir, MagicNumber);

   // Determine which level to use
   int useLevel = (g_plannedLevel>0 && g_planningMode==1) ? g_plannedLevel : g_currentLevel;

   // If there are open/pending orders already, manage and exit early
   int act = OM_ActiveOrdersCount(MagicNumber);
   if(act>0)
   {
      // If planning mode is ForceClose+Reopen and planned level is set, force close and re-open
      if(g_plannedLevel>0 && g_planningMode==0 && IsLiveTrading())
      {
         if(DebugPrint) Print("Force close all then reopen at planned level ", g_plannedLevel);
         OM_CloseAllForMagic(MagicNumber);
         g_currentLevel = g_plannedLevel;
         g_plannedLevel = 0;
         SaveLevelToGlobal("GS_active_level", g_currentLevel);
         SaveLevelToGlobal("GS_planned_level", g_plannedLevel);
      }
      else
      {
         // nothing to do until orders resolve
         UI_Update(sig, g_currentLevel, g_plannedLevel, g_planningMode);
         return;
      }
   }

   // If no active orders, evaluate placement
   // Entry price based on signal direction
   double entry = sig.entryPrice;
   double sl    = (sig.dir>0) ? entry - PointsToPrice(BaseSLPips) : entry + PointsToPrice(BaseSLPips);

   // fetch level parts (RR and Lots arrays)
   double rr[25];    // reuse as buffer
   double lots[25];
   int parts = Level_GetParts(useLevel, LotSizeStart, rr, lots);
   if(parts<=0) { UI_Update(sig, g_currentLevel, g_plannedLevel, g_planningMode); return; }

   // If planning mode = PlanNext, do NOT place now (only cache; UI shows planned)
   if(g_plannedLevel>0 && g_planningMode==1)
   {
      // Just show UI; placement will happen after current trade resolves
      UI_Update(sig, g_currentLevel, g_plannedLevel, g_planningMode);
      return;
   }

   // Place batch pending(s) (split orders allowed but as one atomic batch)
   string cmtPrefix = StringFormat("GS L%d", useLevel);
   bool placed = OM_PlaceBatchPending(sig.dir, entry, sl, rr, lots, parts, MagicNumber, Slippage, cmtPrefix, DebugPrint);
   if(placed)
   {
      // If we were force-jumping, we consumed the planned level
      if(g_plannedLevel>0 && g_planningMode==0)
      {
         g_currentLevel = g_plannedLevel;
         g_plannedLevel = 0;
      }
      SaveLevelToGlobal("GS_active_level", g_currentLevel);
      SaveLevelToGlobal("GS_planned_level", g_plannedLevel);
   }

   UI_Update(sig, g_currentLevel, g_plannedLevel, g_planningMode);
}

// UI events (buttons)
void OnChartEvent(const int id,         // Event ID
                  const long lparam,    // parameter
                  const double dparam,  // parameter
                  const string sparam)  // parameter
{
   if(!UI_HandleEvent(id, lparam, dparam, sparam, g_currentLevel, g_plannedLevel, g_planningMode))
      return;

   // Persist if changed
   SaveLevelToGlobal("GS_active_level", g_currentLevel);
   SaveLevelToGlobal("GS_planned_level", g_plannedLevel);
}