Article 6316 of alt.sys.pdp10:
Path: nntp1.ba.best.com!news1.best.com!nntp.primenet.com!nntp.gblx.net!cpk-news-hub1.bbnplanet.com!news.gtei.net!newshub2.home.com!news.home.com!news1.rdc1.md.home.com.POSTED!not-for-mail
Message-ID: <3BC3D77A.316A392@null.net>
From: "Douglas A. Gwyn" <DAGwyn@null.net>
X-Mailer: Mozilla 4.78 [en] (Windows NT 5.0; U)
X-Accept-Language: en
MIME-Version: 1.0
Newsgroups: alt.sys.pdp10,alt.sys.pdp11,vmsnet.pdp-11,comp.os.rsts
Subject: Re: Copying 9-track tapes on a Vax
References: <091020011746240349%lchretien@mac.com>
Content-Type: text/plain; charset=us-ascii
Content-Transfer-Encoding: 7bit
Lines: 318
Date: Wed, 10 Oct 2001 05:05:25 GMT
NNTP-Posting-Host: 65.1.216.129
X-Complaints-To: abuse@home.net
X-Trace: news1.rdc1.md.home.com 1002690325 65.1.216.129 (Tue, 09 Oct 2001 22:05:25 PDT)
NNTP-Posting-Date: Tue, 09 Oct 2001 22:05:25 PDT
Organization: Excite@Home - The Leader in Broadband http://home.com/faster
Xref: nntp1.ba.best.com alt.sys.pdp10:6316 alt.sys.pdp11:2624 vmsnet.pdp-11:3091 comp.os.rsts:120

If you're running UNIX on any system with a magtape drive,
you can just use one of my magtape utilities to make a SIMH-compatible
binary image disk file, which you can then transfer to a more
convenient location via binary FTP etc.

/*
	timage -- copy magnetic tape (double-buffered) to tape-image file

	derived from BRL/VLD "tcopy" (Natalie & Gwyn)

	last edit:	01/06/15	gwyn@arl.army.mil

	Usage:	timage /dev/rmt/0mbn tape_image	# for example

	First argument must be the name of a non-rewinding-on-close,
	readable-after-tape-mark (the latter is called ``BSD behavior'' by
	Sun) raw magtape device, or "-" to read from standard input (for
	special applications only).

	The tape-image file contains a sequence of variable-length records:
	each tape mark is represented by four 0-valued bytes, and end-of-tape
	is denoted by two consecutive tape marks.  Data records consist of a
	four-byte record size (in little-endian order), the data bytes, an
	additional 0-valued byte if the number of data bytes was odd, and
	another four-byte record size (to facilitate backspace operations).
	(This is the format used by Bob Supnick's SIMH computer emulators.)
	Such tape-image files can be copied to magtape by the timage utility,
	or unpacked into a set of disk files by the tunpack utility.

	Tape input is double-buffered, which typically makes a huge difference
	in throughput.

	timage itself runs only on a UNIX-based system, but the following
	GetRecord function can be used in any Standard C application to
	decode the tape-image file; GetCount is an auxiliary function that
	the application need not invoke directly:

#include	<stdio.h>

static long				// return # bytes in associated record
GetCount( from, iname )
	FILE		*from;		// input stream
	const char	*iname;		// file name in case of read error
	{
	unsigned long	nc;		// decoded # bytes in record
	static unsigned char	hdr[4];

	if ( fread( hdr, 4, 1, from ) != 1 )
		{
		fprintf( stderr, "error reading \"%s\"\n", iname );
		return -1L;		// special error indicator
		}

	nc = hdr[0] | ((unsigned long)hdr[1] << 8)
	   | ((unsigned long)hdr[2] << 16) | ((unsigned long)hdr[3] << 24);

	return (long)nc;
	}

long		// return # bytes in record; 0 => tape mark; -1 => error;
		// 2 consecutive tape marks indicates end of tape
GetRecord( from, iname, buffer )
	FILE		*from;		// input stream
	const char	*iname;		// file name in case of read error
	char		*buffer;	// receives input data record
	{
	long		nc = GetCount( from, iname );	// read count header
	char		dummy;		// receives padding byte, if any

	if ( nc <= 0L )
		return nc;		// tape mark or error

	if ( fread( buffer, nc, 1, from ) != 1 )
		{
		fprintf( stderr, "error reading \"%s\"\n", iname );
		return -1L;		// special error indicator
		}

	if ( nc % 2 != 0 && fread( &dummy, 1, 1, from ) != 1 )	// padding
		{
		fprintf( stderr, "error reading \"%s\"\n", iname );
		return -1L;		// special error indicator
		}

	if ( GetCount( from, iname ) != nc )	// read count trailer
		{
		fprintf( stderr, "inconsistent byte count in \"%s\"\n", iname );
		return -1L;		// special error indicator
		}

	return nc;
	}
*/
#ifndef	lint
static char	SCCS_id[] = "@(#)timage.c	1.5";
#endif

#include	<stdio.h>

extern void	_exit(), exit(), perror();
extern int	close(), fork(), open(), pipe(), read(), write();

#ifndef MAXSIZE
#define	MAXSIZE	(20*1024)
#endif

static char	buffer[MAXSIZE];

static void
error( msg )
	char	*msg;
	{
	perror( msg );
	exit( 1 );
	}

static void
PutCount( to, nc, oname )
	int		to;		/* output file descriptor */
	unsigned long	nc;		/* # characters in following record */
	char		*oname;		/* file name in case of write error */
	{
	static unsigned char	hdr[4];

	hdr[0] = nc & (unsigned long)0xFF;
	hdr[1] = (nc >> 8) & (unsigned long)0xFF;
	hdr[2] = (nc >> 16) & (unsigned long)0xFF;
	hdr[3] = (nc >> 24) & (unsigned long)0xFF;

	if ( write( to, (char *)hdr, 4 ) != 4 )
		error( oname );
	}

