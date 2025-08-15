import sys, os, json

# Validation report structure
validation_report = {
    'warnings': [],
    'errors': [],
    'unsupported': set(),
}
# Unsupported element feedback and reporting
supported_tags = {'label', 'input', 'select', 'ul', 'div', 'progress', 'button'}
ignored_elements = []
for elem in soup.find_all(True):
    if elem.name not in supported_tags:
        ignored_elements.append(elem.name)
        validation_report['unsupported'].add(elem.name)
if ignored_elements:
    validation_report['warnings'].append(
        f"Ignored/unsupported HTML elements found: {set(ignored_elements)}. Suggestion: Use only supported elements: label, input, select, ul (listbox), div (groupbox/tabcontrol), progress, button."
    )
#!/usr/bin/env python3
"""
html_to_winapi.py: Convert standard HTML sketch to C++ OOP WinAPI GUI code

Usage:
    python3 html_to_winapi.py <input_html> [output_cpp]

Features:
    - Persistent, atomic ID registry for WinAPI controls (JSON file)
    - Robust label/input pairing and validation
    - Layout and nesting validation with fallback logic
    - Event handler registry and stub generation
    - Unsupported element feedback and reporting
    - Partial regeneration with AUTOGEN marker protection
    - Comprehensive validation reporting (warnings, errors, unsupported elements)

How it works:
    1. Parses the HTML UI sketch using BeautifulSoup
    2. Maps HTML elements to C++ WinAPI GUI classes
    3. Assigns persistent IDs and validates layout, labels, and events
    4. Aggregates all validation issues and prints a summary report
    5. Updates only the AUTOGEN region in the output C++ file, preserving manual code

Extension points:
    - Add new supported HTML tags and their C++ mappings in supported_tags and main loop
    - Extend validation_report for new checks
    - Customize layout attribute parsing in get_layout_attrs()

See README.md for more details and examples.
"""
from bs4 import BeautifulSoup

import sys, os, json


# Registry file for persistent WinAPI control IDs
REGISTRY_FILE = 'winapi_id_registry.json'

def load_registry():
    """Load persistent ID registry from JSON file."""
    if os.path.exists(REGISTRY_FILE):
        with open(REGISTRY_FILE, 'r') as f:
            return json.load(f)
    return {}


def save_registry(reg):
    """Save persistent ID registry to JSON file."""
    with open(REGISTRY_FILE, 'w') as f:
        json.dump(reg, f, indent=2)

def update_cpp_file(output_path, new_code):
    """
    Update only the AUTOGEN region in the output C++ file, preserving manual code outside markers.
    Aborts if markers are missing or altered.
    """
    autogen_start = '// AUTOGEN START'
    autogen_end = '// AUTOGEN END'
    if not os.path.exists(output_path):
        with open(output_path, 'w') as f:
            f.write(f'{autogen_start}\n{new_code}\n{autogen_end}\n')
        return
    with open(output_path, 'r') as f:
        content = f.read()
    start_idx = content.find(autogen_start)
    end_idx = content.find(autogen_end)
    if start_idx == -1 or end_idx == -1 or start_idx > end_idx:
        print(f"ERROR: Missing or altered AUTOGEN markers in {output_path}. Aborting regeneration.")
        sys.exit(1)
    before = content[:start_idx+len(autogen_start)]
    after = content[end_idx:]
    with open(output_path, 'w') as f:
        f.write(f'{before}\n{new_code}\n{after}')

def get_or_assign_id(reg, html_id, next_id):
    """
    Assign a persistent numeric ID for a given HTML element ID.
    If already assigned, reuse; otherwise, assign next available.
    """
    if html_id in reg:
        return reg[html_id], next_id
    reg[html_id] = next_id
    return next_id, next_id+1

# Usage: python3 html_to_winapi.py demo_interface.html
if len(sys.argv) < 2:
    print("Usage: python3 html_to_winapi.py <html_file>")
    sys.exit(1)

with open(sys.argv[1], 'r', encoding='utf-8') as f:
    soup = BeautifulSoup(f, 'html.parser')

registry = load_registry()
next_id = max(registry.values(), default=100) + 1
used_ids = set(registry.values())

cpp_lines = []
cpp_lines.append('// Auto-generated C++ WinAPI GUI code from HTML sketch')
cpp_lines.append('std::vector<GuiElement*> elements;')


# Layout management defaults
DEFAULT_X = 10
DEFAULT_Y = 10
DEFAULT_WIDTH = 200
DEFAULT_HEIGHT = 24
y = DEFAULT_Y
container_depth = 0
MAX_CONTAINER_DEPTH = 4
cpp_lines.append(f'int y = {DEFAULT_Y};')

