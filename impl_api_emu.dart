// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'api_emu.dart';

final _resolver = NativeResolver('CounterLib', 'libimpl.so');

final nop = _resolver.resolve0('ApiEmu_Nop');

class Counter extends NativeWrapper {
  // Will be invoked from the native code.
  Counter._construct();

  factory Counter() => _allocate();

  int get counter => _getValue(this);
  void increment(int value) => _increment(this, value);

  static final _allocate = _resolver.resolve0('ApiEmu_Counter_Allocate');
  static final _getValue = _resolver.resolve1('ApiEmu_Counter_GetValue');
  static final _increment = _resolver.resolve2('ApiEmu_Counter_Increment');
}

final void Function() initializeLib = () {
  initialize();
  registerClass('Counter', {
    '_construct': () => Counter._construct(),
  });
  return () {};
}();
