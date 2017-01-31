/* TYPE36 - Displays 36-bit data from a PDP-10 */

/* Used to read a stream of bytes (such as from a half-inch tape drive) to
 * see if it is in PDP-10 format (5 printable characters per 36-bit word.
 * 24-Jan-96: Created by Joe Smith <js-cgi@inwap.com> for Tymshare.
 * 06-Jun-01: Add SIXBIT to the display.
 */

#include <stdio.h>
#include <ctype.h>
#include <fcntl.h>

main(argc,argv)
int argc;
char *argv[];
{
  FILE *out=stdout;
  int in,i,errors=0;
  char *name;

  if (argc < 2)
    {fprintf(stderr,"Usage: %s filename [filename]\n",argv[0]); return(5);}
  else {
    for (i=1;i<argc;i++) {
      if (*argv[i] == '-') {
        in = fileno(stdin);
	name = "STDIN";
      } else {
        in = open(argv[i],O_RDONLY,0);
	name = argv[i];
      }
      if (in < 0) {perror("Can't open input file"); errors++; continue;}
      printfile(in,out,name);
      close(in);
    }
    exit(errors);	/* 2nd file causes segfault on FreeBSD-2.2.8.  Why? */
  }
}

/*
 * Format for storing 36 bits into 5 tape frames
 *    DEC core-dump mode	   ANSI compatible mode
 * |00 01 02 03 04 05 06|07	|__ 00 01 02 03 04 05 06|
 *  08 09 10 11 12 13|14 15	|__ 07 08 09 10 11 12 13|
 *  16 17,18 19 20|21 22 23	|__ 14 15 16 17 18 19 20|
 *  24 25 26 27|28 29 30 31	|__ 21 22 23 24 25 26 27|
 *  __ __ __ __ 32 33 34|35|	|35|28 29 30 31 32 33 34|
 * Note: "|" separate the 7-bit bytes, "__" are unused bits (which are zero).
 */

void shuffle(ptr,lh,rh)
unsigned char *ptr;
long *lh,*rh;
{	/* Convert from core-dump mode to ANSI mode for printing */
  unsigned char c;
  *lh = ptr[0]<<10 | ptr[1]<<2 | (ptr[2]&0xc0)>>6;	/* left  halfword */
  *rh = (ptr[2]&0x3f)<<12 | ptr[3]<<4 | ptr[4]&0x0f;	/* right halfword */
  c = ptr[4];
  ptr[4] = (c>>1)&0x07 | (c<<7)&0x80 | (ptr[3]<<3)&0x78;
  c = ptr[3];
  ptr[3] = (c>>4)&0x0f | (ptr[2]<<4)&0x70;
  c = ptr[2];
  ptr[2] = (c>>3)&0x1f | (ptr[1]<<5)&0x60;
  c = ptr[1];
  ptr[1] = (c>>2)&0x3f | (ptr[0]<<6)&0x40;
  ptr[0] = ptr[0]>>1;
}

printfile(in,out,name)
int in;
FILE *out;
char *name;
{
  unsigned char line[80], data[10], *cp;
  short count,i,j;
  long addr,hw[4];

  printf("\t\t36-bit dump of %s\n",name);
  printf("address    even word      odd word    SIXBIT     7-bit bytes in hex  ASCII text\n");
  addr = 0;
  while ((count=read(in,data,10)) > 0) {	/* 10 bytes = 2 words */
    for (i=count; i<10; i++) {
      data[i] = 0;
    }
    shuffle(&data[0],&hw[0],&hw[1]);
    shuffle(&data[5],&hw[2],&hw[3]);
    j = 0;
    for (i=0; i<10; i++) j |= data[i];	/* Check for 10 bytes of all zero */
    if (j != 0) {		   /* Suppress large blocks of zeros */
      sprintf(line,"%06o|%6o,%6o|%6o,%6o|",addr,hw[0],hw[1],hw[2],hw[3]);
      cp = line;
      while (*(++cp)) ;		/* locate end of string */
      for (i=0; i<4; i++) {
	*cp++ =  (hw[i] >> 12) + ' ';
	*cp++ = ((hw[i] >>  6) & 077) + ' ';
	*cp++ =  (hw[i] & 077) + ' ';
      }
      *cp++ = ' ';
      for (i=0; i<10; i++) {
        if (i < count)
          { sprintf(cp,"%02X",data[i]); cp += 2; }
        else
          { *cp++ = ' '; *cp++ = ' ';}
      }
      *cp++ = ' ';
      for (i=0; i<count; i++) {
        if (isprint(data[i] & 0177))
          *cp++ = (data[i] & 0177);
        else
          *cp++ = '.';		/* period for all non-printing chars */
      }
      *cp++ = '\n'; *cp++ = '\0';
      fputs(line,out);		/* use buffered output */
    }
    addr += (count / 5);	/* 5 bytes per 36-bit word */
  }
  printf("\n");
  return 0;
}