def get_layout_attrs(elem):
    """
    Parse layout attributes from HTML element, with defaults.
    Supports data-x, data-y, data-width, data-height.
    """
    x = int(elem.get('data-x', DEFAULT_X))
    y = int(elem.get('data-y', globals().get('y', DEFAULT_Y)))
    w = int(elem.get('data-width', DEFAULT_WIDTH))
    h = int(elem.get('data-height', DEFAULT_HEIGHT))
    return x, y, w, h

def validate_container_depth(depth):
    """
    Warn if container nesting exceeds recommended maximum.
    """
    if depth > MAX_CONTAINER_DEPTH:
        validation_report['warnings'].append(
            f"Container nesting depth {depth} exceeds recommended maximum {MAX_CONTAINER_DEPTH}"
        )



# Pair labels with inputs


# Event handler registry and namespacing
event_registry = {}
def parse_event_attrs(elem, html_id):
    """
    Parse event handler attributes from HTML element and register them.
    Supported: onclick, onchange, onselect, oncheck.
    Warn if handler is multiply assigned.
    """
    handlers = []
    for attr in ['onclick', 'onchange', 'onselect', 'oncheck']:
        handler = elem.get(attr)
        if handler:
            if handler in event_registry:
                validation_report['warnings'].append(
                    f"Event handler '{handler}' multiply assigned (previously for {event_registry[handler]})"
                )
            event_registry[handler] = html_id
            handlers.append(handler)
    return handlers



# Cache BeautifulSoup queries for performance
inputs = soup.find_all('input')
labels = soup.find_all('label')
selects = soup.find_all('select')
uls = soup.find_all('ul')
divs = soup.find_all('div')
progs = soup.find_all('progress')
buttons = soup.find_all('button')

# Pair labels with inputs and validate references
input_ids = set(inp.get('id', inp.get('type', '')) for inp in inputs)
paired_labels = set()
for label in labels:
    text = label.text.strip()
    for_attr = label.get('for')
    html_id = label.get('id', text)
    if for_attr:
        if for_attr in input_ids:
            # Pair label with input, skip standalone label
            paired_labels.add(for_attr)
            # Label will be handled with input below
        else:
            validation_report['warnings'].append(
                f"Label '{text}' references missing input '{for_attr}'"
            )
    else:
        # Standalone label
        id_val, next_id = get_or_assign_id(registry, html_id, next_id)
        if id_val in used_ids:
            validation_report['errors'].append(f"Duplicate ID {id_val} for {html_id}")
            print(f"ERROR: Duplicate ID {id_val} for {html_id}")
            sys.exit(1)
        used_ids.add(id_val)
        cpp_lines.append(f'elements.push_back(new GuiLabel(L"{text}", {id_val}, 10, y, 200, 24)); y += 30;')

# Map input IDs to label text for later pairing
label_for_map = {label.get('for'): label.text.strip() for label in labels if label.get('for')}

    typ = inp.get('type', 'text')
    html_id = inp.get('id', typ)
    id_val, next_id = get_or_assign_id(registry, html_id, next_id)
    if id_val in used_ids:
        print(f"ERROR: Duplicate ID {id_val} for {html_id}")
        sys.exit(1)
    used_ids.add(id_val)
    val = inp.get('value', '')
    label_text = label_for_map.get(html_id, '')
    x, y_val, w, h = get_layout_attrs(inp)
        for handler in handlers:
            cpp_lines.append(f'// Event: {handler} for {html_id} (stub to be implemented)')
    if typ == 'text':
        if label_text:
            cpp_lines.append(f'// Label: {label_text} for input {html_id}')
        cpp_lines.append(f'auto edit_{html_id} = new GuiEdit(L"{val}", {id_val}); elements.push_back(edit_{html_id}); edit_{html_id}->Create(parent, {x}, {y_val}, {w}, {h}); y += 30;')
    elif typ == 'password':
        if label_text:
            cpp_lines.append(f'// Label: {label_text} for password {html_id}')
        cpp_lines.append(f'auto pass_{html_id} = new GuiEdit(L"", {id_val}, true); elements.push_back(pass_{html_id}); pass_{html_id}->Create(parent, {x}, {y_val}, {w}, {h}); y += 30;')
    elif typ == 'checkbox':
        if label_text:
        handlers = parse_event_attrs(sel, html_id)
            cpp_lines.append(f'// Label: {label_text} for checkbox {html_id}')
        cpp_lines.append(f'auto check_{html_id} = new GuiCheckBox(L"{html_id}", {id_val}); elements.push_back(check_{html_id}); check_{html_id}->Create(parent, {x}, {y_val}, 100, {h}); y += 30;')
        for handler in handlers:
            cpp_lines.append(f'// Event: {handler} for {html_id} (stub to be implemented)')
    elif typ == 'radio':
        if label_text:
            cpp_lines.append(f'// Label: {label_text} for radio {html_id}')
        cpp_lines.append(f'auto radio_{html_id} = new GuiRadioButton(L"{html_id}", {id_val}, {x}, {y_val}, 100, {h}); elements.push_back(radio_{html_id}); radio_{html_id}->Create(parent); y += 30;')
    elif typ == 'range':
        if label_text:
            cpp_lines.append(f'// Label: {label_text} for slider {html_id}')
        minv = inp.get('min', '0')
        maxv = inp.get('max', '100')
        valv = inp.get('value', '50')
        cpp_lines.append(f'auto slider_{html_id} = new GuiSlider({id_val}, {minv}, {maxv}, {valv}); elements.push_back(slider_{html_id}); slider_{html_id}->Create(parent, {x}, {y_val}, {w}, {h}); y += 30;')
        handlers = parse_event_attrs(ul, html_id)

