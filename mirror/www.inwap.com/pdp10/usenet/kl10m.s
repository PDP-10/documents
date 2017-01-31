Article 5418 of alt.sys.pdp10:
Path: nntp1.ba.best.com!news1.best.com!newshub.sdsu.edu!newsfeed.cs.wisc.edu!loops.cs.wisc.edu!enews.sgi.com!diablo.netcom.net.uk!netcom.net.uk!news.tele.dk!203.50.2.79!intgwlon.nntp.telstra.net!news-server.bigpond.net.au!not-for-mail
From: Mark Garrett <Mark.Garrett@wedontwantyourspam.com.au>
Newsgroups: alt.sys.pdp10
Subject: May thet rot in hell, this will never be finished now
Organization: Garetech Computer Solutions
Lines: 2143
Message-ID: <B7615988.191AC%Mark.Garrett@wedontwantyourspam.com.au>
Mime-Version: 1.0
Content-Type: text/plain; charset="US-ASCII"
Content-Transfer-Encoding: 7bit
User-Agent: Microsoft-Outlook-Express-Macintosh-Edition/5.02.2022
Date: Thu, 28 Jun 2001 12:00:27 GMT
NNTP-Posting-Host: 144.132.244.163
X-Complaints-To: news@bigpond.net.au
X-Trace: news-server.bigpond.net.au 993729627 144.132.244.163 (Thu, 28 Jun 2001 22:00:27 EST)
NNTP-Posting-Date: Thu, 28 Jun 2001 22:00:27 EST
Xref: nntp1.ba.best.com alt.sys.pdp10:5418

Hi all,
    After the 26-Jun-2001 my project is at an end so I post here my results
so far maybe it will make amusing reading, maybe not.

#@(#)$Id: kl10m.s,v 1.6 2001/04/27 11:02:23 mark Exp mark $
# @(#)$Log: kl10m.s,v $
#;; Revision 1.6  2001/04/27  11:02:23  mark
#;; friday checkin
#;;
#;; Revision 1.5  2000/10/27  13:07:45  mark
#;; now have completed code for vtophyrx - bet it has buggs
#;;
#;; Revision 1.4  2000/10/27  04:20:59  mark
#;; about to change from macro fetch in single routine fetch that
#;; maybe more cache efficent with alpha even though we have some extra
#;; jumps.
#;;
#;; Revision 1.3  2000/10/13  12:32:30  mark
#;; friday night checkin now has good part of vir to phy memory done
#;;
#;; Revision 1.2  2000/10/03  00:31:24  mark
#;; cpt
#;;
# Revision 1.1  2000/08/27  12:18:48  mark
# Initial revision
#

        .arch ev4
    .set noat
        .set volatile
    .set noreorder
    .set nomacro 

    .include "regdef.h"    # define register names
    .include "dcode.h"    # DCODE is ref by base reg s0
    .include "kl10_a.h"    # MM is reg by base reg s1

.macro    inc_PC
    and    s2, t11, t1        # t1 get PC section part
    lda    v0, 1(s2)        # inc the PC
    bic    v0, t11, v0        # v0 get PC 18bit and so wrap
    or    t1, v0, s2        # recombine PC with section part
.endm

vtophylabrx    .assigna    0
.macro    vtophy_rx
# Virtual to physical address with reference type of FETCH
# Inputs:    t0 = 23bit virtual
#        t1 = 5/9 bit section number
#        s5 = reg base either CAB or PAB
# Outputs:    a0 = phy address (axp) may point to a reg or in KL memory
# s0==DCODE, s1==membase, s2==PC, s3==flags, s5==effective register base

    blt    s3, VMrx\&vtophylabrx # is VM enabled?
    s8addq    t0, s1, a0    # get phy axp address membase s1
    s8addq    t0, s5, v0
    subq    t0,017, t6    # is the address inside the accumlators
    cmovlt    t6, v0, a0    # move reg address to a0 instead
    br    endvtophyrx\&vtophylabrx
checkcacherx\&vtophylabrx:
# make key of sect+page

    srl    t0, 9, v0        # get section + page
    subl    v0, ra, v0        # subtract from lower 32bits of ra
    bne    v0, cachemissrx\&vtophylabrx    # not matched cache miss
# here then we have a valid cache hit
    extwl    ra, 4, t2        # get core pg no into t2
    srl    ra, 32+15+5, t3        # get GPWSC into t3
    br    cstpgupdrx\&vtophylabrx

VMrx\&vtophylabrx:
    bne    ra, checkcacherx\&vtophylabrx
cachemissrx\&vtophylabrx:
    ldq    t5, spt-MM(s1)!lituse_base!3    # get spt
    bic    t5,t10,t5        # clear non 36 bit part

    sll    s3, sll_user, t2    # move user flag to sign  v0
    sll    s3, 28,  t4        # move PCU flag to sign  t4
    srl    s3, 2, v0        # get PXCT flag in v0
    cmovlt    v0,t4, t2        # if PXCT then move PCU to t2

    extwl    s3, 0, t4        # get EBR  in t4
    extwl    s3, 2, t6        # get UBR  in t6
    cmovgt    t2, t6, t4        # if user ==1 then UBR
    sll    t4, 9 , t4        # Base reg is a page number shift left so its a
PDP10 word address 
# now t4 is process base register either UBR or EBR
    mov    USECT, v0        # USECT == ESECT ==540
    addq    v0, t1, v0        # SECTNO+0540
    addq    v0, t4, v0        # still PDP10 address add SECTNO+540+BASE
    mov    015, t3            # set flags PWC = 1
    s8addq    v0, s1, v0        # convert to axp address using memory base
s1 
    ldq    t2, (v0)        # fetch page table pointer
    bic    t2, t10, t2        # clear non  36bit part

fetchptrrx\&vtophylabrx:
# t2 = ar = fetched page table pointer
    srl    t2, 29, v0        # get page flags P,W,C in lower 4 bits of v0
...|P|W|0|C| 
    and    t3, v0, t3        # and the flags with current PWC
    srl    t2, 36-3, v0        # get type flags in v0
    lda    v0, -1(v0)        # dec typeflags
    beq    v0, pgtblimedrx\&vtophylabrx    # type=001 Immediate
    lda    v0, -1(v0)        # dec typeflags
    beq    v0, pgtblsharrx\&vtophylabrx    # type=010 Shared
    lda    v0, -1(v0)        # dec typeflags
    bne    v0, FLTNOACC        # if not zero it was not 011 shared must have
been either 000 or 1xx so flt noacc
pgtblindirrx\&vtophylabrx:
# type=011 Indirect
    srl    t2, 18, t1        # get new section number
    mov    511, v0            # 9 bit and mask
    and    t1, v0, t1        # get lower 9 bits as pageno  number index

    bic    t2, t11, v0        # get 18 bit SPTX
    addq    t5, v0, v0        # SPT+SPTX
    s8addq    v0, s1, v0        # convert to AXP address
    ldq    t2, (v0)        # fetch storage address
    bic    t2, t10, t2        # clear non 36 bit

    srl    t2, 18, v0        # get 6 bits that define in core
    and    v0, 077, v0        # clear off anything but 6 bit core flag
    bne    v0, FLTNOTCORE        # branch if not in core

    bic    t2, t11, v0        # get 18 bits if storage address
5bitsMBZ+13bit corepgno
    sll    v0, 9, v0        # convert page no to PDP-10 phy address
    addq    t1, v0, v0        # add 9 bits of section index
    s8addq    v0, s1, v0        # convert to axp address
    ldq    t2,(v0)            # fetch new page table pointer
    bic    t2, t10, t2        # clear non 36 bit part
# check for interupts
    ldq    at, interupt10-MM(s1)!lituse_base!3
    beq    at,fetchptrrx\&vtophylabrx    # branch backward and do it all
again 
    br    gointerupt        # Interupt DISP request interupt != 0
    
pgtblsharrx\&vtophylabrx:
# type=010 Shared 
    bic    t2,t11, v0        # get SPTX 18 bits
    addq    t5, v0, v0        # SPT+SPTX

    s8addq    v0, s1, v0        # get axp address
    ldq    t2, (v0)        # fetch new pointer
    bic    t2, t10, t2        # clear non 36 bit part

pgtblimedrx\&vtophylabrx:
# type=001 now have a storage address of page table in t2
    srl    t2, 18, v0
    and    v0, 077, v0
    bne    v0,FLTNOTCORE

    bic    t2, t11, t2        # get 18 bits if storage address
5bitsMBZ+13bit corepgno
    sll    t2, 9 , v0        # convert core page no to address
    s8addq    v0, s1, v0        # convert to axp address of page table
# now do CST things for page table t2 == corepagenno of Page Table
    
    ldq    v0, cst-MM(s1)!lituse_base!3    # get CST table pointer
    bic    v0, t10, v0        # clear non 36 bit part
    addq    v0, t2, t6        # get CST+corepageno
    s8addq    t6, s1, t6        # get axp address of CST entry
    ldq    v0, (t6)        # fetch CST entry
    bic    v0, t10, v0        # clear non 36 bit part

    sll    v0, 30, at        # get top 6 bits of CST entry
    beq    at, FLTNOACC        # 0 is no access
    ldq    at, cstmask-MM(s1)!lituse_base!3    # get cst mask
    bic    at, t10, at        # get 36 bit part of mask
    and    v0, at, v0        # CSTentry and CSTmask
    
    ldq    at, cstdata-MM(s1)!lituse_base!3    # get cst data
    bic    at, t10, at        # get 36 bit part of cstdata
    or    v0, at, v0        # CSTentry or CSTdata
    stq    v0, (t6)        # store CSTentry back

    mov    511, v0            # 9 bit and mask
    srl    t0, 9, at        # gt actual page_no  first time using actual
page no from VA index into pgtbl
    and    at, v0, t1        # get 9 bits only
# t2 was cleared as 18 bits b4
    sll    t2, 9, v0        # we did this shift before the cst update - t2
