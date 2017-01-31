Article 4021 of alt.sys.pdp10:
Path: nntp1.ba.best.com!news1.best.com!su-news-hub1.bbnplanet.com!news.bbnplanet.com!logbridge.uoregon.edu!news.oru.edu!sol.pdnt.net!bony.umtec.com!root
From: Daniel Seagraves <root@bony.umtec.com>
Newsgroups: alt.sys.pdp10
Subject: PDP-10 emulation code.
Date: Thu, 16 Jul 1998 15:53:59 -0500
Organization: Planet Digital Network Technologies
Lines: 536
Approved: Why bother?
Message-ID: <Pine.LNX.3.96.980716155034.31081B-100000@bony.umtec.com>
NNTP-Posting-Host: bony.umtec.com
Mime-Version: 1.0
Content-Type: TEXT/PLAIN; charset=US-ASCII
Xref: nntp1.ba.best.com alt.sys.pdp10:4021


Here ya go.
The project lives at e10@cosmic.com.
Free software, and under the GNU Public License.
Further updates will be available at ftp://bony.umtec.com/pub/e10

Only the HLL* and HRL* instructions are implemented yet.
If you would like to do a block of instructions, contact
root@bony.umtec.com.  I'm trying to keep (somewhat) control of edits so
people don't duplicate work.
Someone care to check to see if this does what it's supposed to do?

------------------------ snip - ka10.c -------------------------------

/* KA-10 SIMULATOR */
/* Daniel Seagraves <root@bony.umtec.com> started this stuff. */
/* Add your name and email here when you make meaningful changes */
/* Then mail the changes to me so I know about them! */

/* This program is free software, you can redistribute it and/or
   modify it under the terms of the GNU Public License as published
   by the Free Software Foundation.  It is copyrighted by myself and
   all those who contribute code and annote their names above */

/* DISCLAIMER:  If this program, or any form of it, compiled, source, or
otherwise, causes you computer to break, slow down, halt, catch fire, or
produce a handgun and demand money from you, we ARE NOT responsible for
it.  You can't hold any of the aforementioned people, or any party, liable
for any damages or percieved damages caused by the use and or distribution
of this software.  It's your fault.  No animals, small or otherwise, were
harmed in the production of this program, but I had to take my cat off of
the keyboard twice, and set him on the floor, and that made him mad at me.
*/

#include <stdio.h>
#include <string.h>

