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

У `assets/json/collection.json` у кожного sight є поля `reticleImage` та `calibratedMagnification`:

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

`reticleImage` зараз — просто рядок, що зберігається в OB. Як саме він буде використовуватись для відображення конкретної сітки — **не визначено**. Планується: кожен ідентифікатор відповідає SVG-файлу з `assets/reticles/`.

---

## packages/reticle_gen

Розташування: `packages/reticle_gen/`

**Поточний статус: standalone CLI-інструмент, частково реалізований. Планується розширення для генерації всіх SVG-сіток колекції.**

Використовує `dart:io` для запису SVG у файл — не може безпосередньо використовуватись як Flutter widget.

### Архітектура

```
CanvasInterface       — абстрактний API: line, rect, circle, path, text, fill, clip
    └── SVGCanvas     — реалізація через xml (XmlElement)
                        viewBox центрований: (-w/2, -h/2, w, h)
                        _target — поточний контейнер запису (svg / clipPath / group)

DrawerInterface       — draw(CanvasInterface canvas)
    ├── CrossDrawer       — простий хрест
    ├── ScopeDrawer       — хрест + коло + розмітка по колу
    ├── CompositeDrawer   — комбінація кількох Drawer
    └── MilReticleDrawer  — MIL сітка (перший варіант, тестовий)

MilReticleCanvas      — SVGCanvas з factor (координати у мілах, виводяться * factor)
    └── drawAdjustment(x, y)  — малює крапку на заданому зміщенні в мілах
```

### clip()

SVG клiпування через `<clipPath>`. API:

```dart
canvas.clip(
  shape: (c) => c.circle(0, 0, 15, 'white'),  // форма обрізки
  draw: (c) {
    c.line(...);  // вміст, обрізаний по формі
  },
);
```

Генерує `<clipPath id="clipN">` + `<g clip-path="url(#clipN)">` безпосередньо в SVG (без `<defs>`).
Підкласи `SVGCanvas`, що додають елементи напряму, мають використовувати `target.children.add(...)` замість `svg.children.add(...)`.

### MilReticleCanvas — система координат

```dart
MilReticleCanvas(milWidth: 30, milHeight: 30, factor: 100)
// → SVG 3000×3000 px, viewBox (-1500, -1500, 3000, 3000)
// Координати у drawer — в мілах: line(-10, 0, 10, 0, ...) = 10 MIL вліво/вправо

drawAdjustment(0.53, 4.6)  // → крапка на 0.53 MIL вправо, 4.6 MIL вниз
```

Всі методи (`line`, `rect`, `circle`, `text`, `path`) автоматично масштабують координати та товщини на `factor`.

### Кастомні SVG-атрибути (self-describing reticle)

`MilReticleCanvas.generate()` додає до кореневого `<svg>`:

| Атрибут | Значення |
|---------|---------|
| `data-mil-width` | Ширина канвасу в мілах (default `30.0`) |
| `data-mil-height` | Висота канвасу в мілах (default `30.0`) |
| `data-factor` | Масштабний фактор (default `100`) |
| `shape-rendering` | `crispEdges` |

Flutter зчитує ці атрибути через `_parseSvgMeta()` для правильного обчислення координат поправки без хардкоду.

### MilReticleDrawer — перший варіант (тестовий)

- Зовнішнє коло r=15 MIL — обідок + clip-path
- Горизонтальна вісь: лінія −10..+10, риски кожний 1 MIL, числові підписи над рискою (парні)
- Вертикальна вісь: лінія −10..+14, риски кожний 1 MIL, числові підписи зліва (парні)
- Весь вміст обрізається по колу; обідок малюється поверх

### Кольори в SVG

Замість хардкодованих кольорів — семантичні ролі Material ColorScheme як рядки:

```dart
const String color = "onSurface";
canvas.line(-10, 0, 10, 0, color, thickness);
// → stroke="onSurface" в SVG
```

Flutter замінює їх на `#rrggbb` при завантаженні (runtime string replace).

Підтримувані ролі: `onSurface`, `onBackground`, `primary`, `secondary`, `error`.

### Генерація SVG

```bash
dart run packages/reticle_gen/lib/default.dart assets/reticles/default.svg
```

---

## Поточний стан UI

### HomeReticlePage (`lib/features/home/widgets/home_reticle_page.dart`)

Page 1 (з трьох) HomeScreen. Складається з двох частин:

**`_ReticleView`** — займає 2/3 ширини, `AspectRatio(1)`:
- Завантажує `assets/reticles/default.svg` через `rootBundle` (один раз, `static Future`)
- **Runtime підміна кольорів:** замінює `"onSurface"` і т.д. на `#rrggbb` з поточного `ColorScheme`
- **Ін'єкція поправки:** вставляє 2 лінії + коло перед `</svg>` у системі координат SVG (`windMil * factor`, `elevMil * factor`)
- **OUT OF RANGE:** якщо поправка виходить за межі canvas — виводить текст замість індикатора
- Рендерить через `flutter_svg`: `SvgPicture.string(fit: BoxFit.contain, allowDrawingOutsideViewBox: true)`
- Колір поправки: `orangeAccent` (dark) / `deepOrangeAccent` (light)

**`_AdjPanel`** — займає 1/3 ширини:
- ✅ Функціональна: показує Drop і Windage з `homeVmProvider` (`AdjustmentData`)
- Формат (`AdjustmentDisplayFormat`): arrows / signs / letters — з налаштувань
- Якщо `elevation.isEmpty` — показує `'Enable units...'`

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

## TODO (Post-Alpha)

- [ ] Генерація SVG для всіх ідентифікаторів сіток з `collection.json` через `reticle_gen`
- [ ] Підключення `Sight.reticleImage` до відображення відповідного SVG-файлу
- [ ] Формат і сховище для `entity.image` (Weapon/Sight/Ammo) — TBD (файлова система / base64 / asset)
- [ ] Підключення `reticle_gen` до Flutter (заміна `dart:io` на Flutter-сумісний підхід, або pre-generate all)
- [ ] Image picker / camera UI у wizard screens
- [ ] Fullscreen reticle view — детальний перегляд з поправками
