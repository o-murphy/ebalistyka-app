import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;

bool get isDesktop =>
    defaultTargetPlatform == TargetPlatform.windows ||
    defaultTargetPlatform == TargetPlatform.linux ||
    defaultTargetPlatform == TargetPlatform.macOS;
