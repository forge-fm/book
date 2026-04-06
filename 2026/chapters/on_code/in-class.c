#include <klee/klee.h>
#include <assert.h>
#include <stdlib.h>

void f (int x, int y) {
  if (x > y) {
    int tmp = x;
    x = y;
    y = tmp;
    if (x > 0 && y > 0 && x - y > 0) {
       klee_assert(0); // was: exit(-1);
    }
  }
  int z = x << 7;
  int w = x & 0xFF;
  if (!w) {
    klee_assert(0); // was: exit(-1);
  }
} 

int main() {
  int x, y;
  klee_make_symbolic(&x, sizeof(x), "x");
  klee_make_symbolic(&y, sizeof(y), "y");
  f(x, y);
  return 0;
}