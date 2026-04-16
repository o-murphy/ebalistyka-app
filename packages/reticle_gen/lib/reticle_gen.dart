import 'dart:math';

import 'package:xml/xml.dart';
import 'dart:io';

extension SvgExport on XmlElement {
  void export([String? filePath]) {
    File(filePath ?? 'temp.svg').writeAsStringSync(toXmlString(pretty: true));
  }
}

/// Інтерфейс для малювання на канвасі
abstract interface class CanvasInterface {
  /// Малює лінію
  void line(
    double x1,
    double y1,
    double x2,
    double y2,
    String stroke,
    double strokeWidth,
  );

  /// Малює прямокутник
  void rect(
    double x,
    double y,
    double w,
    double h,
    String fill, {
    String? stroke,
    double? strokeWidth,
  });

  /// Заповнює весь канвас кольором
  void fill(String fill);

  /// Малює коло
  void circle(
    double cx,
    double cy,
    double r,
    String fill, {
    String? stroke,
    double? strokeWidth,
  });

  /// Малює шлях
  void path(String d, String fill, {String? stroke, double? strokeWidth});

  /// Додає текст
  void text(
    String content,
    double x,
    double y,
    String fill, {
    double fontSize,
    String textAnchor,
  });

  /// Малює [draw] з обрізанням по формі [shape].
  /// Форма описується тими ж методами канвасу; колір fill/stroke ігнорується.
  void clip({
    required void Function(CanvasInterface canvas) shape,
    required void Function(CanvasInterface canvas) draw,
  });
}

abstract interface class DrawerInterface {
  void draw(CanvasInterface canvas);
}

class SVGCanvas implements CanvasInterface {
  final double width;
  final double height;
  late final XmlElement _svgElement;
  late XmlElement _target;
  int _clipCounter = 0;

  SVGCanvas({this.width = 640.0, this.height = 640.0});

  XmlElement get svg => _svgElement;

  /// Поточний контейнер для запису елементів.
  /// Підкласи, що додають елементи напряму, мають використовувати його.
  XmlElement get target => _target;

  XmlElement generate(DrawerInterface drawer) {
    final double minX = -width / 2;
    final double minY = -height / 2;

    _svgElement = XmlElement(XmlName('svg'), [
      XmlAttribute(XmlName('xmlns'), 'http://www.w3.org/2000/svg'),
      XmlAttribute(XmlName('width'), width.toString()),
      XmlAttribute(XmlName('height'), height.toString()),
      XmlAttribute(XmlName('viewBox'), '$minX $minY $width $height'),
    ]);
    _target = _svgElement;

    drawer.draw(this);

    return _svgElement;
  }

  @override
  void line(
    double x1,
    double y1,
    double x2,
    double y2,
    String stroke,
    double strokeWidth,
  ) {
    _target.children.add(
      XmlElement(XmlName('line'), [
        XmlAttribute(XmlName('x1'), x1.toString()),
        XmlAttribute(XmlName('y1'), y1.toString()),
        XmlAttribute(XmlName('x2'), x2.toString()),
        XmlAttribute(XmlName('y2'), y2.toString()),
        XmlAttribute(XmlName('stroke'), stroke),
        XmlAttribute(XmlName('stroke-width'), strokeWidth.toString()),
      ]),
    );
  }

  @override
  void rect(
    double x,
    double y,
    double w,
    double h,
    String fill, {
    String? stroke,
    double? strokeWidth,
  }) {
    _target.children.add(
      XmlElement(XmlName('rect'), [
        XmlAttribute(XmlName('x'), x.toString()),
        XmlAttribute(XmlName('y'), y.toString()),
        XmlAttribute(XmlName('width'), w.toString()),
        XmlAttribute(XmlName('height'), h.toString()),
        XmlAttribute(XmlName('fill'), fill),
        if (stroke != null) XmlAttribute(XmlName('stroke'), stroke),
        if (strokeWidth != null)
          XmlAttribute(XmlName('stroke-width'), strokeWidth.toString()),
      ]),
    );
  }

  @override
  void fill(String fill) => rect(-width / 2, -height / 2, width, height, fill);

