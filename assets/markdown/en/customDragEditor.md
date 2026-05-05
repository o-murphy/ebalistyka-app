## Custom Drag Table

Defines the drag function as a series of **Mach number → drag coefficient (Cd)** pairs. This model replaces the standard G1/G7 drag functions entirely and allows for a bullet-specific drag curve.

The table is sorted by Mach ascending on save.

---

### Filling the table

- Enter Mach number in the left column and the corresponding Cd in the right column
- Leave unused rows blank — they are ignored on save
- Rows with zero or invalid values are skipped automatically

---

### Tips

- Custom drag data is typically obtained from manufacturer specifications, doppler radar measurements, or external ballistic software
- More data points across the full velocity range (supersonic, transonic, subsonic) give the most accurate results
