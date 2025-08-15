## Important Stability Notice: Persistent Window Edge Case

This EA and DLL integration uses a persistent child window for GUI interaction. The workflow is robust and stable under normal usage:

- The child window appears and closes cleanly.
- Relaunching the EA does not cause errors.

**Edge Case Warning:**

If you close the parent MT4 window (the chart or terminal) before closing the child window, the child window becomes orphaned. Closing the orphaned child window in this state may cause MT4 to crash.

**User Guidance:**

- Always close the child window before closing the parent MT4 window.
- Avoid leaving orphaned child windows running after the parent is closed.

This is a known limitation of the persistent window approach. The risk is accepted for this integration, but users should be aware and avoid this scenario whenever possible.
# Version3: OOP WinAPI GUI Toolkit for MT4 EA
> **Note:** This project is always operated and maintained on GitHub. Please ensure all changes, builds, and documentation updates are performed via the GitHub repository for consistency and collaboration.

## ⚠️ Reliability-First Integration (August 2025)

- **Critical Constraint:** Only safe modal dialogs and simple controls are supported for MT4 DLL integration. Persistent windows, threads, and advanced controls are not supported to ensure platform stability.
- **Workflow:**
  1. Create HTML UI sketch using only supported elements (input, button, label).
  2. Use `auto_html_to_winapi.py` to detect changes and run `html_to_winapi.py` for conversion.
  3. Review validation report for unsupported features.
  4. Compile generated C++ code into DLL.
  5. EA calls DLL modal dialog functions (e.g., `ShowSafeInputDialog`).
- **Troubleshooting:** If the HTML or generated code includes unsupported features, the converter will warn and skip them. Only modal dialogs are guaranteed to work reliably in MT4.
- **Best Practice:** Always test for MT4 responsiveness and stability after each change. Prefer minimal, non-blocking UI.

## What Has Been Realized

- **OOP GUI Elements in C++ DLL**: All crucial WinAPI controls (Button, Edit, ComboBox, CheckBox, etc.) are implemented as reusable C++ classes with per-instance event handlers and value management.
- **Event-Driven Design**: Each GUI element supports its own event callbacks (e.g., onClick, onCheck, onSelect, onChange).
- **MT4 EA Integration**: The EA can call the DLL to show a native Windows GUI dialog, receive user input, and react to events.
- **32-bit DLL Build**: The DLL is built for 32-bit compatibility with MT4 using MinGW-w64.
- **String Encoding**: Proper conversion between MQL4 strings and WinAPI wide strings is handled.
- **Demo Dialog**: A working demo dialog with all controls and event routing is available.



## Integration, Testing, and Enhancement Plan

### 1. Integration
- End-to-end test: Run converter, generate C++ code, build DLL, verify GUI in MT4.
- AUTOGEN marker protection: Confirm manual code outside AUTOGEN regions is preserved.
- Event handler stubs: Ensure generated stubs are easy to implement.

### 2. Automated Testing
- Add Python unit tests for converter functions (ID registry, label pairing, validation report).
- Create sample HTML sketches (valid, edge cases, unsupported elements) and verify output/validation.
- Compile generated C++ code and run in test harness/demo EA.

### 3. Enhancements
- Integrate with C++ layout manager for automatic arrangement.
- Add support for more HTML attributes (tooltips, default values, disabled state).
- Allow user-defined mappings for custom HTML tags.
- Add advanced validation (accessibility, tab order, event handler completeness).
- Add CLI options for dry-run, verbose output, selective regeneration.

### 4. Documentation & Onboarding
- Expand README with integration guide, troubleshooting, FAQ.
- Provide minimal working example (HTML + C++ + EA).
- Continue improving inline code comments.

### 5. Continuous Improvement
- Encourage user feedback and feature suggestions.
- Tag releases and document changes in README.

### Usage

To convert an HTML UI sketch to C++ WinAPI code:

```bash
python3 library/html_to_winapi.py library/demo_interface.html library/demo_interface_winapi.cpp
```

This will update only the AUTOGEN region in the output C++ file, preserving any manual code outside the markers.
```bash
sudo apt-get update
sudo apt-get install mingw-w64
sudo apt-get install gcc-mingw-w64-i686 g++-mingw-w64-i686
which i686-w64-mingw32-g++
i686-w64-mingw32-g++ --version
i686-w64-mingw32-g++ -shared -o Version3/library/full_demo_interface.dll Version3/library/full_demo_interface_winapi.cpp -static -mwindows
```
### Features

- Persistent, atomic ID registry for WinAPI controls (JSON file)
- Robust label/input pairing and validation
- Layout and nesting validation with fallback logic
- Event handler registry and stub generation
- Unsupported element feedback and reporting
- Partial regeneration with AUTOGEN marker protection
- Comprehensive validation reporting (warnings, errors, unsupported elements)

### Validation Report

After each run, a summary report is printed showing:
- Warnings (e.g., missing labels, excessive container depth, event handler conflicts)
- Errors (e.g., duplicate IDs)
- Unsupported HTML elements

If no issues are found, "No validation issues detected." will be shown.

### Troubleshooting

- If you see "ERROR: Missing or altered AUTOGEN markers", restore the markers in your C++ file.
- For duplicate IDs, check your HTML for repeated id attributes.
- For unsupported elements, use only: label, input, select, ul, div, progress, button.

### Extending the Workflow

- Add new supported HTML tags and their C++ mappings in `html_to_winapi.py`.
- Extend validation_report for new checks.
- Customize layout attribute parsing in `get_layout_attrs()`.


