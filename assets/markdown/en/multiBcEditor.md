## Multi-BC Table

Defines how the ballistic coefficient (BC) changes with bullet velocity. More breakpoints give a more accurate drag model across the full velocity range.

Each row is a **velocity → BC** pair. The table is sorted by velocity descending on save.

---

### Filling the table

- Enter velocity in the left column and the corresponding BC in the right column
- Leave unused rows blank — they are ignored on save
- The first row is pre-filled with the current muzzle velocity and single BC as a starting point

---

### Tips

- Add at least 2–3 breakpoints from manufacturer data or measured data for meaningful improvement over a single BC
- Rows with zero or invalid values are skipped automatically
