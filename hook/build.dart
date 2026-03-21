// ignore_for_file: dangling_library_doc_comments
/// Flutter native-assets build hook (native_assets_cli ^0.18).
///
/// Automatically invoked by `flutter run / flutter build` when the
/// native-assets experiment is enabled:
///
///   flutter run --enable-experiment=native-assets
///
/// Builds the bclibc_ffi shared library via CMake and registers it as a
/// bundled CodeAsset so DynamicLibrary.open('libbclibc_ffi.so') works.

import 'dart:io';

import 'package:native_assets_cli/code_assets.dart';
import 'package:native_assets_cli/native_assets_cli.dart';

const _libName = 'bclibc_ffi';

void main(List<String> args) async {
  await build(args, _hook);
}

Future<void> _hook(BuildInput input, BuildOutputBuilder output) async {
  final nativeDir = input.packageRoot.resolve('native/');
  final buildDir  = input.outputDirectory.resolve('cmake_build/');

  await Directory(buildDir.toFilePath()).create(recursive: true);

  // ── CMake configure ───────────────────────────────────────────────────────
  await _cmake([
    '-S', nativeDir.toFilePath(),
    '-B', buildDir.toFilePath(),
  ]);

  // ── CMake build ───────────────────────────────────────────────────────────
  await _cmake(['--build', buildDir.toFilePath()]);

  // ── Register the produced library as a bundled code asset ─────────────────
  final libFile = buildDir.resolve(
    input.config.code.targetOS.libraryFileName(_libName, DynamicLoadingBundled()),
  );

  output.assets.code.add(CodeAsset(
    package:  input.packageName,
    name:     _libName,
    linkMode: DynamicLoadingBundled(),
    file:     libFile,
  ));

  // ── Declare source files so the hook re-runs on changes ───────────────────
  output.addDependencies([
    nativeDir.resolve('bclibc_ffi.h'),
    nativeDir.resolve('bclibc_ffi.cpp'),
    nativeDir.resolve('CMakeLists.txt'),
  ]);
}

Future<void> _cmake(List<String> args) async {
  // Flutter snap bundles its own cmake/ld which conflicts with system gcc 15.
  // Force system tools by prepending /usr/bin to PATH.
  final env = Map<String, String>.from(Platform.environment);
  env['PATH'] = '/usr/bin:/usr/local/bin:${env['PATH'] ?? ''}';

  final result = await Process.run('cmake', args, environment: env);
  if (result.exitCode != 0) {
    throw ProcessException(
      'cmake', args,
      'exit ${result.exitCode}\nstdout: ${result.stdout}\nstderr: ${result.stderr}',
      result.exitCode,
    );
  }
}
