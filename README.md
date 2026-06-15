# 🇧🇩 Bengali Avro Phonetic — Native XKB Keyboard Layout

> **Type Bengali on Linux without any Input Method daemon (IBus/Fcitx).**
> A pure, kernel-level XKB layout inspired by the Avro Phonetic scheme — no background processes, no popups, no middlemen.

---

## ✨ Features

- ✅ **Daemon-free** — Works entirely at the X11 keymap level. No IBus, no Fcitx, no background process
- ✅ **Secure** — Your keystrokes go directly to the application. No third-party process reads them
- ✅ **62+ Bengali characters** — All vowels, consonants, matras, diacritics, digits, and punctuation covered
- ✅ **4-level key design** — Normal, Shift, AltGr, Shift+AltGr per key
- ✅ **Phonetically intuitive** — `k` → ক, `K` → খ, `t` → ত, `T` → ট, `a` → অ, `A` → আ
- ✅ **Conjunct typing** — Use `\` (Backslash) as Hasanta: `k` + `\` + `t` → ক্ত
- ✅ **Bengali digits** — AltGr + `0`–`9` → ০–৯
- ✅ **KDE Plasma native** — Appears in System Settings on both X11 and Wayland
- ✅ **Wayland compatible** — Works on KDE Plasma Wayland via `kwriteconfig` and D-Bus
- ✅ **Bilingual switching** — Switch between Bengali and English instantly with a shortcut
- ✅ **Optional XCompose** — Companion `.XCompose` file for Avro-style digraph sequences

---

## 🔐 Why This Is More Secure Than IBus/Fcitx

When you use an Input Method like IBus or Fcitx, **every key you press passes through a third-party daemon** before reaching your application. This includes passwords, banking credentials, and sensitive messages.

```
IBus/Fcitx flow:   Keyboard → ibus-daemon (background process) → Application
XKB flow:          Keyboard → Linux kernel keymap              → Application
```

This XKB layout has **no middleman**. It is defined at the kernel input layer — the same level as your regular English keyboard layout. Nothing extra runs, nothing extra reads your input.

---

## 📋 Requirements

| Requirement | Details |
|---|---|
| OS | Debian, Ubuntu, or any Debian-based distro |
| Display Server | X11 (Xorg) **and** Wayland (KDE Plasma 5.27+ / 6) |
| Desktop | KDE Plasma 5 or 6 (also works on GNOME/XFCE) |
| Font | `fonts-noto-core` (for correct Bengali rendering) |
| Privileges | `sudo` access (for installation only) |

---

## 📦 Files in This Repository

```
.
├── bn_avro                  # XKB symbols file → goes to /usr/share/X11/xkb/symbols/
├── bn-avro-xcompose         # Optional XCompose rules → merge into ~/.XCompose
├── install-bn-avro.sh       # Automated installer script
└── README.md                # This file
```

---

## 🚀 Quick Installation

### Option A — Automated (Recommended)

```bash
# Clone the repository
git clone https://github.com/RuHRabin/xkb-avro.git
cd bn-avro-xkb

# Run the installer with sudo
chmod +x install-bn-avro.sh
sudo bash install-bn-avro.sh
```

The script will:
1. Copy `bn_avro` to `/usr/share/X11/xkb/symbols/`
2. Register the layout in `evdev.lst`
3. Register the layout in `evdev.xml`
4. Verify the installation

### Option B — Manual (Step by Step)

**Step 1 — Copy the symbols file:**

```bash
sudo cp bn_avro /usr/share/X11/xkb/symbols/bn_avro
sudo chown root:root /usr/share/X11/xkb/symbols/bn_avro
sudo chmod 644 /usr/share/X11/xkb/symbols/bn_avro
```

**Step 2 — Register in `evdev.lst`:**

```bash
sudo nano /usr/share/X11/xkb/rules/evdev.lst
```

Find the `! layout` section. After the line containing `bn`, add:

```
  bn_avro         Bengali (Avro Phonetic)