is a 13bit corepgno of a pgtable
    
    or    v0, t1, v0        # add page_no to core page address of page table
index for page pointer
    s8addq    v0, s1, v0        # get axp address
    ldq    t2, (v0)        # fetch page pointer
    srl    t2, 29, v0        # get flags PWC in lower bits
    and    t3, v0, t3        # add flags to current PWC
    srl    t2, 36-3, v0        # get type in v0
    lda    v0, -1(v0)        # dec
    beq    v0, pgimedrx\&vtophylabrx    # type=001 Immediate
    lda    v0, -1(v0)        # dec typeflags
    beq    v0, pgsharrx\&vtophylabrx    # type=010 Shared
    lda    v0, -1(v0)        # dec typeflags
    beq    v0, pgtblindirrx\&vtophylabrx    #
    br     FLTNOACC        # if not zero it was not 011 shared must have
been either 000 or 1xx so flt noacc
pgsharrx\&vtophylabrx:
    bic    t2, t11, v0        # get SPTX
    addq    t5, 0, v0         # SPT + SPTX
    s8addq    v0, s1, v0        # convert to axp addr
    ldq    t2, (v0)        # fetch pg ptr
    bic    t2, t10, t2        # 36bits only
pgimedrx\&vtophylabrx:
    sll    t2, 18, v0        # get 6 bit that define core
    and    v0, 077, v0        # 6 bits only
    bne    v0, FLTNOTCORE
    bic    t2, t11, t2        # get 18 bit storage address phy core pg
cstpgupdrx\&vtophylabrx:
# now have real user pgno of core in t2 do CST update
    ldq    v0, cst-MM(s1)!lituse_base!3    # get CST pointer
    bic    v0, t10, v0        # 36bits only
    addq    v0, t2, t6        # CST+corepgno
    s8addq    t6, s1, t6        # get axp address of CSTentry
    ldq    v0, (t6)        # fetch CSTentry
    bic    v0, t10, v0        # 36bits only
    sll    v0, 30, at        # get top 6 bits of CSTentry
    beq    at, FLTNOACC        # 0=noaccess
    ldq    at, cstmask-MM(s1)!lituse_base!3    # get CSTmask
    bic    at, t10, at        # 36bits only
    and    v0, at, v0        # CSTentry and CSTmask
# this is a fetch for rx so no need to do writeable page checks
# allow the CST update even if public is failed later
    ldq    at, cstdata-MM(s1)!lituse_base!3    # get CSTdata
    bic    at, t10, at        # 36bits only
    or    v0, at, v0        # CSTentry or CSTdata
    stq    v0, (t6)        # store CSTentry back

    sll    t2, 9 , t2        # cvt core pg no to PDP-10 address
    mov    510, v0
    and    t0, v0, at        # get 9 bit address of word in page
    addq    t2, at, v0        # v0 = PDP-10 address of word in phy memory
    s8addq    v0, s1, a0        # a0 = AXP address of word
# t3 = G|P|W|S|C  now test public access of page
    srl    t3, 3, v0        # get P flag in low bit
    blbs    v0, updatecacherx\&vtophylabrx    # branch page is public
# ok its a private page aka concealed page are we in supervisor mode
    sll    s3, sll_public, v0    # get processor flag P in sign
    bgt    v0, updatecacherx\&vtophylabrx    # branch we are in supervisor
allow access 
# here if page is private and not in supervisor, check its a portal
    ldq    v0, (a0)        # fetch the instruction
#     is it portal ?
    bic    v0, t10, v0        # 36bits only
    srl    v0, 36-15, v0
    mov    025404, at        # portal instruction
    subq    v0, at, at
    bne    at, FLTNOPUBLIC
updatecacherx\&vtophylabrx:
    sll    t3, 18, t3
    srl    t2, 9, v0        # get  back core pgno
    or    t2, t3, v0        # get GPWSC+MBZ5bits+13bit corepgno
    sll    v0, 32, v0        # make room for section+pg
    srl    t0, 9, t3
    or    t3, v0, ra        # store new translation

#*********************************************
endvtophyrx\&vtophylabrx:


vtophylabrx    .assigna    \&vtophylabrx + 1
.endm

vtophylabr    .assigna    0
.macro    vtophy_r
# Virtual to physical address with reference type of READ
# Inputs:    t0 = 23bit virtual
#        t1 = 5/9 bit section number
# Outputs:    a0 = phy address (axp) may point to a reg or in KL memory
# s0==DCODE, s1==membase, s2==PC, s3==flags, s5==effective register base
# This is very similar to _rx. Except the difference here is with public
access
# If the processor is in public and the page is private there is no valid
access

    blt    s3, VMr\&vtophylabr # is VM enabled?
    s8addq    t0, s1, a0    # get phy axp address membase s1
    s8addq    t0, s5, v0
    subq    t0,017, t6    # is the address inside the accumlators
    cmovlt    t6, v0, a0    # move reg address to a0 instead
    br    endvtophyr\&vtophylabr
checkcacher\&vtophylabr:
# make key of sect+page
    srl    t0, 9, v0        # get section + page
    subl    v0, ra, v0        # subtract from lower 32bits of ra
    bne    v0, cachemissr\&vtophylabr    # not matched cache miss
# here then we have a valid cache hit
    extwl    ra, 4, t2        # get core pg no into t2
    srl    ra, 32+15+5, t3        # get GPWSC into t3
    br    cstpgupdr\&vtophylabr

VMr\&vtophylabr:
    bne    ra, checkcacher\&vtophylabr
cachemissr\&vtophylabr:
    ldq    t5, spt-MM(s1)!lituse_base!3    # get spt
    bic    t5,t10,t5        # clear non 36 bit part

    sll    s3, sll_user, t2    # move user flag to sign  v0
    sll    s3, 28,  t4        # move PCU flag to sign  t4
    srl    s3, 2, v0        # get PXCT flag in v0
    cmovlt    v0,t4, t2        # if PXCT then move PCU to t2

    extwl    s3, 0, t4        # get EBR  in t4
    extwl    s3, 2, t6        # get UBR  in t6
    cmovgt    t2, t6, t4        # if user ==1 then UBR
    sll    t4, 9 , t4        # Base reg is a page number shift left so its a
PDP10 word address 

# now t4 is process base register either UBR or EBR
    mov    USECT, v0        # USECT == ESECT ==540
    addq    v0, t1, v0        # SECTNO+0540
    addq    v0, t4, v0        # still PDP10 address add SECTNO+540+BASE
    mov    015, t3            # set flags PWC = 1
    s8addq    v0, s1, v0        # convert to axp address using memory base
s1 
    ldq    t2, (v0)        # fetch page table pointer
    bic    t2, t10, t2        # clear non  36bit part

fetchptrr\&vtophylabr:
# t2 = ar = fetched page table pointer
    srl    t2, 29, v0        # get page flags P,W,C in lower 4 bits of v0
...|P|W|0|C| 
    and    t3, v0, t3        # and the flags with current PWC
    srl    t2, 36-3, v0        # get type flags in v0
    lda    v0, -1(v0)        # dec typeflags
    beq    v0, pgtblimedr\&vtophylabr    # type=001 Immediate
    lda    v0, -1(v0)        # dec typeflags
    beq    v0, pgtblsharr\&vtophylabr    # type=010 Shared
    lda    v0, -1(v0)        # dec typeflags
    bne    v0, FLTNOACC        # if not zero it was not 011 shared must have
been either 000 or 1xx so flt noacc
pgtblindirr\&vtophylabr:
# type=011 Indirect
    srl    t2, 18, t1        # get new section number
    mov    511, v0            # 9 bit and mask
    and    t1, v0, t1        # get lower 9 bits as pageno  number index


    bic    t2, t11, v0        # get 18 bit SPTX
    addq    t5, v0, v0        # SPT+SPTX
    s8addq    v0, s1, v0        # convert to AXP address
    ldq    t2, (v0)        # fetch storage address
    bic    t2, t10, t2        # clear non 36 bit

    srl    t2, 18, v0        # get 6 bits that define in core
    and    v0, 077, v0        # clear off anything but 6 bit core flag
    bne    v0, FLTNOTCORE        # branch if not in core

    bic    t2, t11, v0        # get 18 bits if storage address
5bitsMBZ+13bit corepgno
    sll    v0, 9, v0        # convert page no to PDP-10 phy address
    addq    t1, v0, v0        # add 9 bits of section index
    s8addq    v0, s1, v0        # convert to axp address
    ldq    t2,(v0)            # fetch new page table pointer
    bic    t2, t10, t2        # clear non 36 bit part
# check for interupts
    ldq    at, interupt10-MM(s1)!lituse_base!3
    beq    at,fetchptrr\&vtophylabr    # branch backward and do it all again
    br    gointerupt         # Interupt DISP request interupt != 0

    
pgtblsharr\&vtophylabr:
# type=010 Shared 
    bic    t2,t11, v0        # get SPTX 18 bits
    addq    t5, v0, v0        # SPT+SPTX

    s8addq    v0, s1, v0        # get axp address
    ldq    t2, (v0)        # fetch new pointer
    bic    t2, t10, t2        # clear non 36 bit part

pgtblimedr\&vtophylabr:
# type=001 now have a storage address of page table in t2
    srl    t2, 18, v0
    and    v0, 077, v0
    bne    v0,FLTNOTCORE

    bic    t2, t11, t2        # get 18 bits if storage address
5bitsMBZ+13bit corepgno
    sll    t2, 9 , v0        # convert core page no to address
    s8addq    v0, s1, v0        # convert to axp address of page table
