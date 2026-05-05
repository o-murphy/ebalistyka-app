## New Cartridge / Cartridge Editor

![Ammo wizard overview](resource:assets/markdown/en/ammoWizard_overview.png)

Create or edit a cartridge preset. The form is divided into sections: **General**, **Projectile** (including drag model), **Cartridge** (muzzle velocity and powder sensitivity), **Zeroing conditions**, and optional **Coriolis correction**.

Tap **Save** (bottom-right) to confirm, or **Discard** (bottom-left) to cancel without changes.

---

### General

- **Name** — a label to identify this cartridge in your library
- **Vendor** — manufacturer name; used for filtering in the ammo library

---

### Projectile

![Projectile section](resource:assets/markdown/en/ammoWizard_projectile.png)

- **Projectile name** — bullet model or free-text designation
- **Caliber** — actual bullet diameter; inherited from the linked weapon profile and shown as read-only here
- **Weight** — bullet weight; affects energy, recoil, and trajectory calculations (required)
- **Length** — overall bullet length; used for gyroscopic stability and Miller/Berger stability factor calculations (required)

---

### Drag Model

![Drag model section](resource:assets/markdown/en/ammoWizard_dragModel.png)

Select the ballistic model that describes how this bullet decelerates through air:

| Model | Best for |
|-------|----------|
| **G1** | Flat-base, round-nose, or older sporting bullets |
| **G7** | Boat-tail long-range bullets — generally more accurate for modern rifle projectiles |
| **CUSTOM** | Any bullet with a known Mach → Cd drag table (e.g. from Doppler radar or manufacturer data) |

**G1 / G7 — Single BC**

Enter one ballistic coefficient that applies at all velocities. Quick to set up; accuracy may decrease in the transonic region.

**G1 / G7 — Multi-BC table**

Enable the **Multi-BC** toggle to enter a velocity-banded table of BC values. The app interpolates between breakpoints, improving accuracy across the full velocity envelope (supersonic → transonic → subsonic). Tap **Edit table** to open the breakpoint editor.

**CUSTOM drag table**

Tap **Edit custom drag table** to enter Mach → Cd pairs. The table must cover the bullet's full expected velocity range. Rows are sorted by Mach ascending on save.

---

### Cartridge

![Cartridge section](resource:assets/markdown/en/ammoWizard_cartridge.png)

- **Muzzle velocity** — measured or vendor-specified velocity at the muzzle, at the reference temperature below (required)
- **MV temperature** — ambient temperature at which the muzzle velocity was measured or specified; used as the reference point for powder sensitivity correction
- **Powder sensitivity** — enable this toggle to apply a temperature correction to MV; the sensitivity coefficient is set via the measurement table (see below)

---

### Powder Sensitivity (when enabled)

![Powder sensitivity section](resource:assets/markdown/en/ammoWizard_powderSens.png)

When the **Powder Sensitivity** toggle is on, an additional section appears:

- The current corrected MV at the given powder temperature is shown live
- **Different powder temperature** — toggle on to set a separate powder temperature (e.g. ammo stored warm but fired cold); when off, the air temperature from Conditions screen is used
- **Calculate from measurements** — tap to open the T → V measurement table; enter at least two temperature/velocity pairs measured at the range; the app calculates the sensitivity coefficient (%/15°C) automatically

---

### Zeroing Conditions

![Zeroing conditions section](resource:assets/markdown/en/ammoWizard_zeroing.png)

Atmospheric conditions recorded when the zero was established. The app uses these to compensate for the atmosphere shift between zeroing and current shooting conditions.

- **Zero distance** — the range at which the rifle was zeroed
- **Look angle** — vertical angle to the target during zeroing (0° = level ground)
- **Temperature** — air temperature at the zeroing location
- **Pressure** — atmospheric pressure at the zeroing location
- **Humidity** — relative air humidity at the zeroing location
- **Altitude** — elevation above sea level at the zeroing location

---

### Zeroing Offset

Fine-tune the zero by entering the number of clicks already dialled in at the zeroing range. Use this to shift the ballistic zero without re-entering a new zero distance.

- **Vertical offset** — click count (positive = up)
- **Horizontal offset** — click count (positive = right)
- **Click unit** — unit for the offset values; must match the scope's turret unit

---

### Coriolis Correction at Zero

![Coriolis section](resource:assets/markdown/en/ammoWizard_coriolis.png)

Enable **Coriolis effect** to account for Earth's rotation during zeroing. Relevant at distances beyond 800–1000 m.

- **Latitude** — geographic latitude of the zeroing location (−90° to +90°)
- **Azimuth** — firing direction relative to north (0–360°)
