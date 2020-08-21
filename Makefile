# Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
# for details. All rights reserved. Use of this source code is governed by a
# BSD-style license that can be found in the LICENSE file.

DART_INCLUDE=$(HOME)/src/dart/sdk/runtime
CXXFLAGS=-g -O3 -fPIC -m64 -I$(DART_INCLUDE) -DDART_SHARED_LIB

all: libimpl.so Makefile

clean:
	rm -rf *.o *.so

libimpl.so: api_emu.o counter.o impl_api.o impl_api_emu.o impl_ffi.o dart_api_dl.o
	g++ -shared -m64 -Wl,-soname,libimpl.so -o $@ $^

dart_api_dl.o: $(DART_INCLUDE)/include/dart_api_dl.c
	g++ $(CXXFLAGS) -c -o $@ $<

%.o: %.cc
	g++ $(CXXFLAGS) -c -o $@ $<