# now do CST things for page table t2 == corepagenno of Page Table
    
    ldq    v0, cst-MM(s1)!lituse_base!3    # get CST table pointer
    bic    v0, t10, v0        # clear non 36 bit part
    addq    v0, t2, t6        # get CST+corepageno
    s8addq    t6, s1, t6        # get axp address of CST entry
    ldq    v0, (t6)        # fetch CST entry
    bic    v0, t10, v0        # clear non 36 bit part

    sll    v0, 30, at        # get top 6 bits of CST entry
    beq    at, FLTNOACC        # 0 is no access
    ldq    at, cstmask-MM(s1)!lituse_base!3    # get cst mask
    bic    at, t10, at        # get 36 bit part of mask
    and    v0, at, v0        # CSTentry and CSTmask
    
    ldq    at, cstdata-MM(s1)!lituse_base!3    # get cst data
    bic    at, t10, at        # get 36 bit part of cstdata
    or    v0, at, v0        # CSTentry or CSTdata
    stq    v0, (t6)        # store CSTentry back

    mov    511, v0            # 9 bit and mask
    srl    t0, 9, at        # gt actual page_no  first time using actual
page no from VA index into pgtbl
    and    at, v0, t1        # get 9 bits only
# t2 was cleared as 18 bits b4
    sll    t2, 9, v0        # we did this shift before the cst update - t2
is a 13bit corepgno of a pgtable
    
    or    v0, t1, v0        # add page_no to core page address of page table
index for page pointer
    s8addq    v0, s1, v0        # get axp address
    ldq    t2, (v0)        # fetch page pointer
    srl    t2, 29, v0        # get flags PWC in lower bits
    and    t3, v0, t3        # add flags to current PWC
    srl    t2, 36-3, v0        # get type in v0
    lda    v0, -1(v0)        # dec
    beq    v0, pgimedr\&vtophylabr    # type=001 Immediate
    lda    v0, -1(v0)        # dec typeflags
    beq    v0, pgsharr\&vtophylabr    # type=010 Shared
    lda    v0, -1(v0)        # dec typeflags
    beq    v0, pgtblindirr\&vtophylabr    #
    br     FLTNOACC        # if not zero it was not 011 shared must have
been either 000 or 1xx so flt noacc
pgsharr\&vtophylabr:
    bic    t2, t11, v0        # get SPTX
    addq    t5, 0, v0         # SPT + SPTX
    s8addq    v0, s1, v0        # convert to axp addr
    ldq    t2, (v0)        # fetch pg ptr
    bic    t2, t10, t2        # 36bits only
pgimedr\&vtophylabr:
    sll    t2, 18, v0        # get 6 bit that define core
    and    v0, 077, v0        # 6 bits only
    bne    v0, FLTNOTCORE
    bic    t2, t11, t2        # get 18 bit storage address phy core pg
cstpgupdr\&vtophylabr:
# now have real user pgno of core in t2 do CST update
    ldq    v0, cst-MM(s1)!lituse_base!3    # get CST pointer
    bic    v0, t10, v0        # 36bits only
    addq    v0, t2, t6        # CST+corepgno
    s8addq    t6, s1, t6        # get axp address of CSTentry
    ldq    v0, (t6)        # fetch CSTentry
    bic    v0, t10, v0        # 36bits only
    sll    v0, 30, at        # get top 6 bits of CSTentry
    beq    at, FLTNOACC        # 0=noaccess
    ldq    at, cstmask-MM(s1)!lituse_base!3    # get CSTmask
    bic    at, t10, at        # 36bits only
    and    v0, at, v0        # CSTentry and CSTmask
# this is a fetch for r so no need to do writeable page checks
# allow the CST update even if public is failed later
    ldq    at, cstdata-MM(s1)!lituse_base!3    # get CSTdata
    bic    at, t10, at        # 36bits only
    or    v0, at, v0        # CSTentry or CSTdata
    stq    v0, (t6)        # store CSTentry back

    sll    t2, 9 , t2        # cvt core pg no to PDP-10 address
    mov    510, v0
    and    t0, v0, at        # get 9 bit address of word in page
    addq    t2, at, v0        # v0 = PDP-10 address of word in phy memory
    s8addq    v0, s1, a0        # a0 = AXP address of word
# t3 = G|P|W|S|C  now test public access of page
    srl    t3, 3, v0        # get P flag in low bit
    blbs    v0, endvtophyr\&vtophylabr    # branch page is public
# ok its a private page aka concealed page are we in supervisor mode
    sll    s3, sll_public, v0    # get processor flag P in sign
    ble    v0, FLTNOPUBLIC        # notpubacess fault

# here if page is private and in super or public page
endvtophyr\&vtophylabr:
# Update cache 
    sll    t3, 18, t3
    srl    t2, 9, v0        # get  back core pgno
    or    t2, t3, v0        # get GPWSC+MBZ5bits+13bit corepgno
    sll    v0, 32, v0        # make room for section+pg
    srl    t0, 9, t3
    or    t3, v0, ra        # store new translation

vtophylabr    .assigna    \&vtophylabr + 1
.endm

vtophylabw    .assigna    0
.macro    vtophy_w
# Virtual to physical address with reference type of WRITE
#* Inputs:    t0 = 23bit virtual
#*        t1 = 5/9 bit section number
#* Outputs:    a0 = phy address (axp) may point to a reg or in KL memory
#* s0==DCODE, s1==membase, s2==PC, s3==flags, s5==effective register base
#* this is different from both _r and _rx we have to check pages are
#* writeable

    blt    s3, VMw\&vtophylabw # is VM enabled?
    s8addq    t0, s1, a0    # get phy axp address membase s1
    s8addq    t0, s5, v0
    subq    t0,017, t6    # is the address inside the accumlators
    cmovlt    t6, v0, a0    # move reg address to a0 instead
    br    endvtophyw\&vtophylabw
checkcachew\&vtophylabw:
# make key of sect+page
    srl    t0, 9, v0        # get section + page
    subl    v0, ra, v0        # subtract from lower 32bits of ra
    bne    v0, cachemissw\&vtophylabw    # not matched cache miss
# here then we have a valid cache hit
    extwl    ra, 4, t2        # get core pg no into t2
    srl    ra, 32+15+5, t3        # get GPWSC into t3
    br    cstpgupdw\&vtophylabw

VMw\&vtophylabw:
    bne    ra, checkcachew\&vtophylabw
cachemissw\&vtophylabw:
    ldq    t5, spt-MM(s1)!lituse_base!3    # get spt
    bic    t5,t10,t5        # clear non 36 bit part

    sll    s3, sll_user, t2    # move user flag to sign  v0
    sll    s3, 28,  t4        # move PCU flag to sign  t4
    srl    s3, 2, v0        # get PXCT flag in v0
    cmovlt    v0,t4, t2        # if PXCT then move PCU to t2

    extwl    s3, 0, t4        # get EBR  in t4
    extwl    s3, 2, t6        # get UBR  in t6
    cmovgt    t2, t6, t4        # if user ==1 then UBR
    sll    t4, 9 , t4        # Base reg is a page number shift left so its a
PDP10 word address 
# now t4 is process base register either UBR or EBR
    mov    USECT, v0        # USECT == ESECT ==540
    addq    v0, t1, v0        # SECTNO+0540
    addq    v0, t4, v0        # still PDP10 address add SECTNO+540+BASE
    mov    015, t3            # set flags PWC = 1
    s8addq    v0, s1, v0        # convert to axp address using memory base
s1 
    ldq    t2, (v0)        # fetch page table pointer
    bic    t2, t10, t2        # clear non  36bit part

fetchptrw\&vtophylabw:
# t2 = ar = fetched page table pointer
    srl    t2, 29, v0        # get page flags P,W,C in lower 4 bits of v0
...|P|W|0|C| 
    and    t3, v0, t3        # and the flags with current PWC
    srl    t2, 36-3, v0        # get type flags in v0
    lda    v0, -1(v0)        # dec typeflags
    beq    v0, pgtblimedw\&vtophylabw    # type=001 Immediate
    lda    v0, -1(v0)        # dec typeflags
    beq    v0, pgtblsharw\&vtophylabw    # type=010 Shared
    lda    v0, -1(v0)        # dec typeflags
    bne    v0, FLTNOACC        # if not zero it was not 011 shared must have
been either 000 or 1xx so flt noacc
pgtblindirw\&vtophylabw:
# type=011 Indirect
    srl    t2, 18, t1        # get new section number
    mov    511, v0            # 9 bit and mask
    and    t1, v0, t1        # get lower 9 bits as pageno  number index

    bic    t2, t11, v0        # get 18 bit SPTX
    addq    t5, v0, v0        # SPT+SPTX
    s8addq    v0, s1, v0        # convert to AXP address
    ldq    t2, (v0)        # fetch storage address
    bic    t2, t10, t2        # clear non 36 bit

    srl    t2, 18, v0        # get 6 bits that define in core
    and    v0, 077, v0        # clear off anything but 6 bit core flag
    bne    v0, FLTNOTCORE        # branch if not in core

    bic    t2, t11, v0        # get 18 bits if storage address
5bitsMBZ+13bit corepgno
    sll    v0, 9, v0        # convert page no to PDP-10 phy address
    addq    t1, v0, v0        # add 9 bits of section index
    s8addq    v0, s1, v0        # convert to axp address
    ldq    t2,(v0)            # fetch new page table pointer
    bic    t2, t10, t2        # clear non 36 bit part
# check for interupts
    ldq    at, interupt10-MM(s1)!lituse_base!3
    beq    at,fetchptrw\&vtophylabw    # branch backward and do it all again
    br    gointerupt         # Interupt DISP request interupt != 0
    
pgtblsharw\&vtophylabw:
# type=010 Shared 
    bic    t2,t11, v0        # get SPTX 18 bits
    addq    t5, v0, v0        # SPT+SPTX

    s8addq    v0, s1, v0        # get axp address
    ldq    t2, (v0)        # fetch new pointer
    bic    t2, t10, t2        # clear non 36 bit part

pgtblimedw\&vtophylabw:
# type=001 now have a storage address of page table in t2
    srl    t2, 18, v0
    and    v0, 077, v0
    bne    v0,FLTNOTCORE

    bic    t2, t11, t2        # get 18 bits if storage address
5bitsMBZ+13bit corepgno
    sll    t2, 9 , v0        # convert core page no to address
    s8addq    v0, s1, v0        # convert to axp address of page table
