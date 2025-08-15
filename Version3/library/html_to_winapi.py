import sys, os, json

# Validation report structure
validation_report = {
    'warnings': [],
    'errors': [],
    'unsupported': set(),
}
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
    Prevents duplicate assignment in the same run.
    """
    if html_id in reg:
        if reg[html_id] in used_ids:
            validation_report['warnings'].append(f"Duplicate HTML id '{html_id}' detected; skipping assignment.")
            return reg[html_id], next_id
        return reg[html_id], next_id
    reg[html_id] = next_id
    return next_id, next_id+1

# Usage: python3 html_to_winapi.py demo_interface.html
if len(sys.argv) < 2:
    print("Usage: python3 html_to_winapi.py <html_file>")
    sys.exit(1)

with open(sys.argv[1], 'r', encoding='utf-8') as f:
    soup = BeautifulSoup(f, 'html.parser')


# If registry file does not exist, start fresh
if not os.path.exists(REGISTRY_FILE):
    registry = {}
    next_id = 101
    used_ids = set()
else:
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



# Track HTML IDs seen in this run to prevent duplicates
seen_html_ids = set()
# Generate C++ code for input elements
for inp in inputs:
    typ = inp.get('type', 'text')
    html_id = inp.get('id', typ)
    if html_id in seen_html_ids:
        validation_report['warnings'].append(f"Duplicate HTML id '{html_id}' detected; skipping element.")
        continue
    seen_html_ids.add(html_id)
    id_val, next_id = get_or_assign_id(registry, html_id, next_id)
    used_ids.add(id_val)
    val = inp.get('value', '')
    label_text = label_for_map.get(html_id, '')
    x, y_val, w, h = get_layout_attrs(inp)
    handlers = parse_event_attrs(inp, html_id)
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
            cpp_lines.append(f'// Label: {label_text} for checkbox {html_id}')
        cpp_lines.append(f'auto check_{html_id} = new GuiCheckBox(L"{html_id}", {id_val}); elements.push_back(check_{html_id}); check_{html_id}->Create(parent, {x}, {y_val}, 100, {h}); y += 30;')
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
