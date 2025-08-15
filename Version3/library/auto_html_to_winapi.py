import os
import time
import subprocess
from pathlib import Path

HTML_DIR = Path('../Version2/development/html_mock')
CONVERTER = Path('html_to_winapi.py')
CPP_OUTPUT = Path('full_demo_interface_winapi.cpp')
CHECK_INTERVAL = 2  # seconds

# Store last modification times
last_mtimes = {}

def get_html_files():
    return [f for f in HTML_DIR.glob('*.html')]

def check_modifications():
    modified = []
    for f in get_html_files():
        mtime = f.stat().st_mtime
        if f not in last_mtimes or last_mtimes[f] != mtime:
            modified.append(f)
            last_mtimes[f] = mtime
    return modified

def prompt_user(files):
    print("Modification détectée sur les fichiers HTML :")
    for f in files:
        print(f" - {f.name}")
    resp = input("Lancer la conversion en C++ WinAPI ? (o/n) : ").strip().lower()
    return resp == 'o'

def run_converter(html_file):
    print(f"Conversion de {html_file.name}...")
    result = subprocess.run(['python3', str(CONVERTER), str(html_file), str(CPP_OUTPUT)], capture_output=True, text=True)
    print(result.stdout)
    if result.returncode != 0:
        print("Erreur lors de la conversion :")
        print(result.stderr)
    else:
        print(f"Conversion terminée : {CPP_OUTPUT}")

if __name__ == '__main__':
    print("Surveillance du dossier HTML. Ctrl+C pour quitter.")
    while True:
        modified = check_modifications()
        if modified:
            if prompt_user(modified):
                for f in modified:
                    run_converter(f)
        time.sleep(CHECK_INTERVAL)