```

**Step 3 — Register in `evdev.xml`:**

```bash
sudo nano /usr/share/X11/xkb/rules/evdev.xml
```

Find the `<name>bn</name>` block. After its closing `</layout>` tag, paste:

```xml
<layout>
  <configItem>
    <name>bn_avro</name>
    <shortDescription>bn</shortDescription>
    <description>Bengali (Avro Phonetic)</description>
    <languageList>
      <iso639Id>ben</iso639Id>
    </languageList>
  </configItem>
  <variantList/>
</layout>
```

**Step 4 — Install Bengali font:**

```bash
sudo apt install fonts-noto-core
fc-cache -fv
```

**Step 5 — Test immediately:**

```bash
setxkbmap -layout bn_avro
# Open Kate or any text editor and type — Bengali should appear
# Switch back to English:
setxkbmap -layout us
```

---

## ⚙️ KDE Plasma Setup (Persistent, with Language Switcher)

1. Open **System Settings → Input Devices → Keyboard**
2. Go to the **Layouts** tab
3. Check **"Configure layouts"**
4. Click **Add** → select **Bengali (Avro Phonetic)**
5. Under **Switching policy**, choose **Global**
6. Set a shortcut — recommended: `Super + Space`
7. Click **Apply**

From now on, press `Super + Space` to switch between English and Bengali at any time. The taskbar shows `us` or `bn` to indicate the active layout.

---

## 🌊 Wayland Support (KDE Plasma)

> Wayland replaces `setxkbmap` with compositor-level configuration.
> The **layout file and registration are identical** to X11 — only the activation method differs.

### Detect Your Session Type

```bash
echo $XDG_SESSION_TYPE
# Output: wayland  →  use the steps below
# Output: x11      →  use setxkbmap as described earlier
```

### Step 1 — Install the Layout (Same as X11)

The symbols file and `evdev.xml` registration are **identical** for both X11 and Wayland.
Run the same installer:

```bash
sudo bash install-bn-avro.sh
```

### Step 2 — Clear the XKB Cache

Wayland compositors cache the XKB database. After installing, clear it:

```bash
rm -rf ~/.cache/xkb/
```

### Step 3 — Apply via KDE System Settings (GUI)

This works on both X11 and Wayland and is the recommended method:

1. Open **System Settings → Keyboard → Layouts**
2. Check **"Configure layouts"**
3. Click **Add** → select **Bengali (Avro Phonetic)**
4. Set shortcut: **Super + Space**
5. Click **Apply**
6. **Log out and log back in**

### Step 4 — Apply via Command Line (Wayland, no GUI)

If you prefer the terminal or need to script it:

**KDE Plasma 6:**
```bash
# Add both English and Bengali layouts
kwriteconfig6 --file kxkbrc --group Layout --key Use true
kwriteconfig6 --file kxkbrc --group Layout --key LayoutList "us,bn_avro"
kwriteconfig6 --file kxkbrc --group Layout --key VariantList ","
kwriteconfig6 --file kxkbrc --group Layout --key DisplayNames ","
kwriteconfig6 --file kxkbrc --group Layout --key SwitchMode "Global"
kwriteconfig6 --file kxkbrc --group Layout --key Options "grp:super_space_toggle"

# Reload KDE keyboard settings without logout
dbus-send --session --dest=org.kde.keyboard /Layouts     org.kde.KeyboardLayouts.reloadConfig
```

**KDE Plasma 5:**
```bash
kwriteconfig5 --file kxkbrc --group Layout --key Use true
kwriteconfig5 --file kxkbrc --group Layout --key LayoutList "us,bn_avro"
kwriteconfig5 --file kxkbrc --group Layout --key VariantList ","
kwriteconfig5 --file kxkbrc --group Layout --key DisplayNames ","
kwriteconfig5 --file kxkbrc --group Layout --key SwitchMode "Global"
kwriteconfig5 --file kxkbrc --group Layout --key Options "grp:super_space_toggle"