# now do CST things for page table t2 == corepagenno of Page Table
    
    ldq    v0, cst-MM(s1)!lituse_base!3    # get CST table pointer
    bic    v0, t10, v0        # clear non 36 bit part
    addq    v0, t2, t6        # get CST+corepageno
    s8addq    t6, s1, t6        # get axp address of CST entry
    ldq    v0, (t6)        # fetch CST entry
    bic    v0, t10, v0        # clear non 36 bit part

    sll    v0, 30, at        # get top 6 bits of CST entry
    beq    at, FLTNOACC        # 0 is no access
    ldq    at, cstmask-MM(s1)!lituse_base!3    # get cst mask
    bic    at, t10, at        # get 36 bit part of mask
    and    v0, at, v0        # CSTentry and CSTmask
    
    ldq    at, cstdata-MM(s1)!lituse_base!3    # get cst data
    bic    at, t10, at        # get 36 bit part of cstdata
    or    v0, at, v0        # CSTentry or CSTdata
    stq    v0, (t6)        # store CSTentry back

    mov    511, v0            # 9 bit and mask
    srl    t0, 9, at        # gt actual page_no  first time using actual
page no from VA index into pgtbl
    and    at, v0, t1        # get 9 bits only
# t2 was cleared as 18 bits b4
    sll    t2, 9, v0        # we did this shift before the cst update - t2
is a 13bit corepgno of a pgtable
    
    or    v0, t1, v0        # add page_no to core page address of page table
index for page pointer
    s8addq    v0, s1, v0        # get axp address
    ldq    t2, (v0)        # fetch page pointer
    srl    t2, 29, v0        # get flags PWC in lower bits
    and    t3, v0, t3        # add flags to current PWC
    srl    t2, 36-3, v0        # get type in v0
    lda    v0, -1(v0)        # dec
    beq    v0, pgimedw\&vtophylabw    # type=001 Immediate
    lda    v0, -1(v0)        # dec typeflags
    beq    v0, pgsharw\&vtophylabw    # type=010 Shared
    lda    v0, -1(v0)        # dec typeflags
    beq    v0, pgtblindirw\&vtophylabw    #
    br     FLTNOACC        # if not zero it was not 011 shared must have
been either 000 or 1xx so flt noacc
pgsharw\&vtophylabw:
    bic    t2, t11, v0        # get SPTX
    addq    t5, 0, v0         # SPT + SPTX
    s8addq    v0, s1, v0        # convert to axp addr
    ldq    t2, (v0)        # fetch pg ptr
    bic    t2, t10, t2        # 36bits only
pgimedw\&vtophylabw:
    sll    t2, 18, v0        # get 6 bit that define core
    and    v0, 077, v0        # 6 bits only
    bne    v0, FLTNOTCORE
    bic    t2, t11, t2        # get 18 bit storage address phy core pg
cstpgupdw\&vtophylabw:
# now have real user pgno of core in t2 do CST update
    ldq    v0, cst-MM(s1)!lituse_base!3    # get CST pointer
    bic    v0, t10, v0        # 36bits only
    addq    v0, t2, t6        # CST+corepgno
    s8addq    t6, s1, t6        # get axp address of CSTentry
    ldq    v0, (t6)        # fetch CSTentry
    bic    v0, t10, v0        # 36bits only
    sll    v0, 30, at        # get top 6 bits of CSTentry
    beq    at, FLTNOACC        # 0=noaccess
    ldq    at, cstmask-MM(s1)!lituse_base!3    # get CSTmask
    bic    at, t10, at        # 36bits only
    and    v0, at, v0        # CSTentry and CSTmask

    sll    t2, 9 , t2        # cvt core pg no to PDP-10 address
    mov    510, v0
    and    t0, v0, at        # get 9 bit address of word in page
    addq    t2, at, v0        # v0 = PDP-10 address of word in phy memory
    s8addq    v0, s1, a0        # a0 = AXP address of word
# t3 = G|P|W|S|C  now test public access of page
    srl    t3, 3, v0        # get P flag in low bit
    blbs    v0, endvtophyw\&vtophylabw    # branch page is public
# ok its a private page aka concealed page are we in supervisor mode
    sll    s3, sll_public, v0    # get processor flag P in sign
    ble    v0, FLTNOPUBLIC        # notpubacess fault
# test writable this is a write reference can it be completed?
    srl    t3, 2, v0        # get W flag in low bit
    blbs    v0, FLTNOWRITE    # branch page is nowriteable

# here if page is private and in super or public page
endvtophyw\&vtophylabw:
# this is a write need to do writeable page checks
# allow the CST update even if public is failed later
    ldq    at, cstdata-MM(s1)!lituse_base!3    # get CSTdata
    bic    at, t10, at        # 36bits only
    or    v0, at, v0        # CSTentry or CSTdata
    or    v0, 1, v0        # set bit35 pg written
    stq    v0, (t6)        # store CSTentry back
# Update cache 
    sll    t3, 18, t3
    srl    t2, 9, v0        # get  back core pgno
    or    t2, t3, v0        # get GPWSC+MBZ5bits+13bit corepgno
    sll    v0, 32, v0        # make room for section+pg
    srl    t0, 9, t3
    or    t3, v0, ra        # store new translation

vtophylabw    .assigna    \&vtophylabw + 1
.endm
#***************************************************************
.macro    calc_e
# Calc Effective address
#* Inputs:
#* Outputs: 
.endm

.macro fetch
    br    fetch
.endm

    .text
    .align 4

    .globl  cpu00
    .ent     cpu00
cpu00:
    ldah    gp, (pv)!gpdisp!1
    lda     gp, (gp)!gpdisp!1
    lda    sp, -128(sp)
    .frame  sp, 128, ra, 0
    stq    ra, 0(sp)
    stq    s0, 8(sp)
    stq    s1, 16(sp)
    stq    s2, 24(sp)
    stq    s3, 32(sp)
    stq    s4, 40(sp)
    stq    s5, 48(sp)
    stq    $at, 56(sp)
    stt    $f2, 64(sp)
    stt    $f3, 72(sp)
    stt    $f4, 80(sp)
    stt    $f5, 88(sp)
    stt    $f6, 96(sp)
    stt    $f7, 104(sp)
    stt    $f8, 112(sp)
    stt    $f9, 120(sp)
    trapb
    .mask    0x14007e00, 0
    .fmask    0x000007fc, 0
    .prologue 1
    #
    # Init base registers
    #
    ldq    s0, DCODE(gp)!literal!2        # addr jump tbl
    ldq    s1, emboxreg(gp)!literal!3
    lda    s1, MM(s1)!lituse_base!3    # pdp10 mem 2^22
    #
    # Init constants
    #
    ldah    t11, -4(zero)    # t11 == 01777777777777777000000 18 bit bic
mask
    sll    t11, 18, t10    # t10 == 01777777777000000000000 36 bit bic mask

reset:    
    stq    zero, PC-MM(s1)!lituse_base!3        # Clear PC
    stq    zero, flags-MM(s1)!lituse_base!3    # Clear flags
    mov    zero, ra            # clear page cache register
loadcab:
    ldq    s2, PC-MM(s1)!lituse_base!3        # load PC
    ldq    s3, flags-MM(s1)!lituse_base!3        # load flags

    extwl    s3, 5, v0    # get PAB|CAB from flags reg s3
    and    v0,07, v0    # get CAB current accumulator block idx
    mulq    v0, 16*8, v0 # cal index into reg file 16 reg by 8 byte per reg

    lda    t1,r0_0-MM(s1)!lituse_base!3    # regfile base addr
    addq    v0,t1,s4        # base+16*8*idx :axp address of accblk
    mov    s4, s5            # set default register base

fetch:
startfetch:
# inc PC first so that any gointerupt from here or during vtophy known
# that dec PC is always the next valid step
    inc_PC
    ldq    at, interupt10-MM(s1)!lituse_base!3
    bne    at,gointerupt        #  Interupt DISP request interupt != 0

xctPC:
                    # put sect+incPC back to PC
    mov    s2, t0            # put full virt addr into t0
    srl    t1, 18, t1        # convert section mask to section number
# now t0=5sectno+9bitpg+9bitwordaddr bit virtual  t1=5 bit sect no

    # now convert pc in s2 t1=sectbits t0=VA  into a0
     vtophy_rx
                    # FETCH opcode from PC
    ldq    a1,(a0)            # a1 == fetch opcode
    blt    a1,addrbrk        # branch if addr break
    bic    a1, t10, a1        # clear off non 36 bit part
noaddrbrk:
    srl    a1,27,a2        # a2 == 9 bit opcode
                   
    srl    a1,23,a3
    and    a3,0xf,a3        # a3 == AC register
                   
    srl    a1,18,a4
    and    a4,0xf,a4        # a4 == X register
                   
    bic    a1,t11,a5        # a5 == Y

# calc effective address part
    calc_e
# returns s6, a0 
# Now the following is setup
#    s0 = PC
#    s6 = e
#    t1 = sect(e)
#    t3 = G|P|W|S|C
#    a0 = phyaddr(e)          This may either be a register or pdp10core
#                in eithercase in is not a base
#    s5 = effective regbase
#
    
    s8addq    a2,s0,v0        # lookup op func add in DCODE
dispatch:
    ldq    v0,(v0) 
    jmp    (v0)    

gointerupt:
    lda    t6,DCODE-inthdl(s0)!lituse_base!2  #  base for hdl table
    s8addq    at, pv, v0         # get address of handler
    ldq    v0,(v0) 
    jmp    (v0)    

addrbrk:
# can use a2 as a temp here since branch back to noaddrbrk is before its
loaded 
    srl    a1,1,a2            # get bit for addr break exec type
    bge    a2, noaddrbrk        # branch if ist not a exec break
    bge    a2, noaddrbrk        # branch is VM is not enabled
    sll    s3,21,a2        # get flags Addr Fail Inhibit
    blt    a2, noaddrbrk        # branch if Addr Fail Inhibit set

