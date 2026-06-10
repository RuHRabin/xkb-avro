#!/usr/bin/env bash
# ================================================================
# install-bn-avro.sh
# Bengali (Avro Phonetic) XKB Layout Installer
# For Debian / Ubuntu / KDE Plasma
# ================================================================
# Usage:
#   chmod +x install-bn-avro.sh
#   sudo bash install-bn-avro.sh
#
# This script expects the file  "bn_avro"  to be in the same
# directory. It will:
#   1. Copy bn_avro  →  /usr/share/X11/xkb/symbols/
#   2. Add an entry to  evdev.lst  (if not already present)
#   3. Add an entry to  evdev.xml  (if not already present)
#   4. Verify the install with xkbcomp
# ================================================================

set -euo pipefail

# ── Colors ───────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# ── Paths ─────────────────────────────────────────────────────────
SYMBOLS_DIR="/usr/share/X11/xkb/symbols"
RULES_DIR="/usr/share/X11/xkb/rules"
SRC_FILE="./bn_avro"
DEST_FILE="$SYMBOLS_DIR/bn_avro"
EVDEV_LST="$RULES_DIR/evdev.lst"
EVDEV_XML="$RULES_DIR/evdev.xml"
BASE_LST="$RULES_DIR/base.lst"
BASE_XML="$RULES_DIR/base.xml"
LAYOUT_NAME="bn_avro"
LAYOUT_DESC="Bengali (Avro Phonetic)"

print_header() {
    echo -e "\n${BLUE}${BOLD}════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}${BOLD}   Bengali Avro Phonetic XKB Layout Installer            ${NC}"
    echo -e "${BLUE}${BOLD}════════════════════════════════════════════════════════${NC}\n"
}

ok()   { echo -e "${GREEN}  ✓  $1${NC}"; }
info() { echo -e "${CYAN}  ›  $1${NC}"; }
warn() { echo -e "${YELLOW}  ⚠  $1${NC}"; }
err()  { echo -e "${RED}  ✗  $1${NC}"; }
step() { echo -e "\n${YELLOW}${BOLD}[ $1 ]${NC}"; }

# ── Pre-flight checks ─────────────────────────────────────────────
print_header

if [[ $EUID -ne 0 ]]; then
    err "This script must be run as root."
    echo "    Run:  sudo bash install-bn-avro.sh"
    exit 1
fi

if [[ ! -f "$SRC_FILE" ]]; then
    err "Source file not found: $SRC_FILE"
    echo "    Make sure 'bn_avro' is in the same directory as this script."
    exit 1
fi

# ── Step 1: Install the symbols file ─────────────────────────────
step "STEP 1/4: Installing XKB symbols file"

if [[ -f "$DEST_FILE" ]]; then
    warn "Existing file found. Creating backup: ${DEST_FILE}.bak"
    cp "$DEST_FILE" "${DEST_FILE}.bak"
fi

cp "$SRC_FILE" "$DEST_FILE"
chmod 644 "$DEST_FILE"
ok "Symbols file installed: $DEST_FILE"

# ── Step 2: Update evdev.lst ──────────────────────────────────────
step "STEP 2/4: Registering in evdev.lst"

update_lst() {
    local LST_FILE="$1"
    if [[ ! -f "$LST_FILE" ]]; then
        warn "$LST_FILE not found — skipping."
        return
    fi

    if grep -q "^  ${LAYOUT_NAME}" "$LST_FILE"; then
        warn "Entry already present in $LST_FILE — skipping."
        return
    fi

    # Create backup
    cp "$LST_FILE" "${LST_FILE}.bak-avro"
    info "Backup: ${LST_FILE}.bak-avro"

    # Add entry after the line containing "  bn " in the ! layout section
    # Uses Python for reliable multi-line context-aware insertion
    python3 - <<PYEOF
import re, sys

with open("$LST_FILE", "r") as f:
    content = f.read()

new_entry = "  ${LAYOUT_NAME}         ${LAYOUT_DESC}\n"

# Find the ! layout section and the 'bn' entry, insert after it
pattern = r"(^  bn\b.*$)"
replacement = r"\1\n" + new_entry.rstrip()

new_content = re.sub(pattern, replacement, content, count=1, flags=re.MULTILINE)

if new_content == content:
    # Fallback: insert at end of ! layout section
    new_content = content.replace("! variant", new_entry + "! variant", 1)

with open("$LST_FILE", "w") as f:
    f.write(new_content)

print("  Entry added to $LST_FILE")
PYEOF
    ok "Entry added to $LST_FILE"
}

update_lst "$EVDEV_LST"
if [[ -f "$BASE_LST" ]]; then
    update_lst "$BASE_LST"
fi

# ── Step 3: Update evdev.xml ─────────────────────────────────────
step "STEP 3/4: Registering in evdev.xml"

