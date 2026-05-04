## Reticle View

Visualises your scope reticle with the calculated holdover applied, and lets you configure the scope and target settings.

![overview](resource:assets/markdown/en/reticleScreen_overview.png)

---

### Reticle view

The top panel shows your reticle with the target overlaid at the correct angular size. The dot or crosshair is shifted by the calculated elevation and wind holdover.

- **Pinch / scroll** — zoom in for a closer look
- **Double-tap** — zoom to 3×, double-tap again to reset
- **Reset button** (bottom-right) — returns to 1× zoom

---

### Holdovers

Shows the elevation and windage adjustments calculated for the current conditions and distance.

---

### Manual adjustments

Additional offset you apply on top of the calculated holdover — for example, to account for a zeroing shift or point-of-impact correction.

- **Vertical / Horizontal** — enter a value in the chosen unit (mil, MOA, clicks, etc.)
- Switching to **clicks** mode divides the value by the click size of the active scope

---

### Target

- **Target pattern** — the silhouette displayed inside the reticle view
- **Target size** — the angular size of the target at the set distance (read-only, computed from the profile)

---

### Reticle

- **Reticle pattern** — the SVG reticle overlay drawn over the target; matches the reticle saved in the active profile

---

### Clicks

The click values used when **clicks** mode is selected for adjustments. They come from the active scope profile and can be edited here.

- **Vertical click** — angular value of one turret click on the elevation axis
- **Horizontal click** — angular value of one turret click on the windage axis
