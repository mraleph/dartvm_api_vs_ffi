// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "counter.h"

extern "C" {
void ffi_Nop() {
  // Do nothing
}

Counter* ffi_Counter_Allocate() {
  return new Counter();
}

void ffi_Counter_Free(Counter* counter) {
  delete counter;
}

int64_t ffi_Counter_GetValue(Counter* counter) {
  return counter->value();
}

void ffi_Counter_Increment(Counter* counter, int64_t value) {
  counter->increment(value);
}
}
