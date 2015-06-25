DMD=/usr/bin/env dmd
LIB_DFLAGS=-lib
RELEASE_DFLAGS=-O -inline -release -w -g
TEST_DFLAGS=-main -unittest -w -g

BUILDS=builds

LIBJUDY=/usr/local/lib/libJudy.a
LIBJUDYD=$(BUILDS)/judyd.a

SRCS=src/judy/*.d

.PHONY: clean

all: lib test

lib:
	$(DMD) -of$(LIBJUDYD) $(LIB_DFLAGS) $(RELEASE_DFLAGS) $(SRCS) $(LIBJUDY)

test:
	$(DMD) -ofbuilds/judyd_test $(TEST_DFLAGS) $(SRCS) $(LIBJUDY)
	builds/judyd_test

examples: sort

sort: lib
	$(DMD) -ofbuilds/sort $(RELEASE_DFLAGS) examples/sort.d $(LIBJUDYD)

clean:
	rm -rf builds