  @override
  void circle(
    double cx,
    double cy,
    double r,
    String fill, {
    String? stroke,
    double? strokeWidth,
  }) {
    _target.children.add(
      XmlElement(XmlName('circle'), [
        XmlAttribute(XmlName('cx'), cx.toString()),
        XmlAttribute(XmlName('cy'), cy.toString()),
        XmlAttribute(XmlName('r'), r.toString()),
        XmlAttribute(XmlName('fill'), fill),
        if (stroke != null) XmlAttribute(XmlName('stroke'), stroke),
        if (strokeWidth != null)
          XmlAttribute(XmlName('stroke-width'), strokeWidth.toString()),
      ]),
    );
  }

  @override
  void path(String d, String fill, {String? stroke, double? strokeWidth}) {
    _target.children.add(
      XmlElement(XmlName('path'), [
        XmlAttribute(XmlName('d'), d),
        XmlAttribute(XmlName('fill'), fill),
        if (stroke != null) XmlAttribute(XmlName('stroke'), stroke),
        if (strokeWidth != null)
          XmlAttribute(XmlName('stroke-width'), strokeWidth.toString()),
      ]),
    );
  }

  @override
  void text(
    String content,
    double x,
    double y,
    String fill, {
    double fontSize = 12,
    String textAnchor = 'middle',
  }) {
    _target.children.add(
      XmlElement(
        XmlName('text'),
        [
          XmlAttribute(XmlName('x'), x.toString()),
          XmlAttribute(XmlName('y'), y.toString()),
          XmlAttribute(XmlName('fill'), fill),
          XmlAttribute(XmlName('font-size'), fontSize.toString()),
          XmlAttribute(XmlName('text-anchor'), textAnchor),
        ],
        [XmlText(content)],
      ),
    );
  }

  /// Обрізає вміст [draw] по формі [shape].
  /// Генерує `<clipPath>` та `<g clip-path="url(#...)">` без використання `<defs>`.
  @override
  void clip({
    required void Function(CanvasInterface canvas) shape,
    required void Function(CanvasInterface canvas) draw,
  }) {
    final id = 'clip${_clipCounter++}';

    // Визначення форми обрізання
    final clipPathEl = XmlElement(XmlName('clipPath'), [
      XmlAttribute(XmlName('id'), id),
    ]);
    final prevTarget = _target;
    _target = clipPathEl;
    shape(this);
    _target = prevTarget;
    _svgElement.children.add(clipPathEl);

    // Група з застосованим clip
    final groupEl = XmlElement(XmlName('g'), [
      XmlAttribute(XmlName('clip-path'), 'url(#$id)'),
    ]);
    _target = groupEl;
    draw(this);
    _target = prevTarget;
    _svgElement.children.add(groupEl);
  }
}

class CrossDrawer implements DrawerInterface {
  final double size;
  final double strokeWidth;
  final String color;

  CrossDrawer({this.size = 200, this.strokeWidth = 2, this.color = 'red'});

  @override
  void draw(CanvasInterface canvas) {
    canvas
      // Горизонтальна лінія через центр
      ..line(-size / 2, 0, size / 2, 0, color, strokeWidth)
      // Вертикальна лінія через центр
      ..line(0, -size / 2, 0, size / 2, color, strokeWidth);
  }
}

// Хрест з колом (як приціл)
class ScopeDrawer extends DrawerInterface {
  final double radius;
  final double lineLength;
  final double strokeWidth;
  final String color;

  ScopeDrawer({
    this.radius = 100,
    this.lineLength = 150,
    this.strokeWidth = 2,
    this.color = '#00FF00',
  });

  @override
  void draw(CanvasInterface canvas) {
    final diagLength = radius * 0.7;

    canvas
      // Зовнішнє коло
      ..circle(0, 0, radius, 'none', stroke: color, strokeWidth: strokeWidth)
      // Хрест
      ..line(-lineLength / 2, 0, lineLength / 2, 0, color, strokeWidth)
      ..line(0, -lineLength / 2, 0, lineLength / 2, color, strokeWidth)
      // Діагональні лінії (опційно)
      ..line(
        -diagLength,
        -diagLength,
        diagLength,
        diagLength,
        color,
        strokeWidth * 0.7,
      )
      ..line(
        -diagLength,
        diagLength,
        diagLength,
        -diagLength,
        color,
        strokeWidth * 0.7,
      )
      // Центральна точка
      ..circle(0, 0, strokeWidth * 2, color);

    // Розмітка (риски на колі)
    for (int i = 0; i < 360; i += 30) {
      final rad = i * 3.14159 / 180;
      final x1 = radius * cos(rad);
      final y1 = radius * sin(rad);
      final x2 = (radius - 10) * cos(rad);
      final y2 = (radius - 10) * sin(rad);
      canvas.line(x1, y1, x2, y2, color, strokeWidth * 0.5);
    }
  }
}

