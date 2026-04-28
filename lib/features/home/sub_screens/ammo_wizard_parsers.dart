import 'dart:typed_data';

List<({double vMps, double bc})>? decodeBcTable(
  Float64List? vMps,
  Float64List? bcs,
) {
  if (vMps == null || bcs == null || vMps.isEmpty) return null;
  return List.generate(vMps.length, (i) => (vMps: vMps[i], bc: bcs[i]));
}

List<({double mach, double cd})>? decodeCustomDragTable(
  Float64List? mach,
  Float64List? cd,
) {
  if (mach == null || cd == null || mach.isEmpty) return null;
  return List.generate(mach.length, (i) => (mach: mach[i], cd: cd[i]));
}

List<({double tempC, double vMps})>? decodePowderSensTable(
  Float64List? tempC,
  Float64List? vMps,
) {
  if (tempC == null || vMps == null || tempC.isEmpty) return null;
  return List.generate(tempC.length, (i) => (tempC: tempC[i], vMps: vMps[i]));
}