# Note: Address break is only really valid if VM is enabled
# since this mechanism is under our control finding an address break bit set
# we can assume VM is enable
# also KL10 only has one address break our implementation could support
# many and we could enable many using console functions for debug purposes
#
# now handle address break on execute
# address break is basically a page fail
#
# Continue using a2 and now a3, a4 as temp's thought the address break they
will
# not be loaded now till next fetch

    # work out a page fail word
    sll    s3, 18, v0        # get User/Exec mode
    and    v0, 1,v0
    sll    v0, 5, v0        # make room for failure type
    or    v0, 0123, v0        # set flags to Address failure
    sll    v0, 8, v0        # make room for virtual address
    or    v0, t0, v0        # add virtual address to word
# reg UBR+500 base 
    extwl    s3, 2, a2        # get UBR
    sll    a2,  9, a2        # calc PDP phy address
    addq    a2, s1, a2        # calc axp base address of UPT
    mov    0500, a3
    s8addq    a3,a2,a2        # now have axp addres of page fail

# save page flag word @UPT+500
    stq    v0, (a2)        # 500 save page flag word
    lda    a2, 1(a2)        # inc pointer

# save Flag-PC double word @UPT+501, @UPT+502
    extwl    s3, 7, a3        # get PDP10 flag
    sll    a3, 23, v0        # put them in correct part of 36bit
    sll    a3, sll_user, a4    # get User flag in sign bit, exec = 0
    cmovgt    a4, zero, a4        # clear currect section if in User
    srl    a4, 18, a4        # get in lower 5 bits
    or    a4, a4, v0        # add PC section 2 Flag word
    stq    v0 , (a2)        # save flag word
    lda    a2, 1(a2)        # inc pointer

    stq    s2, (a2)        # save virtual PC
    lda    a2, 1(a2)        # inc pointer
# load new PC from @UPT+503 and clear User and branch back to start fetch
    bic    a3, msk_user, v0    # clear User
    inswl    v0, 7 , s3        # put flags back
    ldq    s2, (a2)        # fetch new PC from 503
    bic    s2, t10, s2        # clear off non 36 bit part
    br    startfetch        # do it all over

FLTNOPUBLIC:
FLTNOTCORE:
FLTNOACC:
FLTNOWRITE:
    br    fetch
    
exit_cpu:    # this should never happen but its here if we need it
    ldq    ra, 0(sp)
    ldq    s0, 8(sp)
    ldq    s1, 16(sp)
    ldq    s2, 24(sp)
    ldq    s3, 32(sp)
    ldq    s4, 40(sp)
    ldq    s5, 48(sp)
    ldq    $at, 56(sp)
    ldt    $f2, 64(sp)
    ldt    $f3, 72(sp)
    ldt    $f4, 80(sp)
    ldt    $f5, 88(sp)
    ldt    $f6, 96(sp)
    ldt    $f7, 104(sp)
    ldt    $f8, 112(sp)
    ldt    $f9, 120(sp)
    lda    sp, 128(sp)
    trapb
    ret    $31,($26),1            # end proc and return
#===Normal ops========
E_LUU0:            # Local Unimplemented User Operations
            #    op001 LUUO01
            #    op002 LUUO02
            #    op003 LUUO03
            #    op004 LUUO04
            #    op005 LUUO05
            #    op006 LUUO06
            #    op007 LUUO07
            #    op010 LUUO10
            #    op011 LUUO11
            #    op012 LUUO12
            #    op013 LUUO13
            #    op014 LUUO14
            #    op015 LUUO15
            #    op016 LUUO16
            #    op017 LUUO17
            #    op020 LUUO20
            #    op021 LUUO21
            #    op022 LUUO22
            #    op023 LUUO23
            #    op024 LUUO24
            #    op025 LUUO25
            #    op026 LUUO26
            #    op027 LUUO27
            #    op030 LUUO30
            #    op031 LUUO31
            #    op032 LUUO32
            #    op033 LUUO33
            #    op034 LUUO34
            #    op035 LUUO35
            #    op036 LUUO36
            #    op037 LUUO37
    fetch
E_MUU0:            # Monitor Unimplemented User Operations
            #    op040 CALL
            #    op041 INITI
            #    op042 MUUO42
            #    op043 MUUO43
            #    op044 MUUO44
            #    op045 MUUO45
            #    op046 MUUO46
            #    op047 CALLI
            #    op050 OPEN
            #    op051 TTCALL
            #    op052 MUUO52
            #    op053 MUUO53
            #    op054 MUUO54
            #    op055 RENAME
            #    op056 IN
            #    op057 OUT
            #    op060 SETSTS
            #    op061 STATO
            #    op062 STATUS
            #    op063 GETSTS
            #    op064 INBUF
            #    op065 OUTBUF
            #    op066 INPUT
            #    op067 OUTPUT
            #    op070 CLOSE
            #    op071 RELEAS
            #    op072 MTAPE
            #    op073 UGETF
            #    op074 USETI
            #    op075 USETO
            #    op076 LOOKUP
            #    op077 ENTER
    fetch
E_UJEN:           #    op100 UJEN
    vtophy_r
    fetch
E_OP101:          #    op101 OP101
    vtophy_w
    fetch
E_GFAD:           #    op102 GFAD
    fetch
E_GFSB:           #    op103 GFSB
    fetch
E_JSYS:           #    op104 JSYS
    fetch
E_ADJSP:          #    op105 ADJSP
    fetch
E_GFMP:           #    op106 GFMP
    fetch
E_GFDV:           #    op107 GFDV
    fetch
E_DFAD:           #    op110 DFAD
    fetch
E_DFSB:           #    op111 DFSB
    fetch
E_DFMP:           #    op112 DFMP
    fetch
E_DFDV:           #    op113 DFDV
    fetch
E_DADD:           #    op114 DADD
    fetch
E_DSUB:           #    op115 DSUB
    fetch
E_DMUL:           #    op116 DMUL
    fetch
E_DDIV:           #    op117 DDIV
    fetch
E_DMOVE:          #    op120 DMOVE
    fetch
E_DMOVN:          #    op121 DMOVN
    fetch
E_FIX:            #    op122 FIX
    fetch
E_EXTEND:         #    op123 EXTEND
     ldq    a1,(a0)            # a1 == fetch opcode from (e)
    bic    a1, t10, a1        # clear off non 36 bit part

    srl    a1,27,a2        # a2 == 9 bit opcode
    addq    a2,512,a2        # index opcode into extend
                   
    srl    a1,23,a3
    and    a3,0xf,a3        # a3 == AC register
                   
    srl    a1,18,a4
    and    a4,0xf,a4        # a4 == X register
                   
    bic    a1,t11,a5        # a5 == Y

    calc_e
    # returns s6, a0
    
    s8addq    a2,s0,v0        # lookup op func add in DCODE
    ldq    v0,(v0) 
    jmp    (v0)    

    fetch

E_DMOVEM:         #    op124 DMOVEM
    fetch
E_DMOVNM:         #    op125 DMOVNM
    fetch
E_FIXR:           #    op126 FIXR
    fetch
E_FLTR:           #    op127 FLTR
    fetch
E_UFA:            #    op130 UFA
    fetch
E_DFN:            #    op131 DFN
    fetch
E_FSC:            #    op132 FSC
    fetch
E_IBP:            #    op133 IBP
    fetch
E_ILDB:           #    op134 ILDB
    fetch
E_LDB:            #    op135 LDB
    fetch
E_IDPB:           #    op136 IDPB
    fetch
E_DPB:            #    op137 DPB
    fetch
E_FAD:            #    op140 FAD
    fetch
E_FADL:           #    op141 FADL
    fetch
E_FADM:           #    op142 FADM
    fetch
E_FADB:           #    op143 FADB
    fetch
E_FADR:           #    op144 FADR
    fetch
E_FADRL:          #    op145 FADRL
    fetch
E_FADRM:          #    op146 FADRM
    fetch
E_FADRB:          #    op147 FADRB
    fetch
E_FSB:            #    op150 FSB
    fetch
E_FSBL:           #    op151 FSBL
    fetch
E_FSBM:           #    op152 FSBM
    fetch
E_FSBB:           #    op153 FSBB
    fetch
E_FSBR:           #    op154 FSBR
    fetch
E_FSBRL:          #    op155 FSBRL
    fetch
E_FSBRM:          #    op156 FSBRM
    fetch
E_FSBRB:          #    op157 FSBRB
    fetch
E_FMP:            #    op160 FMP
    fetch
E_FMPL:           #    op161 FMPL
    fetch
E_FMPM:           #    op162 FMPM
    fetch
E_FMPB:           #    op163 FMPB
    fetch
E_FMPR:           #    op164 FMPR
    fetch
E_FMPRL:          #    op165 FMPRL
    fetch
E_FMPRM:          #    op166 FMPRM
    fetch
E_FMPRB:          #    op167 FMPRB
    fetch
E_FDV:            #    op170 FDV
    fetch
E_FDVL:           #    op171 FDVL
    fetch
E_FDVM:           #    op172 FDVM
    fetch
E_FDVB:           #    op173 FDVB
    fetch
E_FDVR:           #    op174 FDVR
    fetch
E_FDVRL:          #    op175 FDVRL
    fetch
E_FDVRM:          #    op176 FDVRM
    fetch
E_FDVRB:          #    op177 FDVRB
    fetch
E_MOVE:           #    op200 MOVE
    fetch
E_MOVEI:          #    op201 MOVEI
    fetch
E_MOVEM:          #    op202 MOVEM
    fetch
E_MOVES:          #    op203 MOVES
    fetch
E_MOVS:           #    op204 MOVS
    fetch
E_MOVSI:          #    op205 MOVSI
    fetch
E_MOVSM:          #    op206 MOVSM
    fetch
E_MOVSS:          #    op207 MOVSS
    fetch
E_MOVN:           #    op210 MOVN
    fetch
E_MOVNI:          #    op211 MOVNI
    fetch
