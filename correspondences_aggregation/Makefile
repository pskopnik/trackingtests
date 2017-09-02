progname ?= test
SRC_DIRS ?= .

CC=gcc
CXX=g++
RM=rm -f

CPPFLAGS = -std=c++11 -Wall -g -O3 $(shell pkg-config --cflags NetworKit) -fopenmp
LDFLAGS  = -g -O3 -Wall
LDLIBS   = $(shell pkg-config --libs NetworKit) -fopenmp

SRCS := $(shell find $(SRC_DIRS) -name *.cpp -or -name *.c -or -name *.s)
OBJS := $(addsuffix .o,$(basename $(SRCS)))

all: $(progname)

$(progname): $(OBJS)
	$(CXX) $(LDFLAGS) -o $(progname) $(OBJS) $(LDLIBS)

depend: .depend

.depend: $(SRCS)
	$(RM) ./.depend
	$(CXX) $(CPPFLAGS) -MM $^>>./.depend;

.PHONY: clean

clean:
	$(RM) $(progname) $(OBJS)
	$(RM) *~ .depend

include .depend