int
main( argc, argv )
	int	argc;
	char	*argv[];
	{
	static int	pfd[2][2];	/* pipe file descriptors */
	static char	eof;		/* token passed between processes */
	register int	from, to;	/* data I/O file descriptors */
	register int	nc;		/* # bytes read (may be odd) */
	register int	nx;		/* # bytes to write (will be even) */
	register long	count;		/* file block counter */
	int		bs;		/* file blocksize */
	int		pid;		/* child pid (0 in child) */

	if ( argc != 3 )
		{
		(void)fputs( "Usage: timage from-nrmt to-file\n", stderr );
		exit( 2 );
		}

	if ( (to = creat( argv[2], 0666 )) < 0 )
		error( argv[2] );

	do	{			/* for each input tape file: */
		if ( argv[1][0] == '-' && argv[1][1] == '\0' )
			from = 0;	/* stdin */
		else if ( (from = open( argv[1], 0 )) < 0 )
			error( argv[1] );

		/* For each tape file, we set up a pair of processes that pass a
		   "token" around to synchronize with each other, in order to
		   avoid race conditions as they both read and write on the same
		   file descriptors.  This permits reading of the input tape
		   concurrently with writing of the output file; this is a
		   "double buffering" scheme using standard UNIX facilities. */

		if ( pipe( pfd[0] ) != 0 || pipe( pfd[1] ) != 0 )
			error( "pipe" );

		switch( pid = fork() )
			{
		case -1:
			error( "fork" );
			/*NOTREACHED*/

		case 0:			/* child */
			if ( close( pfd[0][1] ) < 0 || close( pfd[1][0] ) < 0 )
				error( "close" );

			for ( eof = 0; ; )
				{
				/* assert( !eof ); */

				if ( write( pfd[1][1], &eof, 1 ) != 1 )
					error( "child pipe write W" );

				/* The token is in the pipe but not necessarily
				   read yet by the other process.  This is the
				   cute trick that achieves double-buffering. */

				if ( read( pfd[0][0], &eof, 1 ) != 1 )
					error( "child pipe read R" );

				if ( eof )
					break;	/* terminate child */

				if ( (nc = read( from, buffer, MAXSIZE )) < 0 )
					error( argv[1] );

				eof = nc == 0;

				if ( write( pfd[1][1], &eof, 1 ) != 1 )
					error( "child pipe write R" );

				/* The token is in the pipe but not necessarily
				   read yet by the other process.  This is the
				   cute trick that achieves double-buffering. */

				if ( read( pfd[0][0], &eof, 1 ) != 1 )
					error( "child pipe read W" );

				/* assert( !eof ); */

				PutCount( to, (unsigned long)nc, argv[2] );

				if ( nc == 0 )
					break;	/* terminate child */

				if ( (nx = nc) % 2 != 0 )
					buffer[nx++] = 0;	/* pad even */

				if ( write( to, buffer, nx ) != nx )
					error( argv[2] );

				PutCount( to, (unsigned long)nc, argv[2] );
				}

			_exit( 0 );	/* terminate child */
			/*NOTREACHED*/

		default:		/* parent */
			if ( close( pfd[0][0] ) < 0 || close( pfd[1][1] ) < 0 )
				error( "close" );

			for ( count = 0L; ; )
				{
				if ( (nc = read( from, buffer, MAXSIZE )) < 0 )
					error( argv[1] );

				if ( count == 0L )
					bs = nc;	/* use 1st blocksize */

				if ( !(eof = nc == 0) )
					++count;	/* parent read block */

				if ( write( pfd[0][1], &eof, 1 ) != 1 )
					error( "parent pipe write R" );

				/* The token is in the pipe but not necessarily
				   read yet by the other process.  This is the
				   cute trick that achieves double-buffering. */

				if ( read( pfd[1][0], &eof, 1 ) != 1 )
					error( "parent pipe read W" );

				/* assert( !eof ); */

				PutCount( to, (unsigned long)nc, argv[2] );

				if ( nc == 0 )
					break;	/* wait for child */

				if ( (nx = nc) % 2 != 0 )
					buffer[nx++] = 0;	/* pad even */

				if ( write( to, buffer, nx ) != nx )
					error( argv[2] );

				PutCount( to, (unsigned long)nc, argv[2] );

				/* assert( !eof ); */

				if ( write( pfd[0][1], &eof, 1 ) != 1 )
					error( "parent pipe write W" );

				/* The token is in the pipe but not necessarily
				   read yet by the other process.  This is the
				   cute trick that achieves double-buffering. */

				if ( read( pfd[1][0], &eof, 1 ) != 1 )
					error( "parent pipe read R" );

				if ( eof )
					break;	/* wait for child */

				++count;	/* child read block */
				}

			if ( wait( (int *)0 ) != pid )	/* looping not needed */
				error( "wait" );

			if ( close( pfd[0][1] ) < 0 || close( pfd[1][0] ) < 0 )
				error( "close" );
			}

		if ( argv[1][0] != '-' || argv[1][1] != '\0' )
			if ( close( from ) != 0 )
				error( argv[1] );

		if ( count == 0L )
			(void)fputs( "EOM\n", stderr );
		else
			(void)fprintf( stderr, "%ld records, blocksize %d\n",
				       count, bs
				     );
		}
	while ( count > 0L );

	PutCount( to, (unsigned long)0, argv[2] );

	if ( close( to ) != 0 )
		error( argv[2] );

	return 0;
	}


