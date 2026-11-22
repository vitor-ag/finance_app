import 'package:finance_app/features/security/domain/local_access.dart';

class FakeAccessStore implements AccessStore {
  String? record;

  @override
  Future<String?> read() async => record;

  @override
  Future<void> write(String value) async {
    record = value;
  }
}

class FakeAppBiometrics implements AppBiometrics {
  bool available = false;
  bool keyRemoved = false;
  BiometricResult result = BiometricResult.success;
  Future<BiometricResult>? pending;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<BiometricResult> authenticate({required bool enroll}) async =>
      await pending ?? result;

  @override
  Future<void> removeKey() async {
    keyRemoved = true;
  }
}
