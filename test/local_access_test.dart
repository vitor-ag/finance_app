@Timeout(Duration(minutes: 2))
library;

import 'dart:async';

import 'package:finance_app/features/security/domain/local_access.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_local_access.dart';

const password = 'minha senha 🔑';

void main() {
  late FakeAccessStore store;
  late FakeAppBiometrics biometrics;
  late DateTime now;

  LocalAccess openAccess() {
    final access = LocalAccess(
      store: store,
      biometrics: biometrics,
      now: () => now,
    );
    addTearDown(access.dispose);
    return access;
  }

  setUp(() {
    store = FakeAccessStore();
    biometrics = FakeAppBiometrics();
    now = DateTime.utc(2026, 11, 22);
  });

  test('a new password is salted and required on each cold start', () async {
    final access = openAccess();
    await access.load();
    expect(access.needsPassword, isTrue);
    await access.createPassword(password);
    expect(access.unlocked, isTrue);
    expect(store.record, isNot(contains(password)));

    final secondStore = FakeAccessStore();
    final secondSetup = LocalAccess(store: secondStore, biometrics: biometrics);
    addTearDown(secondSetup.dispose);
    await secondSetup.load();
    await secondSetup.createPassword(password);
    expect(secondStore.record, isNot(store.record));

    final reopened = openAccess();
    await reopened.load();
    expect(reopened.needsPassword, isFalse);
    expect(reopened.unlocked, isFalse);
    await reopened.unlockWithPassword(password);
    expect(reopened.unlocked, isTrue);
  });

  test('unreadable storage stays locked and cannot start setup', () async {
    store.record = '{"version":1,"verifier":"broken"}';
    final access = openAccess();
    await access.load();
    expect(access.loadFailed, isTrue);
    expect(access.needsPassword, isFalse);
    expect(access.unlocked, isFalse);
  });

  test(
    'a configured delay expires at the threshold, including device sleep',
    () async {
      final access = openAccess();
      await access.load();
      await access.createPassword(password);
      access.enteredBackground();
      now = now.add(const Duration(seconds: 29));
      access.resumed();
      expect(access.unlocked, isTrue);

      access.enteredBackground();
      now = now.add(const Duration(seconds: 30));
      access.resumed();
      expect(access.unlocked, isFalse);
    },
  );

  test('password delays grow and survive a process restart', () async {
    final access = openAccess();
    await access.load();
    await access.createPassword(password);
    access.lock();
    for (var i = 0; i < 3; i++) {
      await expectLater(
        access.unlockWithPassword('errada'),
        throwsA(isA<AccessProblem>()),
      );
    }
    expect(access.passwordWait, const Duration(seconds: 5));

    final reopened = openAccess();
    await reopened.load();
    expect(reopened.passwordWait, const Duration(seconds: 5));
    await expectLater(
      reopened.unlockWithPassword(password),
      throwsA(isA<AccessProblem>()),
    );
    expect(reopened.unlocked, isFalse);
    now = now.add(const Duration(seconds: 5));
    await expectLater(
      reopened.unlockWithPassword('errada'),
      throwsA(isA<AccessProblem>()),
    );
    expect(reopened.passwordWait, const Duration(seconds: 10));
    now = now.add(const Duration(seconds: 10));
    await reopened.unlockWithPassword(password);
    reopened.lock();
    await expectLater(
      reopened.unlockWithPassword('errada'),
      throwsA(isA<AccessProblem>()),
    );
    expect(reopened.passwordWait, Duration.zero);
  });

  test(
    'password changes require the current password and keep settings',
    () async {
      final access = openAccess();
      await access.load();
      await access.createPassword(password);
      await access.setLockDelay(Duration.zero);
      await expectLater(
        access.changePassword('errada', 'nova senha'),
        throwsA(isA<AccessProblem>()),
      );
      await access.changePassword(password, 'nova senha');

      final reopened = openAccess();
      await reopened.load();
      expect(reopened.lockDelay, Duration.zero);
      await expectLater(
        reopened.unlockWithPassword(password),
        throwsA(isA<AccessProblem>()),
      );
      await reopened.unlockWithPassword('nova senha');
      expect(reopened.unlocked, isTrue);
    },
  );

  test(
    'biometric cancellation, outage and invalidation leave password access',
    () async {
      biometrics.available = true;
      final access = openAccess();
      await access.load();
      await access.createPassword(password);
      expect(access.offerBiometrics, isTrue);
      await access.enableBiometrics();
      expect(access.biometricsEnabled, isTrue);
      access.lock();

      biometrics.result = BiometricResult.canceled;
      await access.unlockWithBiometrics();
      expect(access.unlocked, isFalse);
      biometrics.result = BiometricResult.unavailable;
      await expectLater(
        access.unlockWithBiometrics(),
        throwsA(isA<AccessProblem>()),
      );
      expect(access.biometricsEnabled, isTrue);
      biometrics.result = BiometricResult.invalidated;
      await expectLater(
        access.unlockWithBiometrics(),
        throwsA(isA<AccessProblem>()),
      );
      expect(access.biometricsEnabled, isFalse);
      await access.unlockWithPassword(password);
      expect(access.unlocked, isTrue);
      biometrics.result = BiometricResult.success;
      await expectLater(
        access.enableBiometrics(currentPassword: 'errada'),
        throwsA(isA<AccessProblem>()),
      );
      await access.enableBiometrics(currentPassword: password);
      expect(access.biometricsEnabled, isTrue);
      await access.disableBiometrics();
      expect(biometrics.keyRemoved, isTrue);
      expect(access.biometricsEnabled, isFalse);
    },
  );

  test(
    'biometric authentication from an earlier foreground session cannot unlock',
    () async {
      biometrics.available = true;
      final access = openAccess();
      await access.load();
      await access.createPassword(password);
      await access.enableBiometrics();
      access.lock();

      final pending = Completer<BiometricResult>();
      biometrics.pending = pending.future;
      final auth = access.unlockWithBiometrics();
      access.enteredBackground();
      pending.complete(BiometricResult.success);
      await auth;
      expect(access.unlocked, isFalse);
      await access.unlockWithBiometrics();
      expect(access.unlocked, isTrue);
    },
  );
}
