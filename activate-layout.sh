#!/usr/bin/env bash
# ================================================================
# activate-layout.sh
# Bengali (Avro Phonetic) — Layout Activator
# Works on: X11 and Wayland (KDE Plasma 5/6 + GNOME)
# ================================================================
# This script does NOT need sudo.
# It configures the CURRENT USER's session only.
#
# Usage:
#   bash activate-layout.sh
#   bash activate-layout.sh --remove     (undo / remove bn_avro)
#   bash activate-layout.sh --status     (check current status)
# ================================================================

set -euo pipefail

# ── Colours ───────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

ok()    { echo -e "${GREEN}  ✓  $1${NC}"; }
info()  { echo -e "${CYAN}  ›  $1${NC}"; }
warn()  { echo -e "${YELLOW}  ⚠  $1${NC}"; }
err()   { echo -e "${RED}  ✗  $1${NC}"; }
step()  { echo -e "\n${YELLOW}${BOLD}[ $1 ]${NC}"; }
header(){ echo -e "\n${BLUE}${BOLD}$1${NC}"; }

LAYOUT_ID="bn_avro"
KXKBRC="${HOME}/.config/kxkbrc"
XKB_CACHE="${HOME}/.cache/xkb"
MODE="${1:-}"   # --remove | --status | (empty = install)

# ════════════════════════════════════════════════════════════════
#  ① DETECT SESSION TYPE
# ════════════════════════════════════════════════════════════════
detect_session() {
    local session="${XDG_SESSION_TYPE:-}"

    # Primary: XDG_SESSION_TYPE env var
    if [ -n "$session" ]; then
        echo "$session"; return
    fi

    # Fallback 1: WAYLAND_DISPLAY set means we're on Wayland
    if [ -n "${WAYLAND_DISPLAY:-}" ]; then
        echo "wayland"; return
    fi

    # Fallback 2: DISPLAY set without WAYLAND means X11
    if [ -n "${DISPLAY:-}" ] && [ -z "${WAYLAND_DISPLAY:-}" ]; then
        echo "x11"; return
    fi

    # Fallback 3: loginctl
    local lc
    lc=$(loginctl show-session "$(loginctl | awk "/$(whoami)/{print \$1; exit}")" \
         -p Type --value 2>/dev/null || echo "")
    if [ -n "$lc" ]; then echo "$lc"; return; fi

    echo "unknown"
}

# ════════════════════════════════════════════════════════════════
#  ② DETECT DESKTOP ENVIRONMENT
# ════════════════════════════════════════════════════════════════
detect_de() {
    local de="${XDG_CURRENT_DESKTOP:-${DESKTOP_SESSION:-}}"
    de="${de,,}"   # lowercase
    case "$de" in
        *kde*|*plasma*)  echo "kde" ;;
        *gnome*)         echo "gnome" ;;
        *xfce*)          echo "xfce" ;;
        *lxqt*)          echo "lxqt" ;;
        *)               echo "unknown" ;;
    esac
}

# ════════════════════════════════════════════════════════════════
#  ③ DETECT KDE PLASMA VERSION
# ════════════════════════════════════════════════════════════════
detect_kde_version() {
    # Try plasmashell first
    if command -v plasmashell &>/dev/null; then
        local ver
        ver=$(plasmashell --version 2>/dev/null | grep -oP '\d+' | head -1)
        if [ -n "$ver" ]; then echo "$ver"; return; fi
    fi
    # Fallback: which kwriteconfig
    if command -v kwriteconfig6 &>/dev/null; then echo "6"; return; fi
    if command -v kwriteconfig5 &>/dev/null; then echo "5"; return; fi
    echo "0"
}

# ════════════════════════════════════════════════════════════════
#  ④ VERIFY layout file exists in system
# ════════════════════════════════════════════════════════════════
check_layout_installed() {
    if [ ! -f "/usr/share/X11/xkb/symbols/${LAYOUT_ID}" ]; then
        err "Layout file not found: /usr/share/X11/xkb/symbols/${LAYOUT_ID}"
        echo ""
        echo "  Run the system installer first (needs sudo):"
        echo "  ${BOLD}sudo bash install-bn-avro.sh${NC}"
        exit 1
    fi
}

