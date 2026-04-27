import 'dart:io';

import 'package:ebalistyka/l10n/app_localizations.dart';
import 'package:ebalistyka/shared/constants/null_string.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:ebalistyka/features/tables/details_table_mv.dart';
import 'package:ebalistyka/features/tables/trajectory_tables_vm.dart';
import 'package:ebalistyka/shared/models/formatted_row.dart';

// ─── HTML Exporter ────────────────────────────────────────────────────────────

class TableHtmlExporter {
  const TableHtmlExporter._();

  static Future<void> share({
    required DetailsTableData? details,
    required TrajectoryTablesUiReady tables,
    required AppLocalizations l10n,
    bool darkMode = false,
  }) async {
    final html = _buildHtml(
      details: details,
      tables: tables,
      darkMode: darkMode,
      l10n: l10n,
    );
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/trajectory_table.html');
    await file.writeAsString(html, flush: true);

    if (Platform.isAndroid || Platform.isIOS) {
      await Share.shareXFiles(
        [
          XFile(
            file.path,
            mimeType: 'text/html',
            name: 'trajectory_table.html',
          ),
        ],
        subject: details != null
            ? '${details.weaponName} — ${l10n.tabTrajectory}'
            : l10n.tabTrajectory,
      );
    } else {
      // Desktop: open HTML in the default browser
      await launchUrl(
        Uri.file(file.path),
        mode: LaunchMode.externalApplication,
      );
    }
  }

  // ── Top-level builder ──────────────────────────────────────────────────────

  static String _buildHtml({
    required DetailsTableData? details,
    required TrajectoryTablesUiReady tables,
    required bool darkMode,
    required AppLocalizations l10n,
  }) {
    final title = details != null
        ? '${_esc(details.weaponName)} — ${l10n.tabTrajectory}'
        : l10n.tabTrajectory;
    final sb = StringBuffer()
      ..writeln('<!DOCTYPE html>')
      ..writeln('<html lang="en">')
      ..writeln('<head>')
      ..writeln('<meta charset="utf-8">')
      ..writeln(
        '<meta name="viewport" content="width=device-width, initial-scale=1">',
      )
      ..writeln('<title>$title</title>')
      ..writeln('<style>')
      ..writeln(_getCss(darkMode))
      ..writeln('</style>')
      ..writeln('<script>')
      ..writeln(_js)
      ..writeln('</script>')
      ..writeln('</head>')
      ..writeln('<body${darkMode ? ' class="dark"' : ''}>')
      ..writeln('<div class="toolbar" id="toolbar">')
      ..writeln('  <span class="toolbar-title">${_esc(title)}</span>')
      ..writeln('  <div class="toolbar-actions">')
      ..writeln('    <button onclick="toggleTheme()">🌓 ${l10n.theme}</button>')
      ..writeln('    <button onclick="saveHtml()">${l10n.saveButton}</button>')
      ..writeln(
        '    <button onclick="window.print()">${l10n.printButton}</button>',
      )
      ..writeln('  </div>')
      ..writeln('</div>');

    if (details != null) sb.write(_buildDetails(details, l10n: l10n));

    final zeros = tables.zeroCrossings;
    if (zeros != null && zeros.distanceHeaders.isNotEmpty) {
      sb.write(_buildTable(zeros, title: l10n.tablesSectionZeroCrossing));
    }
    sb.write(
      _buildTable(tables.mainTable, title: l10n.tablesSectionTrajectory),
    );

    sb.writeln('</body>');
    sb.writeln('</html>');
    return sb.toString();
  }

  // ── Details section ────────────────────────────────────────────────────────

