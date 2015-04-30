#include "strcasecmp.h"

char __hack_charget(char c)
{
	if(c >= 'a' && c <= 'z')

		c += 'A' - 'a';
	return c;
}

int strcasecmp(char const *a,char const *b)
{
	char ac, bc;
	int r;

	for(;;)
	{
		ac = __hack_charget(*a++);
		bc = __hack_charget(*b++);
		r = (int)ac - (int)bc;

		if(r)
			return r;

		if(!ac)
			return 0;
	}
}

int strncasecmp(char const *a, char const *b,int n)
{
	char ac, bc;
	int r, i;

	for(i = 0; i < n; ++i)
	{
		ac = __hack_charget(*a++);
		bc = __hack_charget(*b++);
		r = (int)ac - (int)bc;

		if(r)
			return r;
		if(!ac)
			return 0;
	}
	return 0;
}