# Warn for multiple labels for same input
        for handler in handlers:
            cpp_lines.append(f'// Event: {handler} for {html_id} (stub to be implemented)')
label_counts = {}
for label in soup.find_all('label'):
    for_attr = label.get('for')
    if for_attr:
        label_counts[for_attr] = label_counts.get(for_attr, 0) + 1
for k, v in label_counts.items():
    if v > 1:
        validation_report['warnings'].append(f"Multiple labels reference input '{k}'")

for inp in soup.find_all('input'):
    typ = inp.get('type', 'text')
    html_id = inp.get('id', typ)
    id_val, next_id = get_or_assign_id(registry, html_id, next_id)
        handlers = parse_event_attrs(div, html_id)
        for handler in handlers:
            cpp_lines.append(f'// Event: {handler} for {html_id} (stub to be implemented)')
    if id_val in used_ids:
        validation_report['errors'].append(f"Duplicate ID {id_val} for {html_id}")
        print(f"ERROR: Duplicate ID {id_val} for {html_id}")
        sys.exit(1)
    used_ids.add(id_val)
    val = inp.get('value', '')
    if typ == 'text':
        cpp_lines.append(f'auto edit_{html_id} = new GuiEdit(L"{val}", {id_val}); elements.push_back(edit_{html_id}); edit_{html_id}->Create(parent, 10, y, 200, 24); y += 30;')
    elif typ == 'password':
        cpp_lines.append(f'auto pass_{html_id} = new GuiEdit(L"", {id_val}, true); elements.push_back(pass_{html_id}); pass_{html_id}->Create(parent, 10, y, 200, 24); y += 30;')
    elif typ == 'checkbox':
        cpp_lines.append(f'auto check_{html_id} = new GuiCheckBox(L"{html_id}", {id_val}); elements.push_back(check_{html_id}); check_{html_id}->Create(parent, 10, y, 100, 24); y += 30;')
    elif typ == 'radio':
        cpp_lines.append(f'auto radio_{html_id} = new GuiRadioButton(L"{html_id}", {id_val}, 10, y, 100, 24); elements.push_back(radio_{html_id}); radio_{html_id}->Create(parent); y += 30;')
    elif typ == 'range':
        minv = inp.get('min', '0')
        maxv = inp.get('max', '100')
        valv = inp.get('value', '50')
        cpp_lines.append(f'auto slider_{html_id} = new GuiSlider({id_val}, {minv}, {maxv}, {valv}); elements.push_back(slider_{html_id}); slider_{html_id}->Create(parent, 10, y, 200, 24); y += 30;')

    html_id = sel.get('id', 'combo')
    id_val, next_id = get_or_assign_id(registry, html_id, next_id)
    if id_val in used_ids:
        validation_report['errors'].append(f"Duplicate ID {id_val} for {html_id}")
        print(f"ERROR: Duplicate ID {id_val} for {html_id}")
        sys.exit(1)
    used_ids.add(id_val)
    x, y_val, w, h = get_layout_attrs(sel)
    cpp_lines.append(f'auto combo_{html_id} = new GuiComboBox({id_val}); elements.push_back(combo_{html_id}); combo_{html_id}->Create(parent, {x}, {y_val}, 120, {h});')
    for opt in sel.find_all('option'):
        cpp_lines.append(f'combo_{html_id}->AddItem(L"{opt.text.strip()}");')
        handlers = parse_event_attrs(prog, html_id)
        for handler in handlers:
            cpp_lines.append(f'// Event: {handler} for {html_id} (stub to be implemented)')
    cpp_lines.append('y += 30;')

    html_id = ul.get('id', 'list')
    id_val, next_id = get_or_assign_id(registry, html_id, next_id)
    if id_val in used_ids:
        validation_report['errors'].append(f"Duplicate ID {id_val} for {html_id}")
        print(f"ERROR: Duplicate ID {id_val} for {html_id}")
        sys.exit(1)
    used_ids.add(id_val)
    x, y_val, w, h = get_layout_attrs(ul)
    cpp_lines.append(f'auto list_{html_id} = new GuiListBox({id_val}); elements.push_back(list_{html_id}); list_{html_id}->Create(parent, {x}, {y_val}, 120, 60);')
    for li in ul.find_all('li'):
        handlers = parse_event_attrs(btn, html_id)
        for handler in handlers:
            cpp_lines.append(f'// Event: {handler} for {html_id} (stub to be implemented)')
        cpp_lines.append(f'list_{html_id}->AddItem(L"{li.text.strip()}");')
    cpp_lines.append('y += 70;')

    html_id = div.get('id', 'group')
    id_val, next_id = get_or_assign_id(registry, html_id, next_id)
    if id_val in used_ids:
        validation_report['errors'].append(f"Duplicate ID {id_val} for {html_id}")
        print(f"ERROR: Duplicate ID {id_val} for {html_id}")
        sys.exit(1)
    used_ids.add(id_val)
    container_depth += 1
    validate_container_depth(container_depth)
    x, y_val, w, h = get_layout_attrs(div)
    cpp_lines.append(f'auto group_{html_id} = new GuiGroupBox(L"{html_id}", {id_val}, {x}, {y_val}, {w}, {h}); elements.push_back(group_{html_id}); group_{html_id}->Create(parent);')
    container_depth -= 1

    html_id = div.get('id', 'tab')
    id_val, next_id = get_or_assign_id(registry, html_id, next_id)
    if id_val in used_ids:
        validation_report['errors'].append(f"Duplicate ID {id_val} for {html_id}")
        print(f"ERROR: Duplicate ID {id_val} for {html_id}")
        sys.exit(1)
    used_ids.add(id_val)
    container_depth += 1
    validate_container_depth(container_depth)
    x, y_val, w, h = get_layout_attrs(div)
    cpp_lines.append(f'auto tab_{html_id} = new GuiTab({id_val}, {x}, {y_val}, {w}, 40, TabDock::Top); elements.push_back(tab_{html_id});')
    for btn in div.find_all('button'):
        cpp_lines.append(f'tab_{html_id}->AddPage(L"{btn.text.strip()}");')
    cpp_lines.append(f'tab_{html_id}->Create(parent); y += 50;')
    container_depth -= 1

    html_id = prog.get('id', 'progress')
    id_val, next_id = get_or_assign_id(registry, html_id, next_id)
    if id_val in used_ids:
        print(f"ERROR: Duplicate ID {id_val} for {html_id}")
        sys.exit(1)
    used_ids.add(id_val)
    x, y_val, w, h = get_layout_attrs(prog)
    val = prog.get('value', '0')
    maxv = prog.get('max', '100')
    cpp_lines.append(f'auto progress_{html_id} = new GuiProgressBar({id_val}, {x}, {y_val}, {w}, {h}, 0, {maxv}, {val}); elements.push_back(progress_{html_id}); progress_{html_id}->Create(parent); y += 30;')

    html_id = btn.get('id', 'btn')
    id_val, next_id = get_or_assign_id(registry, html_id, next_id)
    if id_val in used_ids:
        print(f"ERROR: Duplicate ID {id_val} for {html_id}")
        sys.exit(1)
    used_ids.add(id_val)
    x, y_val, w, h = get_layout_attrs(btn)
    text = btn.text.strip()
    cpp_lines.append(f'auto btn_{html_id} = new GuiButton(L"{text}", {id_val}, {x}, {y_val}, 60, {h}); elements.push_back(btn_{html_id}); btn_{html_id}->Create(parent); y += 30;')


save_registry(registry)


# Print validation summary report
print("\n==== Validation Report ====")
if validation_report['warnings']:
    print("Warnings:")
    for w in validation_report['warnings']:
        print(f"  - {w}")
if validation_report['errors']:
    print("Errors:")
    for e in validation_report['errors']:
        print(f"  - {e}")
if validation_report['unsupported']:
    print(f"Unsupported HTML elements: {validation_report['unsupported']}")
if not any([validation_report['warnings'], validation_report['errors'], validation_report['unsupported']]):
    print("No validation issues detected.")

output_path = sys.argv[2] if len(sys.argv) > 2 else None
autogen_code = '\n'.join(cpp_lines)
if output_path:
    update_cpp_file(output_path, autogen_code)
else:
    print(autogen_code)
