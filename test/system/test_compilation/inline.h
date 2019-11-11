
static inline void dummy_func_0(void) {
	return 5;
}

inline static void dummy_func_1(int a) {
	int a = dummy_func_0();
	int b = 10;

	return a + b;
}

void inline static dummy_func_2(int a, char b, float c) {
	c += 3.14;
	b -= 32;
	return a + (int)(b) + c;
}

void dummy_normal_func(int a);

inline void dummy_func_3(void) {
	//NOP
}