# ════════════════════════════════════════════════════════════════
#  ⑤ PATCH ~/.config/kxkbrc  (KDE — both X11 and Wayland)
# ════════════════════════════════════════════════════════════════
patch_kxkbrc() {
    local action="${1:-add}"   # add | remove

    # Create kxkbrc if it doesn't exist
    if [ ! -f "$KXKBRC" ]; then
        mkdir -p "$(dirname "$KXKBRC")"
        cat > "$KXKBRC" << 'EOF'
[Layout]
Use=false
LayoutList=us
VariantList=
DisplayNames=
SwitchMode=Global
Options=
ResetOldOptions=false
ShowFlag=false
ShowLabel=true
ShowLayoutIndicator=true
ShowSingle=false
LayoutLoopCount=-1
EOF
        info "Created new kxkbrc"
    fi

    # Backup
    cp "$KXKBRC" "${KXKBRC}.bak-avro"
    info "Backup: ${KXKBRC}.bak-avro"

    # Use Python for reliable INI-style parsing
    python3 - "$KXKBRC" "$action" "$LAYOUT_ID" << 'PYEOF'
import sys, re

kxkbrc_path = sys.argv[1]
action      = sys.argv[2]   # "add" or "remove"
layout_id   = sys.argv[3]

with open(kxkbrc_path, "r") as f:
    content = f.read()

# ── Parse current values ──────────────────────────────────────
def get_val(key, default=""):
    m = re.search(rf"^{key}=(.*)$", content, re.MULTILINE)
    return m.group(1).strip() if m else default

def set_val(key, value):
    global content
    if re.search(rf"^{key}=", content, re.MULTILINE):
        content = re.sub(rf"^{key}=.*$", f"{key}={value}", content, flags=re.MULTILINE)
    else:
        # Add under [Layout] section
        content = content.replace("[Layout]", f"[Layout]\n{key}={value}", 1)

layouts      = [x for x in get_val("LayoutList", "us").split(",") if x]
variants     = get_val("VariantList", "").split(",")
display_names= get_val("DisplayNames", "").split(",")
use_flag     = get_val("Use", "false")
options      = get_val("Options", "")

if action == "add":
    if layout_id not in layouts:
        layouts.append(layout_id)
        variants.append("")
        display_names.append("")
        print(f"  Added '{layout_id}' to layout list")
    else:
        print(f"  '{layout_id}' already in layout list")

    # Ensure Use=true
    set_val("Use", "true")

    # Add switch shortcut if Options empty
    if not options.strip():
        set_val("Options", "grp:super_space_toggle")
        set_val("ResetOldOptions", "true")
        print("  Shortcut set: Super+Space to switch layouts")

elif action == "remove":
    if layout_id in layouts:
        idx = layouts.index(layout_id)
        layouts.pop(idx)
        if idx < len(variants):  variants.pop(idx)
        if idx < len(display_names): display_names.pop(idx)
        print(f"  Removed '{layout_id}' from layout list")
    else:
        print(f"  '{layout_id}' not in layout list — nothing to remove")

    # If only one layout left, disable Use flag
    if len(layouts) <= 1:
        set_val("Use", "false")

# Pad lists to equal length
max_len = len(layouts)
while len(variants)      < max_len: variants.append("")
while len(display_names) < max_len: display_names.append("")

# Write back
set_val("LayoutList",   ",".join(layouts))
set_val("VariantList",  ",".join(variants))
set_val("DisplayNames", ",".join(display_names))

with open(kxkbrc_path, "w") as f:
    f.write(content)

print(f"  LayoutList → {','.join(layouts)}")
PYEOF

}

# ════════════════════════════════════════════════════════════════
#  ⑥ RELOAD KDE KEYBOARD without logout
# ════════════════════════════════════════════════════════════════
reload_kde() {
    local kde_ver="$1"
    local reloaded=false

    info "Attempting live reload via D-Bus..."

    if [ "$kde_ver" = "6" ]; then
        if dbus-send --session \
            --dest=org.kde.keyboard \
            /Layouts \
            org.kde.KeyboardLayouts.reloadConfig \
            2>/dev/null; then
            ok "KDE keyboard reloaded via D-Bus (no logout needed)"
            reloaded=true
        fi
    elif [ "$kde_ver" = "5" ]; then
        if command -v qdbus &>/dev/null; then
            if qdbus org.kde.keyboard /Layouts reloadConfig 2>/dev/null; then
                ok "KDE keyboard reloaded via qdbus (no logout needed)"
                reloaded=true
            fi
        fi
        # Fallback for KDE5
        if [ "$reloaded" = false ] && command -v dbus-send &>/dev/null; then
            if dbus-send --session \
                --dest=org.kde.keyboard \
                /Layouts \
                org.kde.KeyboardLayouts.reloadConfig \
                2>/dev/null; then
                ok "KDE keyboard reloaded via D-Bus"
                reloaded=true
            fi
        fi
    fi

    if [ "$reloaded" = false ]; then
        warn "Live reload failed — please log out and back in."
        warn "Your settings are saved and will apply on next login."
    fi
}

