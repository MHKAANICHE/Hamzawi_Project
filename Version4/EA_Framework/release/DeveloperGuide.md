# Developer Guide

## Immutables (Core Team)
- Signatures API dans `core/include/ea_api.h`
- Convention d'appel `__stdcall`, types simples (int/double) uniquement
- Cycle de vie: `EA_CreateContext` → `EA_Init` → `EA_OnTick` → `EA_DestroyContext`
- CI (GitHub Actions) et Toolchain MinGW

## Flexibles (Personnalisables)
- Logic strategy dans `core/src/*.cpp` (ne pas casser l'API)
- Paramètres runtime via `EA_SetParamDouble` / `EA_SetFlag`
- Politique d'exécution ordres dans `GoldenShell.mq4`

## Cycle Dev
1. Implémenter la logique core (C++)
2. `cmake` build + tests locaux
3. Cross-compile DLL Windows
4. Test MT4 (démo) avec GoldenShell
5. PR → CI vert → Tag release

## Ajout d'un signal
- Implémentez dans `EA_OnTick` (ou factorisez dans un module)
- Renvoyez `EA_BUY / EA_SELL` + SL/TP calculés côté DLL
- Shell MQL4 reste bête et déterministe (pas d'algorithmes heavy côté MQL4)

## Debug
- Tracer côté DLL → convertir en états lisibles via `EA_GetState` + `Comment()` côté MQL4
- En cas d'erreur `EA_LastError(handle)` fournit le dernier message

## Roadmap interne
- Ajouter Risk/Money management dans DLL (lot sizing, RR)
- Ajouter indicateurs (SAR/MA/…)
- Exporter plus d'états (pour UI MQL4 sans logique)
