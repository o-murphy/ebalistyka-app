## Tables

### Trajectory Tab

![Trajectory table](resource:assets/markdown/en/tablesScreen_trajectory.png)

The table displays ballistic data for the current profile and shooting conditions across distances. The left column (range) is fixed — the remaining columns scroll horizontally.

**Row colour coding:**
- Normal row — flight data
- Highlighted (blue) — target distance (zero point)
- Red — trajectory zero crossing
- Yellow — subsonic transition

**Tap a row** to open a detail dialog with all values for that distance.

![Row details](resource:assets/markdown/en/tablesScreen_rowDetail.png)

**Top-right buttons:**
- ⚙️ — opens table settings (Trajectory tab only)
- ↗️ — exports the table as an HTML file

---

### Details Tab

![Profile details](resource:assets/markdown/en/tablesScreen_details.png)

Displays the parameters of the current profile used for the calculation:

- **Weapon** — name, calibre, twist rate, zero distance
- **Cartridge** — muzzle velocity (at zero and current)
- **Projectile** — drag model, ballistic coefficient, form factor, weight, length, gyroscopic stability
- **Conditions** — temperature, humidity, pressure, wind

---

### Table Settings

![Table settings](resource:assets/markdown/en/tablesScreen_config.png)

Opened via the ⚙️ button. Lets you customise the table layout and distance range.

**Distance:**
- Start, end, and step — define the table rows

**Extra tables:**
- **Zero crossing table** — shows a separate section with distances where the trajectory crosses zero
- **Subsonic transition** — highlights the row where the bullet goes subsonic

**Visible columns** — enable/disable individual metrics:
Time · Velocity · Height · Drop · Drop (Adjusted) · Wind · Wind (Adjusted) · Mach · Drag · Energy

**Adjustments** — units for adjustment columns:
mrad · MOA · mil · cm/100m · in/100yd · click
