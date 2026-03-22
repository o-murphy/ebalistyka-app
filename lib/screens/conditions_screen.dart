import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../router.dart';
import '../widgets/icon_value_button.dart';

class ConditionsScreen extends StatefulWidget {
  const ConditionsScreen({super.key});

  @override
  State<ConditionsScreen> createState() => _ConditionsScreenState();
}

class _ConditionsScreenState extends State<ConditionsScreen> {
  double _temperature = 15.0;
  bool _coriolis           = false;
  bool _powderSensitivity  = false;
  bool _derivation         = false;
  bool _aeroJump           = false;
  bool _pressureFromAlt    = false;

  void _stepTemp(int dir) => setState(() => _temperature += dir.toDouble());

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _Header(),
        Expanded(
          child: ListView(
            children: [
              // ── Temperature ─────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: _TempControl(
                  value: _temperature,
                  onDown: () => _stepTemp(-1),
                  onUp:   () => _stepTemp(1),
                  onTap:  () {/* TODO: input dialog */},
                ),
              ),
              const Divider(height: 24),

              // ── Altitude / Humidity / Pressure ───────────────────────────────
              IconValueButtonRow(
                items: [
                  IconValueButton(icon: Icons.terrain_outlined,       value: '150 m',    label: 'Altitude', onTap: () {}, heroTag: 'cond-alt'),
                  IconValueButton(icon: Icons.water_drop_outlined,    value: '50%',      label: 'Humidity', onTap: () {}, heroTag: 'cond-hum'),
                  IconValueButton(icon: Icons.speed_outlined,         value: '1000 hPa', label: 'Pressure', onTap: () {}, heroTag: 'cond-pres'),
                ],
              ),
              const Divider(height: 24),

              // ── Switches ─────────────────────────────────────────────────────
              _SwitchTile(label: 'Coriolis effect',                icon: Icons.rotate_right_outlined,            value: _coriolis,          onChanged: (v) => setState(() => _coriolis = v)),
              _SwitchTile(label: 'Powder temperature sensitivity', icon: Icons.local_fire_department_outlined,   value: _powderSensitivity, onChanged: (v) => setState(() => _powderSensitivity = v)),
              _SwitchTile(label: 'Spin drift (derivation)',        icon: Icons.rotate_left_outlined,             value: _derivation,        onChanged: (v) => setState(() => _derivation = v)),
              _SwitchTile(label: 'Aerodynamic jump',               icon: Icons.air_outlined,                     value: _aeroJump,          onChanged: (v) => setState(() => _aeroJump = v)),
              _SwitchTile(label: 'Pressure depends on altitude',   icon: Icons.compress_outlined,                value: _pressureFromAlt,   onChanged: (v) => setState(() => _pressureFromAlt = v)),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Header ──────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.go(Routes.home),
              ),
            ),
            Text('Conditions', style: Theme.of(context).textTheme.titleLarge),
          ],
        ),
      ),
    );
  }
}

// ─── Temperature control ──────────────────────────────────────────────────────

class _TempControl extends StatelessWidget {
  const _TempControl({
    required this.value,
    required this.onDown,
    required this.onUp,
    required this.onTap,
  });

  final double       value;
  final VoidCallback onDown;
  final VoidCallback onUp;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        IconButton.filledTonal(
          icon: const Icon(Icons.remove),
          onPressed: onDown,
        ),
        Expanded(
          child: GestureDetector(
            onTap: onTap,
            child: Column(
              children: [
                Icon(Icons.device_thermostat_outlined, color: cs.primary),
                const SizedBox(height: 4),
                Text(
                  '${value.toStringAsFixed(1)} °C',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                Text(
                  'Temperature',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.55),
                      ),
                ),
              ],
            ),
          ),
        ),
        IconButton.filledTonal(
          icon: const Icon(Icons.add),
          onPressed: onUp,
        ),
      ],
    );
  }
}

// ─── Switch tile ──────────────────────────────────────────────────────────────

class _SwitchTile extends StatelessWidget {
  const _SwitchTile({
    required this.label,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  final String   label;
  final IconData icon;
  final bool     value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      secondary: Icon(icon),
      title: Text(label, style: const TextStyle(fontSize: 14)),
      value: value,
      onChanged: onChanged,
      dense: true,
    );
  }
}