  static String _buildDetails(
    DetailsTableData d, {
    required AppLocalizations l10n,
  }) {
    final sb = StringBuffer()
      ..writeln('<section class="details">')
      ..writeln('<h1>${_esc(d.weaponName)}</h1>');

    // Rifle
    sb.writeln('<div class="card">');
    sb.writeln('<h2>${l10n.weapon}</h2><table class="info">');
    sb.write(_row(l10n.name, d.weaponName));
    if (d.caliber != null) sb.write(_row(l10n.caliber, d.caliber!));
    if (d.twist != null) sb.write(_row(l10n.twist, d.twist!));
    if (d.zeroDist != null) sb.write(_row(l10n.zeroDistance, d.zeroDist!));
    sb.writeln('</table></div>');

    // Cartridge
    if (d.zeroMv != null || d.currentMv != null) {
      sb.writeln('<div class="card">');
      sb.writeln('<h2>${l10n.cartridge}</h2><table class="info">');
      if (d.zeroMv != null) sb.write(_row(l10n.zeroMv, d.zeroMv!));
      if (d.currentMv != null) sb.write(_row(l10n.currentMv, d.currentMv!));
      sb.writeln('</table></div>');
    }

    // Projectile
    final hasProj =
        d.dragModel != null ||
        d.bc != null ||
        d.bulletLen != null ||
        d.bulletDiam != null ||
        d.bulletWeight != null ||
        d.formFactor != null ||
        d.sectionalDensity != null ||
        d.gyroStability != null;
    if (hasProj) {
      sb.writeln('<div class="card">');
      sb.writeln('<h2>${l10n.projectile}</h2><table class="info">');
      if (d.dragModel != null) sb.write(_row(l10n.dragModel, d.dragModel!));
      if (d.bc != null) sb.write(_row(l10n.bc, d.bc!));
      if (d.bulletLen != null) sb.write(_row(l10n.length, d.bulletLen!));
      if (d.bulletDiam != null) sb.write(_row(l10n.diameter, d.bulletDiam!));
      if (d.bulletWeight != null) sb.write(_row(l10n.weight, d.bulletWeight!));
      if (d.formFactor != null) sb.write(_row(l10n.formFactor, d.formFactor!));
      if (d.sectionalDensity != null) {
        sb.write(_row(l10n.sectionalDensity, d.sectionalDensity!));
      }
      if (d.gyroStability != null) {
        sb.write(_row(l10n.gyrostabilitySg, d.gyroStability!));
      }
      sb.writeln('</table></div>');
    }

    // Conditions
    final hasCond =
        d.temperature != null ||
        d.humidity != null ||
        d.pressure != null ||
        d.windSpeed != null ||
        d.windDir != null;
    if (hasCond) {
      sb.writeln('<div class="card">');
      sb.writeln('<h2>${l10n.conditions}</h2><table class="info">');
      if (d.temperature != null)
        sb.write(_row(l10n.temperature, d.temperature!));
      if (d.humidity != null) sb.write(_row(l10n.humidity, d.humidity!));
      if (d.pressure != null) sb.write(_row(l10n.pressure, d.pressure!));
      if (d.windSpeed != null) sb.write(_row(l10n.windSpeed, d.windSpeed!));
      if (d.windDir != null) sb.write(_row(l10n.windDirection, d.windDir!));
      sb.writeln('</table></div>');
    }

    sb.writeln('</section>');
    return sb.toString();
  }

  static String _row(String label, String value) =>
      '<tr><td class="lbl">${_esc(label)}</td>'
      '<td class="val">${_esc(value)}</td></tr>\n';

  // ── Trajectory table section ───────────────────────────────────────────────

  static String _buildTable(FormattedTableData t, {required String title}) {
    if (t.distanceHeaders.isEmpty || t.rows.isEmpty) return '';
    final sb = StringBuffer()
      ..writeln('<section class="traj">')
      ..writeln('<h2>$title</h2>')
      ..writeln('<div class="scroll">')
      ..writeln('<table class="traj-tbl">')
      ..writeln('<thead><tr>');

    sb.writeln(
      '<th>Range<br><span class="unit">${_esc(t.distanceUnit)}</span></th>',
    );
    for (final r in t.rows) {
      final unit = r.unitSymbol.isNotEmpty
          ? '<br><span class="unit">${_esc(r.unitSymbol)}</span>'
          : '';
      sb.writeln('<th>${_esc(r.label)}$unit</th>');
    }
    sb.writeln('</tr></thead><tbody>');

    for (var pi = 0; pi < t.distanceHeaders.length; pi++) {
      final first = t.rows.isNotEmpty ? t.rows[0].cells[pi] : null;
      final cls = (first?.isZeroCrossing ?? false)
          ? ' class="zero"'
          : (first?.isSubsonic ?? false)
          ? ' class="subsonic"'
          : (first?.isTargetColumn ?? false)
          ? ' class="target"'
          : '';
      sb.writeln('<tr$cls>');
      sb.writeln('<td class="rng">${_esc(t.distanceHeaders[pi])}</td>');
      for (final r in t.rows) {
        final v = pi < r.cells.length ? r.cells[pi].value : nullStr;
        sb.writeln('<td>${_esc(v)}</td>');
      }
      sb.writeln('</tr>');
    }

    sb.writeln('</tbody></table></div></section>');
    return sb.toString();
  }

  // ── HTML escape ────────────────────────────────────────────────────────────

  static String _esc(String s) => s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;');

  // ── CSS with theme support ─────────────────────────────────────────────────