# Reload
qdbus org.kde.keyboard /Layouts reloadConfig
```

> **`grp:super_space_toggle`** means `Super + Space` switches between layouts.
> Change to `grp:alt_shift_toggle` or `grp:ctrl_shift_toggle` if preferred.

### Step 5 — Verify on Wayland

```bash
# Check active layout (Wayland-safe method)
cat ~/.config/kxkbrc | grep -E "LayoutList|Use="

# Expected output:
# LayoutList=us,bn_avro
# Use=true
```

> **Note:** `setxkbmap -query` does NOT work on a pure Wayland session.
> Use `cat ~/.config/kxkbrc` to verify instead.

### GNOME Wayland (Bonus)

If you use GNOME on Wayland instead of KDE:

```bash
# Add layouts (GNOME uses gsettings)
gsettings set org.gnome.desktop.input-sources     sources "[('xkb', 'us'), ('xkb', 'bn_avro')]"

# Set shortcut to Super+Space
gsettings set org.gnome.desktop.wm.keybindings     switch-input-source "['<Super>space']"
```

### X11 vs Wayland — Difference Summary

| Action | X11 | Wayland (KDE) |
|---|---|---|
| Install layout file | `sudo cp bn_avro ...` | Same |
| Register in evdev.xml | `sudo nano evdev.xml` | Same |
| Test immediately | `setxkbmap -layout bn_avro` | Not available |
| Permanent setup | KDE Settings GUI | KDE Settings GUI (same) |
| Command-line setup | `setxkbmap` | `kwriteconfig6` + D-Bus |
| Verify active layout | `setxkbmap -query` | `cat ~/.config/kxkbrc` |
| After install | No reboot needed | Log out required |
| Cache to clear | Not needed | `rm -rf ~/.cache/xkb/` |


## ⌨️ Complete Key Map

> **Right Alt (AltGr) activates Level 3 and Level 4.**

```
 ════╤══════════════╤══════════════╤════════════════╤════════════════
 Key │ Normal (L1)  │ Shift (L2)   │ AltGr (L3)     │ Shift+AltGr (L4)
 ════╪══════════════╪══════════════╪════════════════╪════════════════
  Q  │ ক  ka        │ খ  kha       │ ক               │ খ
  W  │ ও  o         │ ঔ  ou        │ ো  o-mātrā      │ ৌ  ou-mātrā
  E  │ এ  e         │ ঐ  oi        │ ে  e-mātrā       │ ৈ  oi-mātrā
  R  │ র  ra        │ ড়  rra       │ ৃ  ri-mātrā     │ ঢ়  rha
  T  │ ত  ta        │ ট  tta       │ থ  tha           │ ঠ  ttha
  Y  │ য়  yya       │ য  ya        │ য়               │ য
  U  │ উ  u         │ ঊ  uu        │ ু  u-mātrā      │ ূ  uu-mātrā
  I  │ ই  i         │ ঈ  ii        │ ি  i-mātrā      │ ী  ii-mātrā
  O  │ ও  o         │ ঔ  ou        │ ো  o-mātrā      │ ৌ  ou-mātrā
  P  │ প  pa        │ ফ  pha       │ প               │ ফ
  [  │ [            │ {            │ ৎ  khanda-ta    │ ্  hasanta
  ]  │ ]            │ }            │ ।  daari         │ ॥  double daari
 ════╪══════════════╪══════════════╪════════════════╪════════════════
  A  │ অ  a         │ আ  aa        │ া  aa-mātrā     │ ঋ  vocalic-R
  S  │ স  sa        │ শ  sha       │ ষ  ssa          │ স
  D  │ দ  da        │ ড  dda       │ ধ  dha          │ ঢ  ddha
  F  │ ফ  pha       │ ফ            │ ফ               │ ফ
  G  │ গ  ga        │ ঘ  gha       │ ঙ  nga          │ ঞ  nya
  H  │ হ  ha        │ ঃ  visarga   │ ঁ  chandrabindu │ ং  anusvara
  J  │ জ  ja        │ ঝ  jha       │ ঞ  nya          │ জ
  K  │ ক  ka        │ খ  kha       │ ক               │ খ
  L  │ ল  la        │ ল            │ ল               │ ল
 ════╪══════════════╪══════════════╪════════════════╪════════════════
  Z  │ জ  ja/z      │ য  ya/Z      │ জ               │ য
  X  │ ক             │ ষ  ssa       │ ্  hasanta      │ স  sa
  C  │ চ  ca        │ ছ  cha       │ চ               │ ছ
  V  │ ভ  bha/v     │ ভ            │ ব  ba           │ ভ
  B  │ ব  ba        │ ভ  bha       │ ব               │ ভ
  N  │ ন  na        │ ণ  nna       │ ঙ  nga          │ ঞ  nya
  M  │ ম  ma        │ ম            │ ম               │ ম
  ,  │ ,            │ <            │ ।  daari         │ ।
  .  │ .            │ >            │ ॥  double daari  │ ॥
  /  │ /            │ ?            │ ্  hasanta (alt) │ ষ  ssa
  \  │ ্  HASANTA ★ │ ়  nukta     │ ।  daari         │ ॥  double daari
 ════╪══════════════╪══════════════╪════════════════╪════════════════
 SPC │ space        │ space        │ ZWNJ (U+200C)   │ ZWJ (U+200D)
 ════╧══════════════╧══════════════╧════════════════╧════════════════

 AltGr + 0–9  →  ০ ১ ২ ৩ ৪ ৫ ৬ ৭ ৮ ৯   (Bengali digits)
 AltGr + =    →  ৳  (Bengali Taka sign)
 AltGr + `    →  ়  (Nukta diacritic)
 Shift+AltGr+`→  ঁ  (Chandrabindu)
