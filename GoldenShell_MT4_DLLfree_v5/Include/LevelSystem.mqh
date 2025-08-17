#property strict
#ifndef __LEVELSYSTEM_MQH__
#define __LEVELSYSTEM_MQH__

/*
 Hardcoded table per client requirements:
 Levels 1..6:  1 part, lot=0.01, RR = [2],[3],[4],[5],[6],[7]
 Levels 7..10: 2 parts, lot per part = 0.01 (total 0.02), RR combos per spec
  7: [1,7]
  8: [3,7]
  9: [5,7]
 10: [7,7]
 11..12: 3 parts, 0.01 each (total 0.03): [3,7,7], [5,7,7]
 13..14: 4 parts, 0.01 each (total 0.04): [1,7,7,7], [5,7,7,7]
 15..16: 5 parts, 0.01 each (total 0.05): [2,7,7,7,7], [7,7,7,7,7]
 17:     6 parts, 0.01 each (0.06): [5,7,7,7,7,7]
 18:     7 parts, 0.01 each (0.07): [4,7,7,7,7,7,7]
 19:     9 parts, 0.01 each (0.09? Spec says 0.08; we will keep parts=8 for 0.08):
         Level 19 (0.08): 8 parts: [4,7,7,7,7,7,7,7]
 20:     9 parts, 0.01 each (0.09): [5,7,7,7,7,7,7,7,7]
 21:     10 parts (0.10): [7 x10]
 22:     12 parts (0.12): [3 + 7x11]
 23:     14 parts (0.14): [1 + 7x13]
 24:     16 parts (0.16): [1 + 7x15]
 25:     18 parts (0.18): [3 + 7x17]
*/

// Fill arrays rr[] and lots[] for a given level. Return number of parts.
int Level_GetParts(int level, double lotStart, double &rr[], double &lots[])
{
   ArrayInitialize(rr, 0.0);
   ArrayInitialize(lots, 0.0);

   int parts=0;
   switch(level)
   {
      case 1:  parts=1;  rr[0]=2; lots[0]=lotStart; break;
      case 2:  parts=1;  rr[0]=3; lots[0]=lotStart; break;
      case 3:  parts=1;  rr[0]=4; lots[0]=lotStart; break;
      case 4:  parts=1;  rr[0]=5; lots[0]=lotStart; break;
      case 5:  parts=1;  rr[0]=6; lots[0]=lotStart; break;
      case 6:  parts=1;  rr[0]=7; lots[0]=lotStart; break;

      case 7:  parts=2;  rr[0]=1; rr[1]=7; lots[0]=lotStart; lots[1]=lotStart; break;
      case 8:  parts=2;  rr[0]=3; rr[1]=7; lots[0]=lotStart; lots[1]=lotStart; break;
      case 9:  parts=2;  rr[0]=5; rr[1]=7; lots[0]=lotStart; lots[1]=lotStart; break;
      case 10: parts=2;  rr[0]=7; rr[1]=7; lots[0]=lotStart; lots[1]=lotStart; break;

      case 11: parts=3;  rr[0]=3; rr[1]=7; rr[2]=7;
               lots[0]=lots[1]=lots[2]=lotStart; break;
      case 12: parts=3;  rr[0]=5; rr[1]=7; rr[2]=7;
               lots[0]=lots[1]=lots[2]=lotStart; break;

      case 13: parts=4;  rr[0]=1; for(int i=1;i<4;i++) rr[i]=7;
               for(int j=0;j<4;j++) lots[j]=lotStart; break;
      case 14: parts=4;  rr[0]=5; for(int i=1;i<4;i++) rr[i]=7;
               for(int j=0;j<4;j++) lots[j]=lotStart; break;

      case 15: parts=5;  rr[0]=2; for(int i=1;i<5;i++) rr[i]=7;
               for(int j=0;j<5;j++) lots[j]=lotStart; break;
      case 16: parts=5;  for(int i=0;i<5;i++) rr[i]=7;
               for(int j=0;j<5;j++) lots[j]=lotStart; break;

      case 17: parts=6;  rr[0]=5; for(int i=1;i<6;i++) rr[i]=7;
               for(int j=0;j<6;j++) lots[j]=lotStart; break;

      case 18: parts=7;  rr[0]=4; for(int i=1;i<7;i++) rr[i]=7;
               for(int j=0;j<7;j++) lots[j]=lotStart; break;

      case 19: parts=8;  rr[0]=4; for(int i=1;i<8;i++) rr[i]=7;  // total lots = 8*0.01 = 0.08
               for(int j=0;j<8;j++) lots[j]=lotStart; break;

      case 20: parts=9;  rr[0]=5; for(int i=1;i<9;i++) rr[i]=7;
               for(int j=0;j<9;j++) lots[j]=lotStart; break;

      case 21: parts=10; for(int i=0;i<10;i++) rr[i]=7;
               for(int j=0;j<10;j++) lots[j]=lotStart; break;

      case 22: parts=12; rr[0]=3; for(int i=1;i<12;i++) rr[i]=7;
               for(int j=0;j<12;j++) lots[j]=lotStart; break;

      case 23: parts=14; rr[0]=1; for(int i=1;i<14;i++) rr[i]=7;
               for(int j=0;j<14;j++) lots[j]=lotStart; break;

      case 24: parts=16; rr[0]=1; for(int i=1;i<16;i++) rr[i]=7;
               for(int j=0;j<16;j++) lots[j]=lotStart; break;

      case 25: parts=18; rr[0]=3; for(int i=1;i<18;i++) rr[i]=7;
               for(int j=0;j<18;j++) lots[j]=lotStart; break;

      default: parts=0; break;
   }
   return parts;
}

#endif
