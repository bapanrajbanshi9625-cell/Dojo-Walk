import 'active_walk.dart';

class ActiveWalkMapper {
  const ActiveWalkMapper._();

  static ActiveWalk fromMap(
    String documentId,
    Map<String, dynamic> data,
  ) {
    return ActiveWalk.fromMap(
      documentId,
      data,
    );
  }

  static Map<String, dynamic> toMap(
    ActiveWalk activeWalk,
  ) {
    return activeWalk.toMap();
  }
}
