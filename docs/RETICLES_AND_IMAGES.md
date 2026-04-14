# Reticles & Entity Images

---

## Entity Fields

### Sight

| Поле | Тип | Семантика |
|---|---|---|
| `reticleImage` | `String?` | Ідентифікатор типу сітки (наприклад `"IHR"`, `"DDR-2"`, `"MIL-XT"`). Береться з `collection.json`, зберігається в OB. Формат — рядок-ідентифікатор, не шлях і не base64. |
| `calibratedMagnification` | `double` | Збільшення, при якому откалібровано сітку (актуально для SFP прицілів). `-1.0` = не задано. |
| `image` | `String?` | Зображення прицілу (фото, арт). Формат TBD. Зараз — `null` скрізь, в UI — стаб. |

### Weapon

| Поле | Тип | Семантика |
|---|---|---|
| `image` | `String?` | Зображення зброї. Формат TBD. Зараз — `null` скрізь, в UI — стаб. |

### Ammo

| Поле | Тип | Семантика |
|---|---|---|
| `image` | `String?` | Зображення набою/кулі. Формат TBD. Зараз — `null` скрізь, в UI — стаб. |

---

## Built-in Collection — reticleImage

У `assets/json/collection.json` у кожного сайту є поля `reticleImage` та `calibratedMagnification`:

```json
{
  "name": "Nightforce ATACR 2.5-10x32",
  "reticleImage": "IHR",
  "calibratedMagnification": 10,
  "focalPlaneValue": "sfp",
  ...
}
```

Приклади ідентифікаторів: `"IHR"`, `"DDR-2"`, `"NP-RF1"`, `"LV.5"`, `"MIL-XT"`.

`reticleImage` зараз — просто рядок, що зберігається в OB. Як саме він буде використовуватись для відображення — не визначено.

---

## Поточний стан UI

### HomeReticlePage (`lib/features/home/widgets/home_reticle_page.dart`)

Page 1 (з трьох) HomeScreen. Складається з двох частин:

**`_ReticleView`** — займає 2/3 ширини, квадратний `AspectRatio(1)`:
- Рендериться через `CustomPaint(_ReticlePainter)`
- **Хардкодована** проста сітка: коло + хрест з gap по центру + 3 риски на кожній осі
- Не підключена до `Sight.reticleImage` або будь-яких даних entity
- `shouldRepaint` — тільки якщо змінився `ColorScheme`

**`_AdjPanel`** — займає 1/3 ширини:
- ✅ Функціональна: показує Drop і Windage з `homeVmProvider` (`AdjustmentData`)
- Формат відображення (`AdjustmentDisplayFormat`): arrows / signs / letters — з налаштувань
- Якщо `elevation.isEmpty` — показує `'Enable units...'`

---

## packages/reticle_gen

Розташування: `packages/reticle_gen/`

**Поточний статус: standalone CLI-інструмент, не інтегрований у Flutter-додаток.**

Використовує `dart:io` для запису SVG у файл — не може безпосередньо використовуватись як Flutter widget.

### Архітектура

```
CanvasInterface       — абстрактний API: line, rect, circle, path, text, fill
    └── SVGCanvas     — реалізація через xml (XmlElement)
                        viewBox центрований: (-w/2, -h/2, w, h)

DrawerInterface       — draw(CanvasInterface canvas)
    ├── CrossDrawer       — простий хрест
    ├── ScopeDrawer       — хрест + коло + розмітка по колу
    ├── CompositeDrawer   — комбінація кількох Drawer
    └── MilReticleDrawer  — MIL сітка (-10..+10 мілів по обох осях, риски кожний 1 MIL)

MilReticleCanvas      — SVGCanvas з factor (координати у мілах, виводяться * factor)
    └── drawAdjustment(x, y)  — малює червону крапку на заданому зміщенні в мілах
```

### MilReticleCanvas — система координат

```dart
MilReticleCanvas(milWidth: 30, milHeight: 30, factor: 100)
// → SVG 3000×3000 px, viewBox (-1500, -1500, 3000, 3000)
// Координати у drawer — в мілах: line(-10, 0, 10, 0, ...) = 10 MIL вліво/вправо

drawAdjustment(0.53, 4.6)  // → червона крапка на 0.53 MIL вправо, 4.6 MIL вниз
```

### Поточне використання

Тільки в `bin/mil_reticle.dart` — генерує `final.svg` у файлову систему. Proof-of-concept.

---

## Wizard Placeholder Widgets

У кожному wizard-екрані є placeholder-картка замість реального зображення:

| Wizard | Клас | Поточний вміст |
|---|---|---|
| `WeaponWizardScreen` | `_RiflePlaceholder` | `Icon(IconDef.image)` + текст `'Rifle image'` |
| `SightWizardScreen` | `_SightPlaceholder` | `Icon(IconDef.sight)` + текст `'Sight image'` |
| `AmmoWizardScreen` | `_AmmoPlaceholder` | `Icon(IconDef.ammo)` + текст `'Ammo image'` |

Всі три — статичні `StatelessWidget`, не підключені до entity `.image` поля.

---

## TODO (не визначено)

- [ ] Реалізація відображення ретіклів і поправок на них — **архітектура і підхід TBD**
- [ ] Формат і сховище для `entity.image` (Weapon/Sight/Ammo) — **TBD** (файлова система / база64 / asset)
- [ ] Підключення `reticle_gen` до Flutter (заміна `dart:io` на Flutter-сумісний підхід, або `flutter_svg`)
- [ ] Image picker / camera UI у wizard screens
