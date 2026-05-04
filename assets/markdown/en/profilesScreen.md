## Profiles

![Profiles screen](resource:assets/markdown/en/profilesScreen_overview.png)

A profile combines a **weapon**, **cartridge**, and **scope** into one preset. Switch between profiles to instantly switch between different rifle setups.

---

### Profile card

![Profile card](resource:assets/markdown/en/profilesScreen_card.png)

Each card shows the weapon, cartridge, and scope assigned to that profile. The active profile (used on the Home screen) is highlighted.

- **Swipe left / right** — browse profiles
- **Dots indicator** — shows the current position; tap a dot to jump to that profile

The card contains three quick-action buttons:

| Button | Location | Action |
|---|---|---|
| **⋯** (more) | Top-right | Opens the edit menu (rename, duplicate, export, delete) |
| **Scope icon** | Top-left | Assign or change the scope for this profile |
| **Cartridge icon** | Bottom-right | Assign or change the cartridge for this profile |

At the bottom of the card:
- **Select** — set this profile as active and return to the Home screen
- **Go to calculations** — shown when the profile is already active; returns to Home

If the profile has no cartridge or scope assigned, the bottom bar shows a warning instead of the Select button.

---

### Profile menu (⋯)

| Action | Description |
|---|---|
| **Rename** | Change the profile name |
| **Duplicate** | Create a copy with a new name |
| **Export** | Save or share the profile as a file |
| **Delete** | Permanently remove the profile |

---

### Adding a profile

Tap **+** to open the add sheet:

- **Create new** — enter a name, then set up a new weapon from scratch
- **From collection** — enter a name, then pick a weapon from the saved collection
- **Import from file** — load a `.ebcp` or `.a7p` file from your device

---

### Exporting a profile

Choose a format in the export sheet:

- **.ebcp** — eBalistyka native format; preserves all data including scope and settings
- **.a7p** — Archer Ballistic Profile; requires a cartridge and scope to be set. Choose a distance range for the embedded trajectory table:

| Range | Distances |
|---|---|
| Subsonic | 25–400 m |
| Low | 100–700 m |
| Middle | 100–1000 m |
| Long | 100–1700 m |
| Ultra long | 100–2000 m |
