import 'package:objectbox/objectbox.dart';

enum FocalPlane { ffp, sfp, lwir }

@Entity()
class Sight {
  Sight({
    this.name,
    this.focalPlane,
    this.horizontalClick = 0.1,
    this.verticalClick = 0.1,
    this.verticalClickUnit = "mil",
    this.horizontalClickUnit = "mil",
    this.sightHeight = 0.0,
    this.sightHorizontalOffset = 0.0,
    this.minMagnification = 1.0,
    this.maxMagnification = 1.0,
    this.reticleImage,
    this.vendor,
    this.notes,
  });

  @Id()
  int id = 0;

  @Index()
  String? name;

  String? vendor;
  String? notes;

  @Transient()
  FocalPlane? focalPlane;

  String? get focalPlaneValue => focalPlane?.name;

  set focalPlaneValue(String? value) {
    if (value != null) {
      focalPlane = FocalPlane.values.firstWhere(
        (e) => e.name == value,
        orElse: () => FocalPlane.ffp,
      );
    } else {
      focalPlane = null;
    }
  }

  double? sightHeight;
  double? verticalClick;
  double? horizontalClick;
  String? verticalClickUnit;
  String? horizontalClickUnit;
  double? sightHorizontalOffset;
  double? minMagnification;
  double? maxMagnification;
  String? reticleImage;

  @Backlink('sight')
  final profiles = ToMany<Profile>();
}

@Entity()
class Profile {
  Profile();

  @Id()
  int id = 0;

  final sight = ToOne<Sight>();
}
