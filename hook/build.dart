import 'package:native_assets_cli/code_assets.dart';
import 'package:native_assets_cli/native_assets_cli.dart';

void main(List<String> args) async {
  await build(args, (input, output) async {
    final targetOS = input.config.code.targetOS;

    final soName = switch (targetOS) {
      OS.macOS   => 'libbclibc_ffi.dylib',
      OS.windows => 'bclibc_ffi.dll',
      _          => 'libbclibc_ffi.so',
    };

    // DynamicLoadingSystem: library resolved at runtime by the OS dynamic linker.
    // Does NOT require ld/ld.lld during build — no bundling step.
    output.assets.code.add(
      CodeAsset(
        package: input.packageName,
        name: soName,
        linkMode: DynamicLoadingSystem(
          Uri.file(soName),
        ),
      ),
    );
  });
}