# ════════════════════════════════════════════════════════════════
#  ⑦ GNOME WAYLAND activation
# ════════════════════════════════════════════════════════════════
activate_gnome() {
    local action="${1:-add}"
    if ! command -v gsettings &>/dev/null; then
        err "gsettings not found. Cannot configure GNOME layout."
        exit 1
    fi

    local current
    current=$(gsettings get org.gnome.desktop.input-sources sources 2>/dev/null || echo "[]")

    if [ "$action" = "add" ]; then
        if echo "$current" | grep -q "bn_avro"; then
            ok "bn_avro already in GNOME input sources"
        else
            # Add to existing sources
            local new_sources
            if [ "$current" = "@as []" ] || [ "$current" = "[]" ]; then
                new_sources="[('xkb', 'us'), ('xkb', 'bn_avro')]"
            else
                # Insert before closing ]
                new_sources="${current%]}, ('xkb', 'bn_avro')]"
            fi
            gsettings set org.gnome.desktop.input-sources sources "$new_sources"
            ok "Added bn_avro to GNOME input sources"
        fi
        # Set Super+Space as switch shortcut
        gsettings set org.gnome.desktop.wm.keybindings \
            switch-input-source "['<Super>space']" 2>/dev/null || true
        ok "Shortcut: Super+Space to switch layouts"
    else
        # Remove
        if echo "$current" | grep -q "bn_avro"; then
            local new_sources
            new_sources=$(echo "$current" | sed "s|, ('xkb', 'bn_avro')||g; s|('xkb', 'bn_avro'), ||g; s|('xkb', 'bn_avro')||g")
            gsettings set org.gnome.desktop.input-sources sources "$new_sources"
            ok "Removed bn_avro from GNOME input sources"
        else
            info "bn_avro not found in GNOME sources — nothing to remove"
        fi
    fi
}

# ════════════════════════════════════════════════════════════════
#  ⑧ X11 activation via setxkbmap
# ════════════════════════════════════════════════════════════════
activate_x11_kde() {
    local action="${1:-add}"

    # Always patch kxkbrc so it persists after reboot
    patch_kxkbrc "$action"

    if [ "$action" = "add" ]; then
        # Apply immediately to current session
        if command -v setxkbmap &>/dev/null && [ -n "${DISPLAY:-}" ]; then
            setxkbmap -layout "us,${LAYOUT_ID}" \
                      -option "grp:super_space_toggle" 2>/dev/null \
            && ok "Applied immediately via setxkbmap (current session)" \
            || warn "setxkbmap failed — settings saved, will apply on next login"
        fi
    else
        if command -v setxkbmap &>/dev/null && [ -n "${DISPLAY:-}" ]; then
            setxkbmap -layout "us" -option "" 2>/dev/null \
            && ok "Reverted to English-only via setxkbmap" || true
        fi
    fi
}

# ════════════════════════════════════════════════════════════════
#  ⑨ STATUS command
# ════════════════════════════════════════════════════════════════
show_status() {
    header "══ bn_avro Layout Status ══"
    echo ""

    # System file
    if [ -f "/usr/share/X11/xkb/symbols/${LAYOUT_ID}" ]; then
        ok "System file: /usr/share/X11/xkb/symbols/${LAYOUT_ID} (installed)"
    else
        err "System file: NOT installed (run: sudo bash install-bn-avro.sh)"
    fi

    # evdev.xml
    if grep -q "$LAYOUT_ID" /usr/share/X11/xkb/rules/evdev.xml 2>/dev/null; then
        ok "evdev.xml: registered"
    else
        err "evdev.xml: NOT registered"
    fi

    # Session
    SESSION=$(detect_session)
    DE=$(detect_de)
    echo ""
    info "Session type: ${SESSION}"
    info "Desktop: ${DE}"
    echo ""

    # kxkbrc (KDE)
    if [ "$DE" = "kde" ] && [ -f "$KXKBRC" ]; then
        local ll
        ll=$(grep "^LayoutList=" "$KXKBRC" 2>/dev/null | cut -d= -f2)
        if echo "$ll" | grep -q "$LAYOUT_ID"; then
            ok "kxkbrc: bn_avro is active (LayoutList=${ll})"
        else
            warn "kxkbrc: bn_avro NOT in LayoutList (current: ${ll})"
        fi
    fi

    # GNOME
    if [ "$DE" = "gnome" ] && command -v gsettings &>/dev/null; then
        local src
        src=$(gsettings get org.gnome.desktop.input-sources sources 2>/dev/null || echo "")
        if echo "$src" | grep -q "bn_avro"; then
            ok "GNOME: bn_avro is active"
        else
            warn "GNOME: bn_avro NOT in input sources"
        fi
    fi

    # X11 current session
    if [ "$SESSION" = "x11" ] && command -v setxkbmap &>/dev/null; then
        local cur
        cur=$(setxkbmap -query 2>/dev/null | grep "^layout:" | awk '{print $2}')
        info "Current X11 layout: ${cur:-unknown}"
        if echo "$cur" | grep -q "bn_avro"; then
            ok "bn_avro is the active layout right now"
        else
            warn "bn_avro is NOT the active layout in this session"
        fi
    fi

    echo ""
}

