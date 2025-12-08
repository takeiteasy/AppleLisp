#ifndef CNCURSES_SHIM_H
#define CNCURSES_SHIM_H

#include <ncurses.h>

// Swift-compatible attribute constants
static const int ATTR_BOLD = A_BOLD;
static const int ATTR_REVERSE = A_REVERSE;
static const int ATTR_UNDERLINE = A_UNDERLINE;
static const int ATTR_STANDOUT = A_STANDOUT;

#endif