  static String _getCss(bool darkMode) => '''
    :root {
      /* Light theme (default) */
      --bg-body: #f2f2f7;
      --bg-card: #ffffff;
      --bg-toolbar: rgba(242,242,247,.85);
      --border-color: #e5e5ea;
      --text-primary: #1c1c1e;
      --text-secondary: #636366;
      --text-tertiary: #8e8e93;
      --header-bg: #f2f2f7;
      --row-alt-bg: #fafafa;
      --zero-bg: #fff0f0;
      --zero-color: #c0392b;
      --subsonic-bg: #f0eeff;
      --subsonic-color: #5856d6;
      --target-bg: #e8f4ff;
      --target-color: #0071e3;
      --toolbar-blur: blur(12px);
    }

    body.dark {
      --bg-body: #000000;
      --bg-card: #1c1c1e;
      --bg-toolbar: rgba(28,28,30,.85);
      --border-color: #38383a;
      --text-primary: #ffffff;
      --text-secondary: #8e8e93;
      --text-tertiary: #636366;
      --header-bg: #1c1c1e;
      --row-alt-bg: #2c2c2e;
      --zero-bg: #3a1c1c;
      --zero-color: #ff6b6b;
      --subsonic-bg: #2a1f3d;
      --subsonic-color: #9b9bff;
      --target-bg: #1a3445;
      --target-color: #4da8ff;
    }

    *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
    
    body {
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
      font-size: 13px; line-height: 1.5; 
      color: var(--text-primary); 
      background: var(--bg-body);
      padding: 16px; padding-top: 60px;
      transition: background 0.2s ease, color 0.2s ease;
    }
    
    .toolbar {
      position: fixed; top: 0; left: 0; right: 0; height: 44px; z-index: 100;
      background: var(--bg-toolbar); backdrop-filter: var(--toolbar-blur);
      border-bottom: 1px solid var(--border-color);
      display: flex; align-items: center; justify-content: space-between;
      padding: 0 16px; gap: 12px;
    }
    
    .toolbar-title { font-weight: 600; font-size: 14px; overflow: hidden;
                     text-overflow: ellipsis; white-space: nowrap; }
    
    .toolbar-actions { display: flex; gap: 8px; flex-shrink: 0; }
    
    .toolbar button {
      font-size: 13px; font-family: inherit; cursor: pointer;
      padding: 6px 12px; border: 1px solid var(--border-color);
      background: var(--bg-card); border-radius: 6px;
      color: var(--text-primary); font-weight: 500;
      transition: all 0.2s ease;
    }
    
    .toolbar button:hover { 
      opacity: 0.8;
      transform: translateY(-1px);
    }
    
    @media print {
      .toolbar { display: none; }
      body { padding-top: 16px; background: #fff; color: #000; }
      body.dark { background: #fff; color: #000; }
      .card, .traj { background: #fff; border: 1px solid #ddd; }
    }
    
    h1 { font-size: 18px; font-weight: 700; margin-bottom: 12px; }
    
    h2 {
      font-size: 11px; font-weight: 700; text-transform: uppercase;
      letter-spacing: 0.7px; color: var(--text-secondary); margin-bottom: 6px;
    }
    
    section { margin-bottom: 20px; }

    /* Details cards */
    .details { display: flex; flex-wrap: wrap; gap: 12px; }
    .details h1 { flex: 0 0 100%; }
    
    .card {
      background: var(--bg-card); border-radius: 10px; padding: 12px 14px;
      flex: 1 1 180px; box-shadow: 0 1px 3px rgba(0,0,0,.07);
      border: 1px solid var(--border-color);
      transition: background 0.2s ease, border-color 0.2s ease;
    }
    
    table.info { width: 100%; border-collapse: collapse; }
    table.info td { padding: 3px 0; vertical-align: top; }
    td.lbl { color: var(--text-secondary); padding-right: 12px; white-space: nowrap; }
    td.val { font-weight: 500; font-variant-numeric: tabular-nums; }

    /* Trajectory table */
    .traj { background: var(--bg-card); border-radius: 10px; padding: 12px 14px;
            box-shadow: 0 1px 3px rgba(0,0,0,.07); border: 1px solid var(--border-color); }
    .scroll { overflow-x: auto; }
    
    table.traj-tbl {
      border-collapse: collapse; font-size: 12px;
      font-variant-numeric: tabular-nums; white-space: nowrap;
      width: 100%; min-width: max-content;
    }
    
    table.traj-tbl th, table.traj-tbl td {
      border: 1px solid var(--border-color); padding: 4px 10px; text-align: right;
    }
    
    table.traj-tbl th {
      background: var(--header-bg); font-size: 11px; font-weight: 600;
      text-align: center; position: sticky; top: 0;
    }
    
    .unit { font-weight: 400; color: var(--text-tertiary); }
    td.rng { text-align: center; font-weight: 600; background: var(--header-bg); }
    tr:nth-child(even) td { background: var(--row-alt-bg); }
    
    tr.zero    td { background: var(--zero-bg) !important; color: var(--zero-color); font-weight: 600; }
    tr.subsonic td { background: var(--subsonic-bg) !important; color: var(--subsonic-color); font-weight: 600; }
    tr.target  td { background: var(--target-bg) !important; color: var(--target-color); font-weight: 600; }
  ''';

  // ── JS with theme toggle ───────────────────────────────────────────────────

  static const _js = r'''
    function toggleTheme() {
      const body = document.body;
      if (body.classList.contains('dark')) {
        body.classList.remove('dark');
        localStorage.setItem('trajTheme', 'light');
      } else {
        body.classList.add('dark');
        localStorage.setItem('trajTheme', 'dark');
      }
    }
    
    // Load saved theme preference
    const savedTheme = localStorage.getItem('trajTheme');
    if (savedTheme === 'dark') {
      document.body.classList.add('dark');
    }
    
    function saveHtml() {
      const html = document.documentElement.outerHTML;
      const blob = new Blob([html], { type: 'text/html' });
      const a = document.createElement('a');
      a.href = URL.createObjectURL(blob);
      a.download = 'trajectory_table.html';
      a.click();
      URL.revokeObjectURL(a.href);
    }
  ''';
}
