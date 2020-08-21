// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

import 'impl_api.dart' as impl_api;
import 'impl_api_emu.dart' as impl_api_emu;
import 'impl_ffi.dart' as impl_ffi;

void tryCauseGc() {
  final sw = Stopwatch()..start();
  while (impl_api.getNumberOfAllocatedCounterObjects() != 0 &&
      sw.elapsedMilliseconds < 2000) {
    final l = List<int>.filled(
        1024 * 1024 + impl_api.getNumberOfAllocatedCounterObjects(), 0);
    expect(l.length, greaterThan(0));
  }
}

void main() {
  impl_api_emu.initializeLib();

  void testBody(ctor) {
    var c = ctor();
    expect(impl_api.getNumberOfAllocatedCounterObjects(), equals(1));
    for (var i = 0; i < 100; i++) {
      c.increment(i);
    }
    expect(c.counter, equals(4950));
    expect(impl_api.getNumberOfAllocatedCounterObjects(), equals(1));
    c = null;
    tryCauseGc();
    expect(impl_api.getNumberOfAllocatedCounterObjects(), equals(0));
  }

  test('Counter (API implementation using native fields)', () {
    testBody(() => impl_api.Counter());
  });

  test('Counter (API implementation using peers)', () {
    testBody(() => impl_api.CounterWithPeer());
  });

  test('Counter (FFI implementation)', () {
    testBody(() => impl_ffi.Counter());
  });

  test('Counter (API emulation via FFI implementation)', () {
    testBody(() => impl_api_emu.Counter());
  });

  test('Counter (RAW access via FFI)', () {
    var c = impl_ffi.Counter();
    expect(c.rawCounter, equals(0));
    c.increment(42);
    expect(c.rawCounter, equals(42));
    c.rawIncrement(-21);
    expect(c.counter, equals(21));
    expect(c.rawCounter, equals(21));
  });

  test('Counter (RAW RAW access via FFI)', () {
    var c = impl_ffi.Counter();
    expect(c.rawrawCounter, equals(0));
    c.increment(42);
    expect(c.rawrawCounter, equals(42));
    c.rawrawIncrement(-21);
    expect(c.counter, equals(21));
    expect(c.rawrawCounter, equals(21));
  });
}