```

---

## ✍️ How to Type Conjuncts (যুক্তব্যঞ্জন)

Use **Backslash `\`** as the Hasanta key to join consonants:

```
ক + \ + ত  =  ক্ত   (kta)
প + \ + র  =  প্র   (pra)
ন + \ + ত  =  ন্ত   (nta)
স + \ + ক  =  স্ক   (ska)
ম + \ + ব  =  ম্ব   (mba)
ত + \ + ব  =  ত্ব   (tba)
```

The Hasanta sign is **invisible** when a valid conjunct forms — the font merges the glyphs automatically.

### Show Hasanta Visibly

To display a visible Hasanta sign (ক্‌) without forming a conjunct:

```
ক + \ + AltGr+Space  →  ক্‌
```

`AltGr+Space` inserts a **ZWNJ** (Zero Width Non-Joiner) which prevents ligature formation.

---

## 🔤 Unicode Characters Covered

This layout maps **80 Unicode code points**, covering all standard Bengali characters:

| Category | Characters |
|---|---|
| Independent Vowels | অ আ ই ঈ উ ঊ ঋ এ ঐ ও ঔ |
| Vowel Signs (mātrā) | া ি ী ু ূ ৃ ে ৈ ো ৌ |
| Consonants | ক খ গ ঘ ঙ চ ছ জ ঝ ঞ ট ঠ ড ঢ ণ ত থ দ ধ ন প ফ ব ভ ম য র ল শ ষ স হ |
| Nukta-form Letters | ড় ঢ় য় |
| Diacritics | ঁ ং ঃ ় |
| Special Signs | ্ (Hasanta) ৎ (Khanda Ta) |
| Punctuation | । ॥ |
| Digits | ০ ১ ২ ৩ ৪ ৫ ৬ ৭ ৮ ৯ |
| Currency | ৳ |
| Joiners | ZWNJ ZWJ |

---

## 🔧 Optional: XCompose for Digraph Sequences

For Avro-style phonetic digraph typing (e.g., `kh` → খ), use the included `bn-avro-xcompose` file with a Compose key.

### Setup

**1. Set a Compose key in KDE:**
System Settings → Keyboard → Advanced → Position of Compose key → choose **Menu key**

> ⚠️ Do **not** choose Right Alt — it is already used as AltGr (Level 3).

**2. Install the XCompose rules:**

```bash
# Back up existing file if any
[ -f ~/.XCompose ] && cp ~/.XCompose ~/.XCompose.bak

