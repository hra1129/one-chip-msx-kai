/*

cl /O1 /EHs-c- /MD bin2vhd.c

*/

#include <stdio.h>
#include <stdlib.h>

#ifdef _MSC_VER

void _except_handler4_common()
{
	abort();
}

void *memset(void *buf, int ch, size_t n)
{
	unsigned char *ptr = buf;
	while (n-- > 0)
	{
		*(ptr++) = ch;
	}
	return buf;
}

#endif

void bin2vhd(char *path)
{
	FILE *fp = fopen(path, "rb");
	while (!feof(fp))
	{
		unsigned char ibuf[16];
		int il = fread(ibuf, 1, sizeof(ibuf), fp);
		if (il>0)
		{
			int o;
			fputs("        ", stdout);
			for (o = 0; o < il; o++)
			{
				fprintf(stdout, "X\"%02X\",", ibuf[o]);
			}
			fputc('\n', stdout);
		}
	}
}

int main(int argc, char **argv)
{
	int i;
	for (i =1; i < argc; i++)
	{
		bin2vhd(argv[i]);
	}
	return 0;
}