- **Layout Manager**: Implement a simple layout manager class in C++ to arrange GUI elements (vertical/horizontal stacking, spacing, etc.).
    - The EA should only call the layout manager, not individual GUI elements.
    - The layout manager should manage all controls and their layout.
- **Dashboard Button**: Add a single button on the chart ("Dashboard") that reopens the interface if the user closes it.
- **Backtest Detection**: Ensure the GUI does not appear during backtesting (only in live/demo trading).
- **EA Structure**: Refactor the EA so that it only contains high-level logic (OnTick: check entry, check exit, etc.), with no direct GUI construction or function calls for GUI elements.
- **Further GUI Elements**: Complete OOP/event support for any remaining controls (ListBox, Radio, Slider, GroupBox, Tab, ProgressBar).
- **Documentation**: Add usage instructions and code comments for maintainability.
##

he best approach is to refactor each GUI element class to support:

Its own event handler (e.g., onClick, onChange, onSelect, etc.)
Initial value and state
OOP-style encapsulation for both rendering and behavior
This means:

Each element exposes methods to set/get value, and to attach a callback for its events.
The dialog procedure delegates WM_COMMAND and other messages to the relevant element’s handler.
1. OOP GUI Element Design
Base Class (GuiElement)

Stores HWND, position, size, ID, and parent.
Has virtual methods: Create(), HandleMessage(), SetValue(), GetValue(), etc.
Supports attaching event handlers (callbacks) for actions (e.g., onClick, onChange).
Derived Classes

GuiButton, GuiEdit, GuiComboBox, GuiCheckBox, etc.
Each class implements its own creation, value management, and event handling.
Each class can have its own event/callback signature (e.g., onClick, onTextChange, onSelect).
2. Event Handling
Each element can register a callback (function pointer, lambda, or std::function).
The dialog procedure (DialogProc) routes Windows messages (WM_COMMAND, WM_NOTIFY, etc.) to the correct element by ID.
The element’s HandleMessage() method is called, which triggers the appropriate callback.
3. Value Management
Each element provides SetValue() and GetValue() for its state (text, checked, selected, etc.).
The dialog can query or set values for any element at any time.
4. Dialog Layout
Elements are stored in a container (e.g., std::vector<GuiElement*>).
Each element has its own position and size, set at creation.
The dialog can be laid out programmatically or via a simple layout manager.
5. Example Usage
6. Dialog Procedure
On WM_COMMAND, find the element by ID and call its HandleMessage().
The element triggers its callback if set.
7. Extensibility
New controls can be added by subclassing GuiElement.
Custom behaviors and events are easy to add per element.
8. Demo Dialog
Create a dialog with all elements, each with its own event handler.
Show how to read/write values and respond to user actions.
Summary:
This approach gives you a modular, maintainable, and extensible GUI toolkit for all future MT4/MT5 DLLs, with true OOP and per-element event handling.
Step 1: OOP Button Element with Event Handler

I will create a new GuiButton class that:

Inherits from GuiElement
Supports setting/getting its label
Allows attaching an onClick event handler (using std::function<void()>)
Handles its own click event in the dialog
Let’s begin by implementing and documenting this class in your GuiElements.hpp.

GuiElements.hpp+18-25
The OOP GuiButton class is now implemented with:

An onClick event handler (settable via std::function<void()>)
Value management (SetText, GetText)
Its own message handler for button clicks
The OOP GuiEdit (text input) element is now implemented with:

Value management (SetText, GetText)
An onChange event handler (triggered when the text changes)
Its own message handler for text change events
Next, I will proceed to implement the OOP GuiComboBox (dropdown) element with value management and event support. Let me know if you want to continue!
The OOP GuiComboBox (dropdown) element is now implemented with:

Value management (AddItem, SetCurSel, GetCurSel)
An onSelect event handler (triggered when the selection changes)
Its own message handler for selection change events
Next, I will proceed to implement the OOP GuiCheckBox element with value management and an onCheck event handler. Let me know if you want to continue!
GuiCheckBox has been refactored as a full OOP class with value management (checked/unchecked), an onCheck event handler, and SetChecked/GetChecked methods. You can now use it with per-instance event handling and state.

Ready to proceed with the next GUI element or further integration.
## Next Steps
0. reusable WinAPI GUI toolkit - the crucial GUI elements:

    Labels (static text)
    Text input fields (including a password field)
    Multiple buttons (OK, Buy, Sell, Cancel, Save, etc.)
    A dropdown/combobox
    A list box
    A checkbox
    A radio button
    A slider/trackbar
    A group box
    A tab control
    A progress bar

Based on your README.md and the current state of your code, here’s what still needs to be done for the GUI elements to complete your OOP WinAPI toolkit:

1. OOP Refactor & Event Support (remaining elements):

Radio Button: Add value management (selected state), onSelect event handler, and message handling.
Slider/Trackbar: Add value management (position), onChange event handler, and message handling.
Group Box: OOP refactor (usually no events, but should support text and layout).
Tab Control: OOP refactor, value management (selected tab), onSelect event handler.
Progress Bar: OOP refactor, value management (progress), and update methods.
2. Documentation:

Add code comments and usage instructions for each element.
3. (Optional) Label/Static Text:

Implement as a simple OOP class for completeness (no events, just text).
Once these are done, your GUI toolkit will have full OOP/event-driven support for all crucial WinAPI controls. Let me know if you want to proceed with the next element!

1. Bootstrap the layout manager class in C++.
2. Refactor the DLL entry point to expose only the layout manager to the EA.
3. Add chart button logic and backtest detection in the EA.
4. Refactor EA to OnTick-only structure, with no direct GUI code.
5. Finalize and document all GUI elements and event handlers.

---

**Contact:** For questions or further development, see the main project README or contact the developer.
