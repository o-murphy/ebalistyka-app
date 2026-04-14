# Post-Alpha UX Features

Функції, які не є блокерами альфа-релізу. Архітектура і підхід для кожної — TBD.

---

## Localization uk/en

- ARB + `flutter_localizations`
- Мови: Ukrainian (основна) + English
- Охоплює всі UI-рядки, включно з назвами одиниць, помилками валідації, label-ами

---

## RulerSelector

Touch-drag ruler для `QuickActionsPanel` на HomeScreen.
Замінює або доповнює поточні кнопки швидкого доступу.
Деталі взаємодії — TBD.

---

## Reticle Fullscreen

Відкривається з Home Page 1 (HomeReticlePage).
Повноекранний вигляд сітки прицілу з поправками.
Залежить від реалізації відображення ретіклів — див. [RETICLES_AND_IMAGES.md](RETICLES_AND_IMAGES.md).

---

## Help Overlay / Coach Marks

Підказки при першому запуску або за запитом користувача.
Бібліотека TBD (наприклад `tutorial_coach_mark`).

---

## Tools Screen

Відкривається з кнопки "More" на HomeScreen (наразі `showNotAvailableSnackBar`).
Набір утиліт — склад TBD.

---

## Settings — Legal / Info Links

- Privacy Policy
- Terms of Use
- Changelog
- GitHub посилання (мінімум для альфи — може переїхати в Alpha TODO)
