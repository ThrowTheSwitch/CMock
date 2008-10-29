#include <stdio.h>
#include "Simple.h"
#include "Stuff.h"

int main(void)
{
  int a = 123, b = 456;
  printf("What is %d + %d?\n", a, b);
  Add(123, 456);
  printf("Now that's swankadelic!\n");
  return 0;
}