E_MOVNM:          #    op212 MOVNM
    fetch
E_MOVNS:          #    op213 MOVNS
    fetch
E_MOVM:           #    op214 MOVM
    fetch
E_MOVMI:          #    op215 MOVMI
    fetch
E_MOVMM:          #    op216 MOVMM
    fetch
E_MOVMS:          #    op217 MOVMS
    fetch
E_IMUL:           #    op220 IMUL
    fetch
E_IMULI:          #    op221 IMULI
    fetch
E_IMULM:          #    op222 IMULM
    fetch
E_IMULB:          #    op223 IMULB
    fetch
E_MUL:            #    op224 MUL
    fetch
E_MULI:           #    op225 MULI
    fetch
E_MULM:           #    op226 MULM
    fetch
E_MULB:           #    op227 MULB
    fetch
E_IDIV:           #    op230 IDIV
    fetch
E_IDIVI:          #    op231 IDIVI
    fetch
E_IDIVM:          #    op232 IDIVM
    fetch
E_IDIVB:          #    op233 IDIVB
    fetch
E_DIV:            #    op234 DIV
    fetch
E_DIVI:           #    op235 DIVI
    fetch
E_DIVM:           #    op236 DIVM
    fetch
E_DIVB:           #    op237 DIVB
    fetch
E_ASH:            #    op240 ASH
    fetch
E_ROT:            #    op241 ROT
    fetch
E_LSH:            #    op242 LSH
    fetch
E_JFFO:           #    op243 JFFO
    fetch
E_ASHC:           #    op244 ASHC
    fetch
E_ROTC:           #    op245 ROTC
    fetch
E_LSHC:           #    op246 LSHC
    fetch
E_op247:          #    op247 op247
    fetch
E_EXCH:           #    op250 EXCH
    fetch
E_BLT:            #    op251 BLT
    fetch
E_AOBJP:          #    op252 AOBJP
    fetch
E_AOBJN:          #    op253 AOBJN
    fetch
E_JRST:           #    op254 JRST
    fetch
E_JFCL:           #    op255 JFCL
    fetch
E_XCT:            #    op256 XCT
    fetch
E_MAP:            #    op257 MAP
    fetch
E_PUSHJ:          #    op260 PUSHJ
    fetch
E_PUSH:           #    op261 PUSH
    fetch
E_POP:            #    op262 POP
    fetch
E_POPJ:           #    op263 POPJ
    fetch
E_JSR:            #    op264 JSR
    fetch
E_JSP:            #    op265 JSP
    fetch
E_JSA:            #    op266 JSA
    fetch
E_JRA:            #    op267 JRA
    fetch
E_ADD:            #    op270 ADD
    fetch
E_ADDI:           #    op271 ADDI
    fetch
E_ADDM:           #    op272 ADDM
    fetch
E_ADDB:           #    op273 ADDB
    fetch
E_SUB:            #    op274 SUB
    fetch
E_SUBI:           #    op275 SUBI
    fetch
E_SUBM:           #    op276 SUBM
    fetch
E_SUBB:           #    op277 SUBB
    fetch
E_CAI:            #    op300 CAI
    fetch
E_CAIL:           #    op301 CAIL
    fetch
E_CAIE:           #    op302 CAIE
    fetch
E_CAILE:          #    op303 CAILE
    fetch
E_CAIA:           #    op304 CAIA
    fetch
E_CAIGE:          #    op305 CAIGE
    fetch
E_CAIN:           #    op306 CAIN
    fetch
E_CAIG:           #    op307 CAIG
    fetch
E_CAM:            #    op310 CAM
    fetch
E_CAML:           #    op311 CAML
    fetch
E_CAME:           #    op312 CAME
    fetch
E_CAMLE:          #    op313 CAMLE
    fetch
E_CAMA:           #    op314 CAMA
    fetch
E_CAMGE:          #    op315 CAMGE
    fetch
E_CAMN:           #    op316 CAMN
    fetch
E_CAMG:           #    op317 CAMG
    fetch
E_JUMP:           #    op320 JUMP
    fetch
E_JUMPL:          #    op321 JUMPL
    fetch
E_JUMPE:          #    op322 JUMPE
    fetch
E_JUMPLE:         #    op323 JUMPLE
    fetch
E_JUMPA:          #    op324 JUMPA
    fetch
E_JUMPGE:         #    op325 JUMPGE
    fetch
E_JUMPN:          #    op326 JUMPN
    fetch
E_JUMPG:          #    op327 JUMPG
    fetch
E_SKIP:           #    op330 SKIP
    fetch
E_SKIPL:          #    op331 SKIPL
    fetch
E_SKIPE:          #    op332 SKIPE
    fetch
E_SKIPLE:         #    op333 SKIPLE
    fetch
E_SKIPA:          #    op334 SKIPA
    fetch
E_SKIPGE:         #    op335 SKIPGE
    fetch
E_SKIPN:          #    op336 SKIPN
    fetch
E_SKIPG:          #    op337 SKIPG
    fetch
E_AOJ:            #    op340 AOJ
    fetch
E_AOJL:           #    op341 AOJL
    fetch
E_AOJE:           #    op342 AOJE
    fetch
E_AOJLE:          #    op343 AOJLE
    fetch
E_AOJA:           #    op344 AOJA
    fetch
E_AOJGE:          #    op345 AOJGE
    fetch
E_AOJN:           #    op346 AOJN
    fetch
E_AOJG:           #    op347 AOJG
    fetch
E_AOS:            #    op350 AOS
    fetch
E_AOSL:           #    op351 AOSL
    fetch
E_AOSE:           #    op352 AOSE
    fetch
E_AOSLE:          #    op353 AOSLE
    fetch
E_AOSA:           #    op354 AOSA
    fetch
E_AOSGE:          #    op355 AOSGE
    fetch
E_AOSN:           #    op356 AOSN
    fetch
E_AOSG:           #    op357 AOSG
    fetch
E_SOJ:            #    op360 SOJ
    fetch
E_SOJL:           #    op361 SOJL
    fetch
E_SOJE:           #    op362 SOJE
    fetch
E_SOJLE:          #    op363 SOJLE
    fetch
E_SOJA:           #    op364 SOJA
    fetch
E_SOJGE:          #    op365 SOJGE
    fetch
E_SOJN:           #    op366 SOJN
    fetch
E_SOJG:           #    op367 SOJG
    fetch
E_SOS:            #    op370 SOS
    fetch
E_SOSL:           #    op371 SOSL
    fetch
E_SOSE:           #    op372 SOSE
    fetch
E_SOSLE:          #    op373 SOSLE
    fetch
E_SOSA:           #    op374 SOSA
    fetch
E_SOSGE:          #    op375 SOSGE
    fetch
E_SOSN:           #    op376 SOSN
    fetch
E_SOSG:           #    op377 SOSG
    fetch
E_SETZ:           #    op400 SETZ
    fetch
E_SETZI:          #    op401 SETZI
    fetch
E_SETZM:          #    op402 SETZM
    fetch
E_SETZB:          #    op403 SETZB
    fetch
E_AND:            #    op404 AND
    fetch
E_ANDI:           #    op405 ANDI
    fetch
E_ANDM:           #    op406 ANDM
    fetch
E_ANDB:           #    op407 ANDB
    fetch
E_ANDCA:          #    op410 ANDCA
    fetch
E_ANDCAI:         #    op411 ANDCAI
    fetch
E_ANDCAM:         #    op412 ANDCAM
    fetch
E_ANDCAB:         #    op413 ANDCAB
    fetch
E_SETM:           #    op414 SETM
    fetch
E_XMOVEI:         #    op415 XMOVEI
    fetch
E_SETMM:          #    op416 SETMM
    fetch
E_SETMB:          #    op417 SETMB
    fetch
E_ANDCM:          #    op420 ANDCM
    fetch
E_ANDCMI:         #    op421 ANDCMI
    fetch
E_ANDCMM:         #    op422 ANDCMM
    fetch
E_ANDCMB:         #    op423 ANDCMB
    fetch
E_SETA:           #    op424 SETA
    fetch
E_SETAI:          #    op425 SETAI
    fetch
E_SETAM:          #    op426 SETAM
    fetch
E_SETAB:          #    op427 SETAB
    fetch
E_XOR:            #    op430 XOR
    fetch
E_XORI:           #    op431 XORI
    fetch
E_XORM:           #    op432 XORM
    fetch
E_XORB:           #    op433 XORB
    fetch
E_OR:             #    op434 OR
    fetch
E_ORI:            #    op435 ORI
    fetch
E_ORM:            #    op436 ORM
    fetch
E_ORB:            #    op437 ORB
    fetch
E_ANDCB:          #    op440 ANDCB
    fetch
E_ANDCBI:         #    op441 ANDCBI
    fetch
E_ANDCBM:         #    op442 ANDCBM
    fetch
E_ANDCBB:         #    op443 ANDCBB
    fetch
E_EQV:            #    op444 EQV
    fetch
E_EQVI:           #    op445 EQVI
    fetch
E_EQVM:           #    op446 EQVM
    fetch
E_EQVB:           #    op447 EQVB
    fetch
E_SETCA:          #    op450 SETCA
    fetch
E_SETCAI:         #    op451 SETCAI
    fetch
E_SETCAM:         #    op452 SETCAM
    fetch
E_SETCAB:         #    op453 SETCAB
    fetch
E_ORCA:           #    op454 ORCA
    fetch
E_ORCAI:          #    op455 ORCAI
    fetch
E_ORCAM:          #    op456 ORCAM
    fetch
E_ORCAB:          #    op457 ORCAB
    fetch
E_SETCM:          #    op460 SETCM
    fetch
E_SETCMI:         #    op461 SETCMI
    fetch
E_SETCMM:         #    op462 SETCMM
    fetch
E_SETCMB:         #    op463 SETCMB
    fetch
E_ORCM:           #    op464 ORCM
    fetch
E_ORCMI:          #    op465 ORCMI
    fetch
E_ORCMM:          #    op466 ORCMM
    fetch
