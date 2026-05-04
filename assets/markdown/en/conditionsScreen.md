## Shooting Conditions

![Shooting conditions](resource:assets/markdown/en/conditionsScreen_overview.png)

The Conditions screen lets you set atmospheric parameters, powder temperature sensitivity, and the Coriolis effect correction. All values immediately affect the adjustments calculated on the Home screen.

---

### Temperature

![Temperature](resource:assets/markdown/en/conditionsScreen_temperature.png)

A large central control for air temperature. Swipe up or down to change the value, or tap to enter an exact number.

---

### Altitude, Humidity, Pressure

![Altitude, humidity, pressure](resource:assets/markdown/en/conditionsScreen_atmo.png)

Three buttons for entering atmospheric conditions:

- **Altitude** — elevation above sea level
- **Humidity** — relative air humidity (%)
- **Pressure** — atmospheric pressure

Tap any button to open the value input with unit selection.

---

### Powder Temperature Sensitivity

![Powder sensitivity](resource:assets/markdown/en/conditionsScreen_powderSens.png)

This section accounts for the change in muzzle velocity depending on powder temperature.

**"Powder Sensitivity" toggle** — enables/disables the correction. The sensitivity value is set in the cartridge properties.

**"Different Powder Temperature" toggle:**
- **Off** — the air temperature entered above is used for the calculation
- **On** — allows setting a separate powder temperature (e.g. when ammunition is stored in a warm place but fired in the cold)

An info row below shows the current muzzle velocity (MV) at the given powder temperature.

---

### Coriolis Effect

![Coriolis effect](resource:assets/markdown/en/conditionsScreen_coriolis.png)

Accounts for bullet deflection due to Earth's rotation. Relevant at distances beyond 800–1000 m.

**"Coriolis Effect" toggle** — enables/disables the correction. Once enabled, two fields appear:

- **Latitude** — geographic latitude of the firing position (−90° to +90°)
- **Azimuth** — firing direction relative to north (0–360°)
