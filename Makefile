DMD=/usr/bin/env dmd
RELEASE_DFLAGS=-O -w -lib -g
TEST_DFLAGS=-main -unittest -w -g
LIBJUDY=/usr/local/lib/libJudy.a

SRCS=src/judy/*.d

.PHONY: all test clean

all:
	$(DMD) -ofbuilds/djudy.a $(RELEASE_DFLAGS) $(SRCS) $(LIBJUDY)

test:
	$(DMD) -ofbuilds/djudy_test $(TEST_DFLAGS) $(SRCS) $(LIBJUDY)
	builds/djudy_test

clean:
	rm -r builds