E_ORCMB:          #    op467 ORCMB
    fetch
E_ORCB:           #    op470 ORCB
    fetch
E_ORCBI:          #    op471 ORCBI
    fetch
E_ORCBM:          #    op472 ORCBM
    fetch
E_ORCBB:          #    op473 ORCBB
    fetch
E_SETO:           #    op474 SETO
    fetch
E_SETOI:          #    op475 SETOI
    fetch
E_SETOM:          #    op476 SETOM
    fetch
E_SETOB:          #    op477 SETOB
    fetch
E_HLL:            #    op500 HLL
    fetch
E_XHLLI:          #    op501 XHLLI
    fetch
E_HLLM:           #    op502 HLLM
    fetch
E_HLLS:           #    op503 HLLS
    fetch
E_HRL:            #    op504 HRL
    fetch
E_HRLI:           #    op505 HRLI
    fetch
E_HRLM:           #    op506 HRLM
    fetch
E_HRLS:           #    op507 HRLS
    fetch
E_HLLZ:           #    op510 HLLZ
    fetch
E_HLLZI:          #    op511 HLLZI
    fetch
E_HLLZM:          #    op512 HLLZM
    fetch
E_HLLZS:          #    op513 HLLZS
    fetch
E_HRLZ:           #    op514 HRLZ
    fetch
E_HRLZI:          #    op515 HRLZI
    fetch
E_HRLZM:          #    op516 HRLZM
    fetch
E_HRLZS:          #    op517 HRLZS
    fetch
E_HLLO:           #    op520 HLLO
    fetch
E_HLLOI:          #    op521 HLLOI
    fetch
E_HLLOM:          #    op522 HLLOM
    fetch
E_HLLOS:          #    op523 HLLOS
    fetch
E_HRLO:           #    op524 HRLO
    fetch
E_HRLOI:          #    op525 HRLOI
    fetch
E_HRLOM:          #    op526 HRLOM
    fetch
E_HRLOS:          #    op527 HRLOS
    fetch
E_HLLE:           #    op530 HLLE
    fetch
E_HLLEI:          #    op531 HLLEI
    fetch
E_HLLEM:          #    op532 HLLEM
    fetch
E_HLLES:          #    op533 HLLES
    fetch
E_HRLE:           #    op534 HRLE
    fetch
E_HRLEI:          #    op535 HRLEI
    fetch
E_HRLEM:          #    op536 HRLEM
    fetch
E_HRLES:          #    op537 HRLES
    fetch
E_HRR:            #    op540 HRR
    fetch
E_HRRI:           #    op541 HRRI
    fetch
E_HRRM:           #    op542 HRRM
    fetch
E_HRRS:           #    op543 HRRS
    fetch
E_HLR:            #    op544 HLR
    fetch
E_HLRI:           #    op545 HLRI
    fetch
E_HLRM:           #    op546 HLRM
    fetch
E_HLRS:           #    op547 HLRS
    fetch
E_HRRZ:           #    op550 HRRZ
    fetch
E_HRRZI:          #    op551 HRRZI
    fetch
E_HRRZM:          #    op552 HRRZM
    fetch
E_HRRZS:          #    op553 HRRZS
    fetch
E_HLRZ:           #    op554 HLRZ
    fetch
E_HLRZI:          #    op555 HLRZI
    fetch
E_HLRZM:          #    op556 HLRZM
    fetch
E_HLRZS:          #    op557 HLRZS
    fetch
E_HRRO:           #    op560 HRRO
    fetch
E_HRROI:          #    op561 HRROI
    fetch
E_HRROM:          #    op562 HRROM
    fetch
E_HRROS:          #    op563 HRROS
    fetch
E_HLRO:           #    op564 HLRO
    fetch
E_HLROI:          #    op565 HLROI
    fetch
E_HLROM:          #    op566 HLROM
    fetch
E_HLROS:          #    op567 HLROS
    fetch
E_HRRE:           #    op570 HRRE
    fetch
E_HRREI:          #    op571 HRREI
    fetch
E_HRREM:          #    op572 HRREM
    fetch
E_HRRES:          #    op573 HRRES
    fetch
E_HLRE:           #    op574 HLRE
    fetch
E_HLREI:          #    op575 HLREI
    fetch
E_HLREM:          #    op576 HLREM
    fetch
E_HLRES:          #    op577 HLRES
    fetch
E_TRN:            #    op600 TRN
    fetch
E_TLN:            #    op601 TLN
    fetch
E_TRNE:           #    op602 TRNE
    fetch
E_TLNE:           #    op603 TLNE
    fetch
E_TRNA:           #    op604 TRNA
    fetch
E_TLNA:           #    op605 TLNA
    fetch
E_TRNN:           #    op606 TRNN
    fetch
E_TLNN:           #    op607 TLNN
    fetch
E_TDN:            #    op610 TDN
    fetch
E_TSN:            #    op611 TSN
    fetch
E_TDNE:           #    op612 TDNE
    fetch
E_TSNE:           #    op613 TSNE
    fetch
E_TDNA:           #    op614 TDNA
    fetch
E_TSNA:           #    op615 TSNA
    fetch
E_TDNN:           #    op616 TDNN
    fetch
E_TSNN:           #    op617 TSNN
    fetch
E_TRZ:            #    op620 TRZ
    fetch
E_TLZ:            #    op621 TLZ
    fetch
E_TRZE:           #    op622 TRZE
    fetch
E_TLZE:           #    op623 TLZE
    fetch
E_TRZA:           #    op624 TRZA
    fetch
E_TLZA:           #    op625 TLZA
    fetch
E_TRZN:           #    op626 TRZN
    fetch
E_TLZN:           #    op627 TLZN
    fetch
E_TDZ:            #    op630 TDZ
    fetch
E_TSZ:            #    op631 TSZ
    fetch
E_TDZE:           #    op632 TDZE
    fetch
E_TSZE:           #    op633 TSZE
    fetch
E_TDZA:           #    op634 TDZA
    fetch
E_TSZA:           #    op635 TSZA
    fetch
E_TDZN:           #    op636 TDZN
    fetch
E_TSZN:           #    op637 TSZN
    fetch
E_TRC:            #    op640 TRC
    fetch
E_TLC:            #    op641 TLC
    fetch
E_TRCE:           #    op642 TRCE
    fetch
E_TLCE:           #    op643 TLCE
    fetch
E_TRCA:           #    op644 TRCA
    fetch
E_TLCA:           #    op645 TLCA
    fetch
E_TRCN:           #    op646 TRCN
    fetch
E_TLCN:           #    op647 TLCN
    fetch
E_TDC:            #    op650 TDC
    fetch
E_TSC:            #    op651 TSC
    fetch
E_TDCE:           #    op652 TDCE
    fetch
E_TSCE:           #    op653 TSCE
    fetch
E_TDCA:           #    op654 TDCA
    fetch
E_TSCA:           #    op655 TSCA
    fetch
E_TDCN:           #    op656 TDCN
    fetch
E_TSCN:           #    op657 TSCN
    fetch
E_TRO:            #    op660 TRO
    fetch
E_TLO:            #    op661 TLO
    fetch
E_TROE:           #    op662 TROE
    fetch
E_TLOE:           #    op663 TLOE
    fetch
E_TROA:           #    op664 TROA
    fetch
E_TLOA:           #    op665 TLOA
    fetch
E_TRON:           #    op666 TRON
    fetch
E_TLON:           #    op667 TLON
    fetch
E_TDO:            #    op670 TDO
    fetch
E_TSO:            #    op671 TSO
    fetch
E_TDOE:           #    op672 TDOE
    fetch
E_TSOE:           #    op673 TSOE
    fetch
E_TDOA:           #    op674 TDOA
    fetch
E_TSOA:           #    op675 TSOA
    fetch
E_TDON:           #    op676 TDON
    fetch
E_TSON:           #    op677 TSON
    fetch
E_DEVIO:          #    IO instruction
    fetch
#===Extend ops========
E_CMPSL:          #    op001 CMPSL
    fetch
E_CMPSE:          #    op002 CMPSE
    fetch
E_CMPSLE:         #    op003 CMPSLE
    fetch
E_EDIT:           #    op004 EDIT
    fetch
E_CMPSGE:         #    op005 CMPSGE
    fetch
E_CMPSN:          #    op006 CMPSN
    fetch
E_CMPSG:          #    op007 CMPSG
    fetch
E_CVTDBO:         #    op010 CVTDBO
    fetch
E_CVTDBT:         #    op011 CVTDBT
    fetch
E_CVTBDO:         #    op012 CVTBDO
    fetch
E_CVTBDT:         #    op013 CVTBDT
    fetch
E_MOVSO:          #    op014 MOVSO
    fetch
E_MOVST:          #    op015 MOVST
    fetch
E_MOVSLJ:         #    op016 MOVSLJ
    fetch
E_MOVSRJ:         #    op017 MOVSRJ
    fetch
E_XBLT:           #    op020 XBLT
    fetch
#* Interupt service routines

I_lvl0:
    stq    zero,    interupt10-MM(s1)!lituse_base!3    # reset interupt
    fetch
I_lvl1:
    stq    zero,    interupt10-MM(s1)!lituse_base!3    # reset interupt
    fetch
I_lvl2:
    stq    zero,    interupt10-MM(s1)!lituse_base!3    # reset interupt
    fetch
I_lvl3:
    stq    zero,    interupt10-MM(s1)!lituse_base!3    # reset interupt
    fetch
I_lvl4:
    stq    zero,    interupt10-MM(s1)!lituse_base!3    # reset interupt
    fetch
I_lvl5:
    stq    zero,    interupt10-MM(s1)!lituse_base!3    # reset interupt
    fetch
I_lvl6:
    stq    zero,    interupt10-MM(s1)!lituse_base!3    # reset interupt
    fetch
I_lvl7:
    stq    zero,    interupt10-MM(s1)!lituse_base!3    # reset interupt
    fetch
