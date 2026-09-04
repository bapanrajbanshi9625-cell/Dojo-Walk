import '../models/accept_live_strip_data.dart';
import 'accept_live_strip_service.dart';

class AcceptLiveStripTrigger {
  AcceptLiveStripTrigger({
    AcceptLiveStripService? service,
  }) : _service = service ?? AcceptLiveStripService();

  final AcceptLiveStripService _service;

  // ==========================================================
  // TRIGGER
  // ==========================================================

  Stream<AcceptLiveStripData> trigger() {
    return _service.watch();
  }

  // ==========================================================
  // DISPOSE
  // ==========================================================

  Future<void> dispose() async {
    await _service.dispose();
  }
}