int     main() {
unsigned long mem_buffer_lo[16384];      /* 16K of core */
unsigned long mem_buffer_hi[16384];
unsigned long mi_lo;                    /* Memory Indicator */
unsigned long mi_hi;
unsigned long pc_lo;                    /* Program Counter */
unsigned long pc_hi;
unsigned long br_lo;                    /* Buffer Register */
unsigned long br_hi;
unsigned long ma,ir;                    /* Memory Addr, Inst. Register */
char    cmdline[128];                   /* The command line */
char    addrstr[8];                     /* String version of address */
char    datastr_l[8];                   /* String version of low data */
char    datastr_h[8];                   /* " " " high data */
char    cmd[3];                         /* The command (Use KS10 commands) */
unsigned long   data_l, data_h, addr;   /* Data and address longs */
int     x,y;                            /* Scratch variables. */
int     run;                            /* RUN state of the CPU */
unsigned long   e_addr;                 /* Effective address */
unsigned long   z;                      /* Scratch long */
int     ac;                             /* AC.  Used in inst. decode */

/* Banner.  When you make a change, ++ the version number.  It works
   like the ITS version numbers. Then change the comment to reflect what 
   you did.*/

printf("KA10 simulator version 4 (Halfword Data Transmission Instructions)\n");

getcmd:                                 /* This is a nasty habit left over
					   from BASIC I need to kill */
x = 0; y = 0; addr = 0;
data_l = 0; data_h = 0;                 /* Clear variables */

printf("KA> ");                         /* Prompt */
gets(cmdline);                          /* I know, this is unsafe, who cares? */

/* This produces 3 strings:  THe command, address, and low and high data. */

while(cmdline[x] != ' ' ) {
	if(x >= strlen(cmdline)) { cmd[y]=0; break; }
	cmd[y]=cmdline[x];
	x++;
	y++;
	}
y = 0;
x++;

while(cmdline[x] != ' ' ) {
	if(x >= strlen(cmdline)) { addrstr[y]=0; break; }
	addrstr[y]=cmdline[x];
	x++;
	y++;
	}
y = 0;
x++;

while(cmdline[x] != ' ') {
	if(x >= strlen(cmdline)) { datastr_h[y]=0; break; }
	datastr_h[y]=cmdline[x];
	x++;
	y++;
	}
datastr_h[y]=0;
y = 0;
x++;

while(cmdline[x] != ' ') {
	if(x >= strlen(cmdline)) { datastr_l[y]=0; break; }
	datastr_l[y]=cmdline[x];
	x++;
	y++;
	}
y = 0;
x++;

/* For debugging, echo input as parsed back to the user */

printf("STRINGS: cmd = %s, addr = %s, data = %s %s\n",cmd,addrstr,datastr_h, datastr_l);

/* Convert those strings to octal numbers */

addr = strtoul(addrstr, NULL, 8);
data_l = strtoul(datastr_l, NULL, 8);
data_h = strtoul(datastr_h, NULL, 8);

/* Deal with the commands */

if(!strncmp(cmd,"DM",2)){
		mem_buffer_lo[addr]=data_l;
		mem_buffer_hi[addr]=data_h;
		}

if(!strncmp(cmd,"EM",2)){
		mi_lo=mem_buffer_lo[addr];
		mi_hi=mem_buffer_hi[addr];
		printf("%lo %lo\n",mi_hi, mi_lo);
		}

if(!strncmp(cmd,"QU",2)){
		return(0);
		}

if(!strncmp(cmd,"ST",2)){
		/* Start the CPU. */
		printf("CPU: Entering RUN state\n");
		if(strlen(addrstr) > 0) {
			printf("CPU: Starting address is %lo\n",addr);
			pc_lo=(addr-1);
			}
		run=1;
		
		while(run){
		/* INSTRUCTION FETCH - Get the high bits in IR, and the low
		   bits in MA. */
		ma=mem_buffer_lo[pc_lo];
		ir=mem_buffer_hi[pc_lo];
		
		/* Increment the PC address */
		pc_lo++;

		/* figure up the address */
		/* If X is nonzero, add it to Y to get E. */

		/* Load the buffer register */
		br_lo=ma; br_hi=ir;
		e_addr=ma;              /* I Forgot this */             

		calc_eaddr:
		z = (017 & br_hi);
		if(z >= 1){
			e_addr = (br_lo+mem_buffer_lo[z]);
			printf("CPU: Index register is %lo\n",z);
		}

		/* If I is 0, we use direct addressing.
		   If I is 1, we get indirect addressing. */

		if(020 & br_hi){
			br_lo=(mem_buffer_lo[e_addr]);
			br_hi=(mem_buffer_hi[e_addr]);
			goto calc_eaddr;        /* Loop until no more
						   indirects. */
			}
		printf("CPU: E_ADDR figured at %lo\n",e_addr);                  

			
		/* HERE'S WHERE INSTRUCTION DECODING STARTS
		   At this point, e_addr is the effective address,
		   and the instruction is in ir.  Buffer register
		   could be random, and you shouldn't do much with it
		   unless you reload it.  Or, more likely, I fudged,
		   and something's incorrect, in which case you need
		   to tell me.   The following is how I think I'd get
		   the instruction... */

		if(ir & 0500000){
			/* Halfword left to left */
			/* Left half of E goes to AC. */
			ac=((ir & 0740) >> 5);
			printf("CPU: HLL %o %lo\n",ac,e_addr);
			mem_buffer_hi[ac]=mem_buffer_hi[e_addr];
			}

		if(ir & 0501000){
			/* Halfword Left to Left Immediate */
			/* Clear AC Left */
			ac=((ir & 0740) >> 5);
			printf("CPU: HLLI %o %lo\n",ac,e_addr);
			mem_buffer_hi[ac]=0;
			}

		if(ir & 0502000){
			/* Halfword Left to Left Memory */
			/* AC goes to E */
			ac=((ir & 0740) >> 5);
			printf("CPU: HLLM %o %lo\n",ac,e_addr);
			mem_buffer_hi[e_addr]=mem_buffer_hi[ac];
			}
		
		if(ir & 0503000){
			/* Halfword Left to Left Self */
			/* E to E, but also AC if it's nonzero */
			ac=((ir & 0740) >> 5);
			printf("CPU: HLLS %o %lo\n",ac,e_addr);
			if(ac==0) { break; }
			mem_buffer_hi[ac]=mem_buffer_hi[e_addr];
			}

		if(ir & 0510000){
			/* Halfword left to left, Zeros */
			/* Left half of E goes to AC */
			ac=((ir & 0740) >> 5);
			printf("CPU: HLLZ %o %lo\n",ac,e_addr);
			mem_buffer_hi[ac]=mem_buffer_hi[e_addr];
			mem_buffer_lo[ac]=0;
			}

		if(ir & 0511000){
			/* Halfword Left to Left Zeros, Immediate */
			/* Clear AC Left */
			ac=((ir & 0740) >> 5);
			printf("CPU: HLLZI %o %lo\n",ac,e_addr);
			mem_buffer_hi[ac]=0;
			mem_buffer_lo[ac]=0;
			}

		if(ir & 0512000){
			/* Halfword Left to Left Zeros, Memory */
			/* AC goes to E */
			ac=((ir & 0740) >> 5);
			printf("CPU: HLLZM %o %lo\n",ac,e_addr);
			mem_buffer_hi[e_addr]=mem_buffer_hi[ac];
			mem_buffer_lo[e_addr]=0;
			}
		
		if(ir & 0513000){
			/* Halfword Left to Left Zeros, Self */
			/* E to E, but also AC if it's nonzero */
			ac=((ir & 0740) >> 5);
			printf("CPU: HLLZS %o %lo\n",ac,e_addr);
			if(ac==0) { mem_buffer_hi[e_addr]=0; break; }
			mem_buffer_hi[ac]=mem_buffer_hi[e_addr];
			mem_buffer_hi[ac]=0;
			}

		if(ir & 0520000){
			/* Halfword left to left Ones */
			/* Left half of E goes to AC. */
			ac=((ir & 0740) >> 5);
			printf("CPU: HLLO %o %lo\n",ac,e_addr);
			mem_buffer_hi[ac]=mem_buffer_hi[e_addr];
			mem_buffer_lo[ac]=0777777;
			}

		if(ir & 0521000){
			/* Halfword Left to Left Ones, Immediate */
			/* Clear AC Left */
			ac=((ir & 0740) >> 5);
			printf("CPU: HLLOI %o %lo\n",ac,e_addr);
			mem_buffer_hi[ac]=0;
			mem_buffer_lo[ac]=0777777;
			}

		if(ir & 0522000){
			/* Halfword Left to Left Ones, Memory */
			/* AC goes to E */
			ac=((ir & 0740) >> 5);
			printf("CPU: HLLOM %o %lo\n",ac,e_addr);
			mem_buffer_hi[e_addr]=mem_buffer_hi[ac];
			mem_buffer_lo[e_addr]=0777777;
			}
		
		if(ir & 0523000){
			/* Halfword Left to Left Ones, Self */
			/* E to E, but also AC if it's nonzero */
			ac=((ir & 0740) >> 5);
			printf("CPU: HLLOS %o %lo\n",ac,e_addr);
			if(ac==0) { mem_buffer_lo[ac]=0777777; break; }
			mem_buffer_hi[ac]=mem_buffer_hi[e_addr];
			mem_buffer_lo[ac]=0777777;
			}

		if(ir & 0530000){
			/* Halfword left to left Extend*/
			/* Left half of E goes to AC. */
			ac=((ir & 0740) >> 5);
			printf("CPU: HLLE %o %lo\n",ac,e_addr);
			mem_buffer_hi[ac]=mem_buffer_hi[e_addr];
			if(mem_buffer_hi[e_addr] & 400000){
				mem_buffer_lo[ac]=0777777;
				break;
				}
			mem_buffer_lo[ac]=0;
			}

		if(ir & 0531000){
			/* Halfword Left to Left Extend, Immediate */
			/* Clear AC Left */
			ac=((ir & 0740) >> 5);
			printf("CPU: HLLEI %o %lo\n",ac,e_addr);
			mem_buffer_hi[ac]=0; mem_buffer_lo[ac]=0;
			}

		if(ir & 0532000){
			/* Halfword Left to Left Extend, Memory */
			/* AC goes to E */
			ac=((ir & 0740) >> 5);
			printf("CPU: HLLEM %o %lo\n",ac,e_addr);
			mem_buffer_hi[e_addr]=mem_buffer_hi[ac];
			if(mem_buffer_hi[ac] & 400000){
				mem_buffer_lo[e_addr]=0777777;
				break;
				}
			mem_buffer_lo[e_addr]=0;
			}
		
		if(ir & 0533000){
			/* Halfword Left to Left Extend, Self */
			/* E to E, but also AC if it's nonzero */
			ac=((ir & 0740) >> 5);
			printf("CPU: HLLES %o %lo\n",ac,e_addr);
				if(mem_buffer_hi[e_addr] & 400000){
					mem_buffer_lo[e_addr]=0777777;
					break;
					}
				mem_buffer_lo[e_addr]=0;
			if(ac==0){ break ; }
			mem_buffer_hi[ac]=mem_buffer_hi[ac];
			if(mem_buffer_hi[ac] & 400000){
				mem_buffer_lo[ac]=0777777;
				break;
				}
			mem_buffer_lo[ac]=0;
			}
		
		/* NEXT! */

		if(ir & 0504000){
			/* Halfword right to left */
			/* Right half of E goes to AC. */
			ac=((ir & 0740) >> 5);
			printf("CPU: HRL %o %lo\n",ac,e_addr);
			mem_buffer_hi[ac]=mem_buffer_lo[e_addr];
			}

		if(ir & 0505000){
			/* Halfword Right to Left Immediate */
			ac=((ir & 0740) >> 5);
			printf("CPU: HRLI %o %lo\n",ac,e_addr);
			mem_buffer_hi[ac]=0;
			}

		if(ir & 0506000){
			/* Halfword Right to Left Memory */
			ac=((ir & 0740) >> 5);
			printf("CPU: HRLM %o %lo\n",ac,e_addr);
			mem_buffer_hi[e_addr]=mem_buffer_lo[ac];
			}
		
		if(ir & 0507000){
			/* Halfword Right to Left Self */
			ac=((ir & 0740) >> 5);
			printf("CPU: HRLS %o %lo\n",ac,e_addr);
			mem_buffer_hi[e_addr]=mem_buffer_lo[e_addr];
			if(ac >= 1) { 
				mem_buffer_hi[ac]=mem_buffer_lo[e_addr];
				}
			}

		if(ir & 0514000){
			/* Halfword Right to left, Zeros */
			ac=((ir & 0740) >> 5);
			printf("CPU: HRLZ %o %lo\n",ac,e_addr);
			mem_buffer_hi[ac]=mem_buffer_lo[e_addr];
			mem_buffer_lo[ac]=0;
			}

		if(ir & 0515000){
			/* Halfword Right to Left Zeros, Immediate */
			ac=((ir & 0740) >> 5);
			printf("CPU: HRLZI %o %lo\n",ac,e_addr);
			mem_buffer_hi[ac]=mem_buffer_lo[e_addr];
			mem_buffer_lo[ac]=0;
			}

		if(ir & 0516000){
			/* Halfword Right to Left Zeros, Memory */
			ac=((ir & 0740) >> 5);
			printf("CPU: HRLZM %o %lo\n",ac,e_addr);
			mem_buffer_hi[e_addr]=mem_buffer_lo[ac];
			mem_buffer_lo[e_addr]=0;
			}
		
		if(ir & 0517000){
			/* Halfword Right to Left Zeros, Self */
			ac=((ir & 0740) >> 5);
			printf("CPU: HRLZS %o %lo\n",ac,e_addr);
			if(ac>=1) {
				mem_buffer_hi[ac]=mem_buffer_lo[e_addr];
				mem_buffer_lo[ac]=0;
				}
			mem_buffer_hi[e_addr]=mem_buffer_lo[e_addr];
			mem_buffer_lo[e_addr]=0;
			}

		if(ir & 0524000){
			/* Halfword Right to left Ones */
			ac=((ir & 0740) >> 5);
			printf("CPU: HRLO %o %lo\n",ac,e_addr);
			mem_buffer_hi[ac]=mem_buffer_lo[e_addr];
			mem_buffer_lo[ac]=0777777;
			}

		if(ir & 0525000){
			/* Halfword Right to Left Ones, Immediate */
			ac=((ir & 0740) >> 5);
			printf("CPU: HRLOI %o %lo\n",ac,e_addr);
			mem_buffer_hi[ac]=mem_buffer_lo[e_addr];
			mem_buffer_lo[ac]=0777777;
			}

		if(ir & 0526000){
			/* Halfword Right to Left Ones, Memory */
			ac=((ir & 0740) >> 5);
			printf("CPU: HRLOM %o %lo\n",ac,e_addr);
			mem_buffer_hi[e_addr]=mem_buffer_lo[ac];
			mem_buffer_lo[e_addr]=0777777;
			}
		
		if(ir & 0527000){
			/* Halfword Right to Left Ones, Self */
			ac=((ir & 0740) >> 5);
			printf("CPU: HRLOS %o %lo\n",ac,e_addr);
			if(ac>=1) {
				mem_buffer_hi[ac]=mem_buffer_lo[e_addr];
				mem_buffer_lo[ac]=0777777;
				}
			mem_buffer_hi[e_addr]=mem_buffer_lo[e_addr];
			mem_buffer_lo[e_addr]=0777777;
			}

		if(ir & 0534000){
			/* Halfword Right to left Extend*/
			ac=((ir & 0740) >> 5);
			printf("CPU: HRLE %o %lo\n",ac,e_addr);
			mem_buffer_hi[ac]=mem_buffer_lo[e_addr];
			if(mem_buffer_hi[e_addr] & 400000){
				mem_buffer_lo[ac]=0777777;
				break;
				}
			mem_buffer_lo[ac]=0;
			}

		if(ir & 0535000){
			/* Halfword Right to Left Extend, Immediate */
			ac=((ir & 0740) >> 5);
			printf("CPU: HRLEI %o %lo\n",ac,e_addr);
			mem_buffer_hi[ac]=mem_buffer_lo[ac];
			if(mem_buffer_hi[ac] & 0400000){
				mem_buffer_lo[ac]=0777777;
				break;
				}
			mem_buffer_lo[ac]=0;
			}

		if(ir & 0536000){
			/* Halfword Right to Left Extend, Memory */
			ac=((ir & 0740) >> 5);
			printf("CPU: HRLEM %o %lo\n",ac,e_addr);
			mem_buffer_hi[e_addr]=mem_buffer_lo[ac];
			if(mem_buffer_hi[ac] & 400000){
				mem_buffer_lo[e_addr]=0777777;
				break;
				}
			mem_buffer_lo[e_addr]=0;
			}
		
		if(ir & 0537000){
			/* Halfword Right to Left Extend, Self */
			ac=((ir & 0740) >> 5);
			printf("CPU: HRLES %o %lo\n",ac,e_addr);
			mem_buffer_hi[e_addr]=mem_buffer_lo[e_addr];
				if(mem_buffer_hi[e_addr] & 400000){
					mem_buffer_lo[e_addr]=0777777;
					break;
					}
				mem_buffer_lo[e_addr]=0;
			if(ac>=1){ 
				mem_buffer_hi[ac]=mem_buffer_lo[ac];
				if(mem_buffer_hi[ac] & 400000){
					mem_buffer_lo[ac]=0777777;
					break;
					}
				mem_buffer_lo[ac]=0;
				}
			}



		if(pc_lo==16384){       /* set this number to top of core */
			printf("CPU: Attempted to set PC past top of core\n");
			run=0;
			}
		if((ir & ma)==0){
			printf("CPU: 0 in core\n");
			run = 0;
			}
		}
		printf("CPU: Leaving RUN state\n");
		printf("CPU: PC: %lo %lo\n",pc_hi,pc_lo);
		}

goto getcmd;                            /* Like I said earlier,
					   nasty habit from BASIC... */ 

}





