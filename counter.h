// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#ifndef COUNTER_H
#define COUNTER_H

#include <cstdint>

class Counter {
 public:
  Counter() { num_allocated++; }
  ~Counter() { num_allocated--; }

  int64_t value() const { return value_; }

  void increment(int64_t value) {
    value_ += value;
  }

  static intptr_t num_allocated;

 private:
  int64_t value_ = 0;
};

#endif  // COUNTER_H