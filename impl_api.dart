// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:nativewrappers';

import 'dart-ext:impl';

void nop() native "nop";

int getNumberOfAllocatedCounterObjects()
    native "Test_Counter_GetAllocatedCount";

class Counter extends NativeFieldWrapperClass1 {
  factory Counter() native "Api_Counter_Allocate";

  int get counter native "Api_Counter_GetValue";

  void increment(int value) native "Api_Counter_Increment";
}

class CounterWithPeer {
  factory CounterWithPeer() native "Api_CounterWithPeer_Allocate";

  int get counter native "Api_CounterWithPeer_GetValue";

  void increment(int value) native "Api_CounterWithPeer_Increment";
}
