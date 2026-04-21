import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';

/// Вертикальний wheel picker як у iOS
class UnitWheelPicker extends StatefulWidget {
  const UnitWheelPicker({
    super.key,
    required this.min,
    required this.max,
    required this.tick,
    required this.smallTick,
    required this.value,
    required this.onChanged,
    this.accuracy = 1,
    this.itemHeight = 32,
    this.horizontalPadding = 24,
    this.backgroundColor,
  });

  final double min, max, tick, smallTick, value;
  final int accuracy;
  final double itemHeight;
  final double horizontalPadding;
  final Color? backgroundColor;
  final ValueChanged<double> onChanged;

  @override
  State<UnitWheelPicker> createState() => _UnitWheelPickerState();
}

class _UnitWheelPickerState extends State<UnitWheelPicker> {
  late FixedExtentScrollController _controller;
  late List<double> _values;
  double _currentValue = 0;

  @override
  void initState() {
    super.initState();
    _generateValues();
    _currentValue = widget.value;
    _controller = FixedExtentScrollController(
      initialItem: _findClosestIndex(widget.value),
    );
  }

  @override
  void didUpdateWidget(UnitWheelPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.itemHeight != widget.itemHeight) {
      final newIndex = _findClosestIndex(_currentValue);
      _controller.dispose();
      _controller = FixedExtentScrollController(initialItem: newIndex);
    }
    if (oldWidget.min != widget.min ||
        oldWidget.max != widget.max ||
        oldWidget.smallTick != widget.smallTick) {
      _generateValues();
      final newIndex = _findClosestIndex(_currentValue);
      _controller.jumpToItem(newIndex);
    }
  }

  void _generateValues() {
    _values = [];
    double current = widget.min;
    while (current <= widget.max + 0.0001) {
      _values.add(current);
      current += widget.smallTick;
    }
  }

  int _findClosestIndex(double value) {
    if (_values.isEmpty) return 0;
    int closest = 0;
    double minDiff = double.infinity;
    for (int i = 0; i < _values.length; i++) {
      final diff = (_values[i] - value).abs();
      if (diff < minDiff) {
        minDiff = diff;
        closest = i;
      }
    }
    return closest;
  }

  bool _isMajorTick(double value) {
    final remainder = (value - widget.min) % widget.tick;
    return remainder.abs() < 0.0001 || (widget.tick - remainder).abs() < 0.0001;
  }

  void _onSelectedItemChanged(int index) {
    if (index >= 0 && index < _values.length) {
      setState(() {
        _currentValue = _values[index];
      });
      widget.onChanged(_values[index]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final visibleItems = 5;
    final totalHeight = widget.itemHeight * visibleItems;
    final centerOffset = (totalHeight - widget.itemHeight) / 2;

    return SizedBox(
      height: totalHeight,
      child: Stack(
        children: [
          // Фон ТІЛЬКИ для колеса (скролюваної області)
          Positioned.fill(
            child: Container(
              margin: EdgeInsets.symmetric(
                horizontal: widget.horizontalPadding,
              ),
              decoration: BoxDecoration(
                color: widget.backgroundColor ?? theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          // Центральний підсвічений рядок ("пігулка")
          Positioned(
            left: widget.horizontalPadding * 2,
            right: widget.horizontalPadding * 2,
            top: centerOffset,
            child: Container(
              height: widget.itemHeight,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(
                  alpha: 0.3,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.colorScheme.primary, width: 2),
              ),
            ),
          ),

          // Колесо вибору
          ListWheelScrollView.useDelegate(
            controller: _controller,
            itemExtent: widget.itemHeight,
            physics: const FixedExtentScrollPhysics(),
            onSelectedItemChanged: _onSelectedItemChanged,
            scrollBehavior: _WheelScrollBehavior(),
            childDelegate: ListWheelChildBuilderDelegate(
              builder: (context, index) {
                if (index < 0 || index >= _values.length) {
                  return const SizedBox.shrink();
                }
                final value = _values[index];
                final isMajor = _isMajorTick(value);
                final isCenter =
                    _controller.hasClients && index == _controller.selectedItem;

                return Container(
                  height: widget.itemHeight,
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: isMajor ? 40 : 16,
                        height: isMajor ? 3 : 1.5,
                        decoration: BoxDecoration(
                          color: isCenter
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface.withValues(
                                  alpha: 0.4,
                                ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        margin: const EdgeInsets.only(right: 12),
                      ),
                      if (isMajor)
                        Text(
                          value.toStringAsFixed(widget.accuracy),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: isCenter
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isCenter
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                    ],
                  ),
                );
              },
              childCount: _values.length,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

class _WheelScrollBehavior extends ScrollBehavior {
  @override
  Widget buildViewportChrome(
    BuildContext context,
    Widget child,
    AxisDirection axisDirection,
  ) {
    return child;
  }

  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.stylus,
    PointerDeviceKind.invertedStylus,
    PointerDeviceKind.trackpad,
  };
}

// ========== FLOATING BUTTON WITH OVERLAY PICKER ==========
class FloatingWheelPickerButton extends StatefulWidget {
  const FloatingWheelPickerButton({
    super.key,
    required this.min,
    required this.max,
    required this.tick,
    required this.smallTick,
    required this.value,
    required this.onChanged,
    this.accuracy = 0,
    this.unit = 'м',
    this.itemHeight = 52,
  });

  final double min, max, tick, smallTick, value;
  final int accuracy;
  final String unit;
  final double itemHeight;
  final ValueChanged<double> onChanged;

  @override
  State<FloatingWheelPickerButton> createState() =>
      _FloatingWheelPickerButtonState();
}

class _FloatingWheelPickerButtonState extends State<FloatingWheelPickerButton> {
  OverlayEntry? _overlayEntry;
  double _currentValue = 0;
  double _tempValue = 0;
  bool _isOverlayVisible = false;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.value;
    _tempValue = widget.value;
  }

  void _showOverlay() {
    if (_isOverlayVisible) return;

    _overlayEntry = OverlayEntry(builder: (context) => _buildOverlay());
    Overlay.of(context).insert(_overlayEntry!);
    _isOverlayVisible = true;
  }

  void _hideOverlay() {
    if (!_isOverlayVisible) return;

    _overlayEntry?.remove();
    _overlayEntry = null;
    _isOverlayVisible = false;
  }

  void _submitValue() {
    if (_currentValue != _tempValue) {
      _currentValue = _tempValue;
      widget.onChanged(_currentValue);
    }
    _hideOverlay();
  }

  Widget _buildOverlay() {
    return GestureDetector(
      onTap: _hideOverlay,
      child: Stack(
        children: [
          Container(color: Colors.black.withValues(alpha: 0.3)),
          Center(
            child: Material(
              color: Colors.transparent,
              child: StatefulBuilder(
                builder: (context, setOverlayState) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Text(
                            '${_tempValue.toStringAsFixed(widget.accuracy)} ${widget.unit}',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onPrimaryContainer,
                                ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        UnitWheelPicker(
                          min: widget.min,
                          max: widget.max,
                          tick: widget.tick,
                          smallTick: widget.smallTick,
                          value: _tempValue,
                          accuracy: widget.accuracy,
                          itemHeight: widget.itemHeight,
                          horizontalPadding: 32,
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.secondaryContainer,
                          onChanged: (value) {
                            setOverlayState(() {
                              _tempValue = value;
                            });
                          },
                        ),
                        const SizedBox(height: 24),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: _hideOverlay,
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: const Text(
                                    'Скасувати',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _submitValue,
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: const Text(
                                    'Вибрати',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: _showOverlay,
      onLongPressEnd: (_) {},
      child: FloatingActionButton(
        onPressed: () {},
        child: Text(
          '${_currentValue.toStringAsFixed(widget.accuracy)}${widget.unit}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

// ========== ДЕМО ==========
void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Wheel Picker Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const WheelPickerDemo(),
    );
  }
}

class WheelPickerDemo extends StatefulWidget {
  const WheelPickerDemo({super.key});

  @override
  State<WheelPickerDemo> createState() => _WheelPickerDemoState();
}

class _WheelPickerDemoState extends State<WheelPickerDemo> {
  double _distance = 100;
  double _itemHeight = 52;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wheel Picker Demo'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.height),
            onPressed: () {
              setState(() {
                _itemHeight = _itemHeight == 52 ? 72 : 52;
              });
            },
          ),
        ],
      ),
      body: const Center(
        child: Text(
          '🇺🇦 Натисни ТА ТРИМАЙ кнопку\nСкроль пальцем вгору/вниз\nНатисни "Вибрати" - значення збережеться',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16),
        ),
      ),
      floatingActionButton: FloatingWheelPickerButton(
        min: 0,
        max: 500,
        tick: 50,
        smallTick: 10,
        value: _distance,
        accuracy: 0,
        unit: 'м',
        itemHeight: _itemHeight,
        onChanged: (value) {
          setState(() {
            _distance = value;
          });
          debugPrint('Final value: $value');
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
