// Conditional import: use stub on non-web, real implementation on web.
export 'accesly_service_stub.dart'
    if (dart.library.html) 'accesly_service_web.dart';