cp bn-avro-xcompose ~/.XCompose
# Log out and back in
```

### Available Sequences

| Compose Sequence | Output | Meaning |
|---|---|---|
| `Menu` + k + h | খ | kha |
| `Menu` + g + h | ঘ | gha |
| `Menu` + j + h | ঝ | jha |
| `Menu` + t + h | থ | tha |
| `Menu` + d + h | ধ | dha |
| `Menu` + s + h | শ | sha |
| `Menu` + p + h | ফ | pha |
| `Menu` + b + h | ভ | bha |
| `Menu` + n + g | ঙ | nga |
| `Menu` + k + t | ক্ত | kta (conjunct) |
| `Menu` + p + r | প্র | pra (conjunct) |
| `Menu` + . + . | । | daari |

Full list of sequences is inside the `bn-avro-xcompose` file.

---

## ⚠️ Important Limitation

XKB is a **static keymap**. It maps one key press to one character. Avro Phonetic's **sequential digraph engine** (where typing `k` then `h` automatically produces খ without a Compose key) requires a stateful input method daemon (IBus/Fcitx).

This layout is a **daemon-free alternative** — all characters are reachable, but via key levels (Shift/AltGr) rather than sequential letter combinations. The optional XCompose file partially bridges this gap for common combinations, at the cost of pressing the Compose key first.

---

## 🆙 After System Updates

The `xkb-data` package manages `evdev.lst` and `evdev.xml`. A system upgrade may overwrite your registrations (but will not touch your `bn_avro` symbols file). To re-apply:

```bash
sudo bash install-bn-avro.sh
```

---

## 🛠️ Troubleshooting

**Layout not appearing in KDE Settings:**
```bash
kbuildsycoca6 --noincremental   # KDE Plasma 6
# or
kbuildsycoca5 --noincremental   # KDE Plasma 5
# Then log out and back in
```

**`setxkbmap` reports unknown layout:**
```bash
grep bn_avro /usr/share/X11/xkb/rules/evdev.lst
grep bn_avro /usr/share/X11/xkb/rules/evdev.xml
# Both must return a result. If not, re-run the installer.
```

**Boxes instead of Bengali characters:**
```bash
sudo apt install fonts-noto-core && fc-cache -fv
```

**AltGr (Level 3) not working:**
```bash
xmodmap -pm | grep Mod5
# Should show ISO_Level3_Shift. If empty, reapply: setxkbmap -layout bn_avro
```

**Wayland session type check:**
On a Wayland session, `setxkbmap` does not work. Use `kwriteconfig6` (KDE Plasma 6) or `kwriteconfig5` (KDE Plasma 5) instead. See the [Wayland Support](#-wayland-support-kde-plasma) section above.

---

## 🤝 Contributing

Contributions are welcome! Some ideas:

- Add more XCompose sequences for common conjuncts
- Create a Wayland-compatible version
- Add support for Assamese characters (ৰ ৱ)
- Test on other desktop environments (GNOME, XFCE, i3)

Please open an issue or pull request.

---

## 📜 License

This project is released under the **MIT License**. See `LICENSE` for details.

The Avro Phonetic scheme is originally created by **OmicronLab** ([omicronlab.com](https://www.omicronlab.com)). This XKB layout is an independent adaptation and is not affiliated with OmicronLab.

---

## 🙏 Acknowledgements

- [OmicronLab](https://www.omicronlab.com) — creators of the original Avro Phonetic scheme
- [X.Org XKB documentation](https://www.x.org/wiki/XKB/) — XKB specification and format reference
- The Bengali open-source community

---

*Made with ❤️ for the Bengali Linux community*
