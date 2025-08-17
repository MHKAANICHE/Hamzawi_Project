# EA_Framework (Version4)

Framework pour développer des EA MT4 avec 80% de logique en DLL C++ (stable, testable), et un shell MQL4 minimal (UI/exec).

## Build rapide (Codespaces)

```bash
cmake -S core -B build_linux -DCMAKE_BUILD_TYPE=Release
cmake --build build_linux --config Release
bash scripts/build_win.sh
bash scripts/package_release.sh
```

## Intégration MT4

* Copier `build_win/libea_core.dll` → `<MT4>/MQL4/Libraries/ea_core.dll`
* Copier `mql4/Include/MT4Adapter.mqh` → `<MT4>/MQL4/Include/`
* Copier `mql4/Experts/GoldenShell.mq4` → `<MT4>/MQL4/Experts/`
* Compiler `GoldenShell.mq4` dans MetaEditor, attacher à un chart (compte démo).

## Architecture

* **core/** : logique stratégie + état + API C exportée (DLL)
* **mql4/** : wrapping fin, exécution ordres, UI basique

## Licence

Internal / Client Delivery
