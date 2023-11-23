#ifndef noreturn_h
#define noreturn_h
/* #include <stdnoreturn.h> */

_Noreturn void myexec1(const char* program);
void __attribute__((noreturn)) myexec2(const char* program);
void myexec3(const char* program) __attribute__((noreturn));

#endif