update_xml() {
    local XML_FILE="$1"
    if [[ ! -f "$XML_FILE" ]]; then
        warn "$XML_FILE not found — skipping."
        return
    fi

    if grep -q "<name>${LAYOUT_NAME}</name>" "$XML_FILE"; then
        warn "Entry already present in $XML_FILE — skipping."
        return
    fi

    # Create backup
    cp "$XML_FILE" "${XML_FILE}.bak-avro"
    info "Backup: ${XML_FILE}.bak-avro"

    # Use Python's xml.etree to safely insert the new layout element
    python3 - <<PYEOF
import xml.etree.ElementTree as ET
import sys

ET.register_namespace('', '')
tree = ET.parse("$XML_FILE")
root = tree.getroot()

# Build the new layout element
new_layout_xml = """    <layout>
      <configItem>
        <name>bn_avro</name>
        <shortDescription>bn</shortDescription>
        <description>Bengali (Avro Phonetic)</description>
        <languageList>
          <iso639Id>ben</iso639Id>
        </languageList>
      </configItem>
      <variantList/>
    </layout>"""

# Find the layoutList element
layout_list = root.find('.//layoutList')
if layout_list is None:
    print("ERROR: <layoutList> not found in XML", file=sys.stderr)
    sys.exit(1)

# Find index of the 'bn' layout to insert after it
insert_after = -1
for i, child in enumerate(layout_list):
    name_el = child.find('.//configItem/name')
    if name_el is not None and name_el.text == 'bn':
        insert_after = i
        break

# Fall back to appending at the end
if insert_after == -1:
    insert_after = len(list(layout_list)) - 1

# We'll use raw string manipulation to preserve formatting
with open("$XML_FILE", "r") as f:
    content = f.read()

# Find the closing </layout> after the 'bn' entry and insert after it
import re

# Pattern: find the bn configItem and its enclosing </layout>
# We look for the block containing <name>bn</name> and take its </layout>
bn_block_pattern = r'(<layout>\s*<configItem>\s*<name>bn</name>.*?</layout>)'
match = re.search(bn_block_pattern, content, re.DOTALL)

if match:
    end_pos = match.end()
    content = content[:end_pos] + "\n" + new_layout_xml + content[end_pos:]
else:
    # Fallback: insert before closing </layoutList>
    content = content.replace("</layoutList>", new_layout_xml + "\n  </layoutList>", 1)

with open("$XML_FILE", "w") as f:
    f.write(content)

print("  Entry added to $XML_FILE")
PYEOF
    ok "Entry added to $XML_FILE"
}

update_xml "$EVDEV_XML"
if [[ -f "$BASE_XML" ]]; then
    update_xml "$BASE_XML"
fi

# ── Step 4: Verify ────────────────────────────────────────────────
step "STEP 4/4: Verifying the layout"

info "Validating XKB symbols file syntax..."
if command -v xkbcomp &>/dev/null; then
    if DISPLAY="${DISPLAY:-:0}" xkbcomp "$DEST_FILE" /dev/null 2>&1; then
        ok "Syntax validation passed."
    else
        warn "xkbcomp reported issues — check the output above."
        warn "The layout may still work; some warnings are non-fatal."
    fi
else
    warn "xkbcomp not found. Install with: sudo apt install x11-xkb-utils"
fi

info "Checking registration..."
if grep -q "$LAYOUT_NAME" "$EVDEV_LST" 2>/dev/null; then
    ok "Found in evdev.lst"
else
    err "NOT found in evdev.lst — manual edit required."
fi

if grep -q "$LAYOUT_NAME" "$EVDEV_XML" 2>/dev/null; then
    ok "Found in evdev.xml"
else
    err "NOT found in evdev.xml — manual edit required."
fi

# ── Done ─────────────────────────────────────────────────────────
echo -e "\n${GREEN}${BOLD}════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}${BOLD}  Installation complete!${NC}"
echo -e "${GREEN}${BOLD}════════════════════════════════════════════════════════${NC}"

echo -e "\n${CYAN}${BOLD}NEXT STEPS:${NC}"
echo -e "  1. Test now (no reboot needed):"
echo -e "     ${BOLD}setxkbmap -layout bn_avro${NC}"
echo -e "     (type in a text editor to verify Bengali output)"
echo ""
echo -e "  2. Switch back to English:"
echo -e "     ${BOLD}setxkbmap -layout us${NC}"
echo ""
echo -e "  3. Add to KDE Plasma permanently:"
echo -e "     System Settings → Keyboard → Layouts → Add"
echo -e "     Search for: 'Bengali (Avro Phonetic)'"
echo -e "     Set a shortcut (e.g., Super+Space) to switch layouts."
echo ""
echo -e "  4. Install Bengali font (if not already):"
echo -e "     ${BOLD}sudo apt install fonts-noto-core${NC}"
echo ""
echo -e "${YELLOW}NOTE: Backups of modified files saved with .bak-avro extension.${NC}"
echo -e "${YELLOW}Re-run this script after xkb-data package upgrades.${NC}\n"