I_vector:
    stq    zero,    interupt10-MM(s1)!lituse_base!3    # reset interupt
    fetch
I_savepc:
    stq    s2, flags-PC(s1)!lituse_base!3
    stq    s3, flags-MM(s1)!lituse_base!3
    stq    zero,    interupt10-MM(s1)!lituse_base!3    # reset interupt
    fetch

    .end     cpu00

kl10_a.h
    # Start of registers just before MM memory area
    .data
    .comm    emboxreg 33555480

    # Start of registers just before MM memory area
    # use var - MM offset from base reg pointing to MM
    # load base as emboxreg+MM
    #
.struct    0
emboxstart: # indexed by s4 and s5
        # s5 is axp base for effective reg base and is the one the
instructions reference
        #          when s4 != s5 then we are doing some PXCT stuff
        # s4 is axp base for CAB
        # PAB or CAB 3 bits  (PAB*16)+reg# + r0_0-MM(S1)
        # or (CAB*16)+reg# + r0_0-MM(s1)

r0_0:    .quad    0
r0_1:    .quad    0
r0_2:    .quad    0
r0_3:    .quad    0
r0_4:    .quad    0
r0_5:    .quad    0
r0_6:    .quad    0
r0_7:    .quad    0
r0_8:    .quad    0
r0_9:    .quad    0
r0_10:    .quad    0
r0_11:    .quad    0
r0_12:    .quad    0
r0_13:    .quad    0
r0_14:    .quad    0
r0_15:    .quad    0


r1_0:    .quad    0
r1_1:    .quad    0
r1_2:    .quad    0
r1_3:    .quad    0
r1_4:    .quad    0
r1_5:    .quad    0
r1_6:    .quad    0
r1_7:    .quad    0
r1_8:    .quad    0
r1_9:    .quad    0
r1_10:    .quad    0
r1_11:    .quad    0
r1_12:    .quad    0
r1_13:    .quad    0
r1_14:    .quad    0
r1_15:    .quad    0

r2_0:    .quad    0
r2_1:    .quad    0
r2_2:    .quad    0
r2_3:    .quad    0
r2_4:    .quad    0
r2_5:    .quad    0
r2_6:    .quad    0
r2_7:    .quad    0
r2_8:    .quad    0
r2_9:    .quad    0
r2_10:    .quad    0
r2_11:    .quad    0
r2_12:    .quad    0
r2_13:    .quad    0
r2_14:    .quad    0
r2_15:    .quad    0

r3_0:    .quad    0
r3_1:    .quad    0
r3_2:    .quad    0
r3_3:    .quad    0
r3_4:    .quad    0
r3_5:    .quad    0
r3_6:    .quad    0
r3_7:    .quad    0
r3_8:    .quad    0
r3_9:    .quad    0
r3_10:    .quad    0
r3_11:    .quad    0
r3_12:    .quad    0
r3_13:    .quad    0
r3_14:    .quad    0
r3_15:    .quad    0

r4_0:    .quad    0
r4_1:    .quad    0
r4_2:    .quad    0
r4_3:    .quad    0
r4_4:    .quad    0
r4_5:    .quad    0
r4_6:    .quad    0
r4_7:    .quad    0
r4_8:    .quad    0
r4_9:    .quad    0
r4_10:    .quad    0
r4_11:    .quad    0
r4_12:    .quad    0
r4_13:    .quad    0
r4_14:    .quad    0
r4_15:    .quad    0

r5_0:    .quad    0
r5_1:    .quad    0
r5_2:    .quad    0
r5_3:    .quad    0
r5_4:    .quad    0
r5_5:    .quad    0
r5_6:    .quad    0
r5_7:    .quad    0
r5_8:    .quad    0
r5_9:    .quad    0
r5_10:    .quad    0
r5_11:    .quad    0
r5_12:    .quad    0
r5_13:    .quad    0
r5_14:    .quad    0
r5_15:    .quad    0

cstmask:
r6_0:    .quad    0

cstdata:
r6_1:    .quad    0

cst:
r6_2:    .quad    0

spt:
r6_3:    .quad    0

r6_4:    .quad    0
r6_5:    .quad    0
r6_6:    .quad    0
r6_7:    .quad    0
r6_8:    .quad    0
r6_9:    .quad    0
r6_10:    .quad    0
r6_11:    .quad    0
r6_12:    .quad    0
r6_13:    .quad    0
r6_14:    .quad    0
r6_15:    .quad    0

r7_0:    .quad    0
r7_1:    .quad    0
r7_2:    .quad    0
r7_3:    .quad    0
r7_4:    .quad    0
r7_5:    .quad    0
r7_6:    .quad    0
r7_7:    .quad    0
r7_8:    .quad    0
r7_9:    .quad    0
r7_10:    .quad    0
r7_11:    .quad    0
r7_12:    .quad    0
r7_13:    .quad    0
r7_14:    .quad    0
r7_15:    .quad    0

/* 
 index into reg set Current Accumulator Block    3bits
 previous context accumulator block        3bits
 Previous context Section include bit8=PCU    5bits
 Previous Context User Current sec is from PC
 if flags is neg ie sign bit set then VM is enabled
 allows a quick way to verify VM on

Reg usage:
s0 == opjumpbase DCODE
s1 == membase
s2 == PC
s3 == Flags ( see below )
s4 == regbase CAB ( referenses the reall Current Accumulators )
s5 == regbase effective (used by all instructions as register base )
ra == virtual cache register

When flags are negative VM is enabled

Logical bit usage
 Flags
|1bit |1bit|      |13bits    |1bit|1bit|5bits|3bits|3bits|13bits|13bits|
|VMena|PXCT|MBZ   |PDP-flags |PCU |PCP |PCS  |PAB  |CAB  | UBR  | EBR  |

Physical bit usage so alpha extract/insert can be used
Flags 
|1bit |1bit|8bits|16bits    |1bit|1bit|1bit|5bits|4bits|4bits|16bits|16bits|
|VMena|PXCT|MBZ  |PDP-flags |MBZ |PCU |PCP |PCS  |PAB  |CAB  | UBR  | EBR  |

VMena    Virtual Memory Enabled (sign bit)
PXCT    Previous context is in effect for addressing
MBZ    Must Be Zero
PDP-flags    PDP-10 flags
PCU    Previous Context User
PCP    Previous Context Public
PCS    Previous Context Section (PC section)
PAB    Previous Accumulator Block
CAB    Current  Accumulator Block
UBR    User Base Register
EBR    Executive Base Register

PDP-flags (16bits lower 13 bits belong to PDP10)
*/
/* Shift Left Logical so that bit is in axp sign */
sll_prevcpub    .equ    13
sll_overflow    .equ    13
sll_carry0    .equ    14
sll_carry1    .equ    15
sll_floatovr    .equ    16
sll_fpd        .equ    17
sll_user    .equ    18
sll_userio    .equ    19
sll_prevcuser    .equ    19
sll_public    .equ    20
sll_addrfinh    .equ    21
sll_trap2    .equ    22
sll_trap1    .equ    23
sll_floatund    .equ    24
sll_nodiv    .equ    25
/* Shift Right Logicals so that bit is in low bit axp */
srl_prevcpub    .equ    12
srl_overflow    .equ    12
srl_carry0    .equ    11
srl_carry1    .equ    10
srl_floatovr    .equ    9
srl_fpd        .equ    8
srl_user    .equ    7
srl_userio    .equ    6
srl_prevcuser    .equ    6
srl_public    .equ    5
srl_addrfinh    .equ    4
srl_trap2    .equ    3
srl_trap1    .equ    2
srl_floatund    .equ    1
srl_nodiv    .equ    0
srl_flags    .equ    48
/* Bit Mask for bic to clear and and to msk the flag,  13 bits wide */
msk_prevcpub    .equ    010000
msk_overflow    .equ    010000
msk_carry0    .equ    004000
msk_carry1    .equ    002000
msk_floatovr    .equ    001000
msk_fpd        .equ    000400
msk_user    .equ    000200
msk_userio    .equ    000100
msk_prevcuser    .equ    000100
msk_public    .equ    000040
msk_addrfinh    .equ    000020
msk_trap2    .equ    000010
msk_trap1    .equ    000004
msk_floatund    .equ    000002
msk_nodiv    .equ    000001

/* process table definitions */
USECT    .equ    0540
ESECT    .equ    0540

/*
+-----+------------+------+------+--------+----+----+------------+------+---
----+-----+-----+---------+------+
|3bits|Overflow    |      |      |Floating|    |    |User IO     |
|Address|     |     |Floating | No   |
|     |Prev context|Carry0|Carry1|Overflow|FPD |User|Prev
Context|Public|Failure|Trap2|Trap1|underflow|Divide|
|     |public      |      |      |        |    |    |User        |
|Inhibit|     |     |         |      |
+-----+------------+------+------+--------+----+----+------------+------+---
----+-----+-----+---------+------+
| MBZ | 1 bit      | 1bit |1bit  | 1bit   |1bit|1bit| 1bit       | 1bit |
1bit  | 1bit|1bit | 1bit    |1bit  |
+-----+------------+------+------+--------+----+----+------------+------+---
----+-----+-----+---------+------+
 ^10   ^13           ^14    ^15    ^16      ^17  ^18  ^19         ^20
^21     ^22   ^23    ^24      ^25
 ^^^^^^^
sll s3,X 
The above numbers correspond to how many bits to shift s3 left by 2 get that
PDP10
flags into the axp sign bit

*/
flags:    .quad    0        # storage locations only after console
PC:    .quad    0        # interupt requesting they be saved

usec:    .quad    0        # micro second counter
usec10:    .quad    0        # 10micro second counter

interupt10:    .quad    0    # fe will indicate interupt with nozero
interupt11:    .quad    0    # 10 will return completion status


MM:    .quad    0:4194304
    # each word lower 36bits is PDP-10 word bit 63 is address break on
    # real 10 only has one address we can support address break
    # on each and every word fetched for execution
    # this leaves 27 bits unassigned

emboxend:






