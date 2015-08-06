DMD=/usr/bin/env dmd
LIB_DFLAGS=-lib
RELEASE_DFLAGS=-O -inline -release -w -g
TEST_DFLAGS=-main -unittest -w -g

BUILDS=builds
INCLUDES=-Isrc/

LIBJUDY=/usr/local/lib/libJudy.a
LIBJUDYD=$(BUILDS)/libjudyd.a

SRCS=src/judy/*.d

.PHONY: clean

all: lib test examples

lib:
	$(DMD) -of$(LIBJUDYD) $(LIB_DFLAGS) $(RELEASE_DFLAGS) $(SRCS) $(LIBJUDY)

test:
	$(DMD) -ofbuilds/judyd_test $(TEST_DFLAGS) $(SRCS) $(LIBJUDY)
	builds/judyd_test

examples: judy1 judyl

judy1:
	$(DMD) -ofbuilds/judy1 $(INCLUDES) $(RELEASE_DFLAGS) examples/judy1.d $(LIBJUDYD)

judyl:
	$(DMD) -ofbuilds/judyl $(INCLUDES) $(RELEASE_DFLAGS) examples/judyl.d $(LIBJUDYD)

clean:
	rm -rf builds