# ════════════════════════════════════════════════════════════════
#  MAIN
# ════════════════════════════════════════════════════════════════
print_header() {
    echo -e "${BLUE}${BOLD}"
    echo "  ╔══════════════════════════════════════════════════════╗"
    echo "  ║   Bengali Avro Phonetic — Layout Activator          ║"
    echo "  ║   Supports: X11 · Wayland · KDE5 · KDE6 · GNOME    ║"
    echo "  ╚══════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

print_header

# Handle --status
if [ "$MODE" = "--status" ]; then
    show_status
    exit 0
fi

# Detect environment
SESSION=$(detect_session)
DE=$(detect_de)
KDE_VER=$(detect_kde_version)

info "Session type : ${SESSION}"
info "Desktop      : ${DE}"
[ "$KDE_VER" != "0" ] && info "KDE Plasma   : ${KDE_VER}"
echo ""

# Handle --remove
ACTION="add"
[ "$MODE" = "--remove" ] && ACTION="remove"

if [ "$ACTION" = "add" ]; then
    step "Checking system installation"
    check_layout_installed
    ok "Layout file found in /usr/share/X11/xkb/symbols/"
fi

# ── Clear XKB cache (both X11 and Wayland benefit) ───────────────
step "Clearing XKB cache"
if [ -d "$XKB_CACHE" ]; then
    rm -rf "$XKB_CACHE"
    ok "XKB cache cleared: ${XKB_CACHE}"
else
    info "No cache found (already clean)"
fi

# ── Route to correct activation method ───────────────────────────
step "Configuring layout (${SESSION} / ${DE})"

case "$DE" in
    kde)
        patch_kxkbrc "$ACTION"
        echo ""
        if [ "$SESSION" = "wayland" ]; then
            info "Wayland session — attempting D-Bus live reload..."
            reload_kde "$KDE_VER"
        else
            activate_x11_kde "$ACTION"
        fi
        ;;
    gnome)
        activate_gnome "$ACTION"
        if [ "$SESSION" = "x11" ] && command -v setxkbmap &>/dev/null; then
            setxkbmap -layout "us,${LAYOUT_ID}" \
                      -option "grp:super_space_toggle" 2>/dev/null \
            && ok "Applied immediately via setxkbmap" || true
        fi
        ;;
    xfce|lxqt|unknown)
        # Generic: patch kxkbrc if KDE tools exist, else setxkbmap only
        warn "Desktop '${DE}' — using generic X11 method"
        if [ "$KDE_VER" != "0" ]; then
            patch_kxkbrc "$ACTION"
        fi
        if [ "$SESSION" = "x11" ] && command -v setxkbmap &>/dev/null; then
            activate_x11_kde "$ACTION"
        fi
        ;;
esac

# ── Final message ────────────────────────────────────────────────
echo ""
echo -e "${GREEN}${BOLD}══════════════════════════════════════════════════════${NC}"
if [ "$ACTION" = "add" ]; then
    echo -e "${GREEN}${BOLD}  Done! Bengali (Avro Phonetic) layout activated.${NC}"
    echo -e "${GREEN}${BOLD}══════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "  Switch layouts : ${BOLD}Super + Space${NC}"
    echo -e "  Taskbar shows  : ${BOLD}bn${NC} (Bengali)  or  ${BOLD}us${NC} (English)"
    echo ""
    if [ "$SESSION" = "wayland" ]; then
        echo -e "  ${YELLOW}If the layout doesn't appear yet, log out and back in.${NC}"
    else
        echo -e "  Test right now : ${BOLD}Super+Space${NC} → open Kate → type k → ক"
    fi
else
    echo -e "${GREEN}${BOLD}  Done! Bengali layout removed.${NC}"
    echo -e "${GREEN}${BOLD}══════════════════════════════════════════════════════${NC}"
fi
echo ""
echo -e "  Check status anytime: ${BOLD}bash activate-layout.sh --status${NC}"
echo ""