// Комбінований drawer (можна комбінувати кілька)
class CompositeDrawer extends DrawerInterface {
  final List<DrawerInterface> drawers;

  CompositeDrawer(this.drawers);

  @override
  void draw(CanvasInterface canvas) {
    for (var drawer in drawers) {
      drawer.draw(canvas);
    }
  }
}

// Приклад кастомного drawer для малювання галактики
class _CustomGalaxyDrawer extends DrawerInterface {
  @override
  void draw(CanvasInterface canvas) {
    final random = Random();

    // Малюємо фоновий градієнт (через rect)
    canvas.rect(-400, -400, 800, 800, '#0a0a2a');

    // Малюємо спіраль галактики
    for (double r = 20; r <= 300; r += 15) {
      final angle = r * 0.1;
      final x = r * cos(angle);
      final y = r * sin(angle);

      canvas.circle(x, y, 2, 'white', stroke: 'cyan', strokeWidth: 0.5);

      // Друге плече спіралі
      final x2 = r * cos(angle + 3.14159);
      final y2 = r * sin(angle + 3.14159);
      canvas.circle(x2, y2, 2, 'white', stroke: 'cyan', strokeWidth: 0.5);
    }

    // Додаємо зірки випадково
    for (int i = 0; i < 500; i++) {
      final x = random.nextDouble() * 700 - 350;
      final y = random.nextDouble() * 700 - 350;
      final brightness = random.nextDouble() * 0.5 + 0.5;
      final size = random.nextDouble() * 2 + 0.5;

      canvas.circle(x, y, size, 'rgba(255,255,255,$brightness)');
    }

    // Ядро галактики
    for (int i = 0; i < 100; i++) {
      final angle = random.nextDouble() * 2 * 3.14159;
      final r = random.nextDouble() * 30;
      final x = r * cos(angle);
      final y = r * sin(angle);
      canvas.circle(
        x,
        y,
        random.nextDouble() * 3 + 1,
        'rgba(255,200,100,${random.nextDouble() * 0.8 + 0.2})',
      );
    }
  }
}

void main() {
  // Приклад 1: Простий хрест
  print('Створюємо SVG з простим хрестом...');
  final crossDrawer = CrossDrawer(size: 300, strokeWidth: 3, color: '#FF0000');
  SVGCanvas().generate(crossDrawer).export('cross.svg');

  // Приклад 2: Приціл з колом
  print('Створюємо SVG з прицілом...');
  final scopeDrawer = ScopeDrawer(
    radius: 200,
    lineLength: 350,
    strokeWidth: 2,
    color: '#00FF00',
  );
  SVGCanvas().generate(scopeDrawer).export('scope.svg');

  // Приклад 3: Комбінований малюнок
  print('Створюємо SVG з комбінованим малюнком...');
  final combinedDrawer = CompositeDrawer([
    ScopeDrawer(
      radius: 250,
      lineLength: 450,
      strokeWidth: 1.5,
      color: '#FF6600',
    ),
    CrossDrawer(size: 100, strokeWidth: 1, color: '#FFFFFF'),
  ]);
  SVGCanvas().generate(combinedDrawer).export('combined.svg');

  // Приклад 4: Кастомний малюнок (галактика)
  print('Створюємо SVG з кастомним малюнком...');
  final customDrawer = _CustomGalaxyDrawer();
  SVGCanvas().generate(customDrawer).export('galaxy.svg');

  print('Всі SVG файли успішно створено!');
  print('- cross.svg');
  print('- scope.svg');
  print('- combined.svg');
  print('- galaxy.svg');
}
