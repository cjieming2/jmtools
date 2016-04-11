#! /usr/bin/ksh


#
#  HardFeed  --  Harvest A Remote Directory via
#                Ftp Enhanced Exhaustive Duplication
#
#  Perderabo  11-23-02 http://www.unix.com/shell-programming-scripting/9174-recursive-ftp-here-last.html

VERSION="1.1"    # 03-16-04

USAGE="\
HardFeed [ -v | -s | -d | -r | -f | -m | -p password-file 
           -l list-command | -x ftp-command ...  ] system user [directory]

use \"HardFeed -h\" use for more documentation

-v (verbose)  Print stuff during run
-s (symlink)  Attempt to duplicate any remote symlinks
-d (directory)Attempt to duplicate any remote directories
-r (recurse)  Attempt to descend into any directories and process them
-f (freshen)  If remote file is newer than local file, overwrite the local 
-m (mode)     Attempt a chmod on files and directories that we create
-p (password) Specify a file that contains the password in plaintext
-x (extra)    Specify a command to be sent to the ftp client 
-l (listcmd)  Override the choice of \"ls .\" to get a remote directory"

DOCUMENTATION="HardFeed  Version $VERSION

e.g. ftp_copyDir.sh -r ftp-private.ebi.ac.uk ega-box-94 EGAS00001000122

$USAGE
HardFeed ftpserver joeblow somedir
This will connect to "ftpserver" and the user "joeblow". It will cd to "somedir". It will look at all of the files (and only the files) there. Each remote file that does not exist in the current directory will be copied to the current directory.

HardFeed -ds ftpserver joeblow somedir
This will work as the above example did. Except now we try to create local copies of any symbolic links or directories that we found in "somedir". Again, though, we will not overwrite any pre-existing object.

HardFeed -rds ftpserver joeblow somedir
Now we will create copies of any remote directories and desend into them. This will copy an entire directory tree. (except that it continues to ignore special files, pipes, etc.)

HardFeed -rs ftpserver joeblow somedir
This is similiar, except we only desend into pre-existing directories. You can use this to copy part of a directory structure. Just pre-create the few directories that you want to copy.

HardFeed -rdsm ftpserver joeblow somedir 
This will copy a directory tree, but this time it will try to duplicate the mode (permissions) on each remote object that is duplicated.

HardFeed -rdsf ftpserver joeblow somdir
The -f is "freshen". Again it copies a directory tree. But if we have a local file and a remote file, the timestamps are compared. The remote file will overwrite the the local file if the remote file was newer.


HardFeed copies all of the contents of a remote directory to the current 
directory using ftp.  It establishes an ftp connection to the remote 
site and it uses the ftp command \"ls\" to get a listing of the remote
directory.  The two required parameters are the remote sytstem and the user
name.  The optional third parameter is the remote directory to copy.  The 
default is just the home directory of the ftp account.

HardFeed will prompt you for the password.  This is very secure but it isn't
any good if you want to run HardFeed automatically. You can set the password in
the environment variable HARDFEED_P as an alternate.  HardFeed will set an
internal variable to the password and then clobber the variable HARDFEED_P,
since on some systems, the environment of another process can be displayed.
With most shells, you can also set an environment variable for one command
only, like this: \"HARDFEED_P=xyzzy HardFeed -dR ftpxy joeblow sourcedir\". 
A second alternative is to specify a \"password file\" with the -p option.  
Such a file contains, in plaintext, the password.  HardFeed will read the file
to get the password.  You must decide which option makes more sense in your
environment.

Only files are examined.  If we don't have a copy of the remote file, we 
will get it.  HardFeed will never overwrite an existing file system object
with one exception.  If you specify -f and we have both a remote file and a
local file, the timestamps are compared.  If the remote file is newer, a
retrieval attempt will be made.  The local file must be writable for this
to succeed.  For the timestamp compare to work, you and the remote system
must be in the same timezone.  (You can vary your environment to make this
true.)

Normally symbolic links are ignored. But with -s, we will attempt to create
a symlink with the same link data.  Even with -s, we will never overwrite
any existing object with a new symbolic link.  You will need to review any
symlinks created and probably correct them.  

Normally, directories are ignored.  If you specify -d, HardFeed will attempt
to create the directory locally.  But again, it will never overwrite an
existing object to create a directory.  If you specify -r, HardFeed will 
attempt to recurse into a directory and process all of the files there.  If
you use both -d and -r, it will copy an entire directory hierarchy.  But you
can leave off -d and only pre-create a few directories if you want.

HardFeed will attempt a chmod of any file or directory that it creates if you 
specify -m.  It will try to match the mode of the remote object.

HardFeed operates by establishing a co-process to the ftp command.  Normally,
the output from the co-process is sent to an un-named file in /tmp and
discarded.  If you want to capture this output, connect a file to fd 3 and
HardFeed will use it for this purpose.  From ksh the syntax is 3>file.  You 
can also do 3>&1 to see it real time during the run if you really want.

You can make HardFeed send the ftp co-process some extra commands after the
connection is established with -x.  

HardFeed gets a directory listing by sending a \"ls .\" command to the server.
Some servers will list dot files with this while others won't.  You can use the
-l option to change the command if your server needs a different one to do want
you want. -l \"ls -al\" is one example that I got to work with unix.

For a microsoft ftp server, I had some luck with:
 -l \"ls -la\" -x \"quote site dirstyle\"
Note that everything is transferred in binary mode.  -x ascii will switch
everything to ascii mode.  HardFeed supports embedded spaces in filenames.  User
names may be long and contain slashes. All of this may make it somewhat usable 
with microsoft ftp servers."


IFS="" 

#
#  If the password is coming in via the environment, save it in
#  a local variable and then clobber the environment variable

unset PASSWORD
if [[ -n $HARDFEED_P ]] ; then
	PASSWORD="$HARDFEED-P"
	HARDFEED_P='********'
fi


#
#  Parse Command Line
#
set -A OPT_CMDS_LIST
OPT_DIRCMD="ls ."
OPT_VERBOSE=0
OPT_SYMLINKS=0
OPT_DIRECTORIES=0
OPT_RECURS=0
OPT_FRESHEN=0
OPT_MODE=0
OPT_PASSWORDFILE=""
OPT_CMDS=0
error=0
while getopts :vsdrfmhp:x:l:  o ; do
	case $o in
	v)	OPT_VERBOSE=1
		;;
        s)      OPT_SYMLINKS=1
		;;
        d)      OPT_DIRECTORIES=1
                ;;
	r)      OPT_RECURS=1
		;;
	f)	OPT_FRESHEN=1
		;;
	m)	OPT_MODE=1
		;;
	h)	echo "$DOCUMENTATION"
		exit 0
		;;
	p)	OPT_PASSWORDFILE=$OPTARG
		if [[ ! -f $OPT_PASSWORDFILE ]] ; then
			echo error $OPT_PASSWORDFILE is not a file
			error=1
		fi
		;;
	x)	OPT_CMDS_LIST[OPT_CMDS]="$OPTARG"
		((OPT_CMDS=OPT_CMDS+1))
		;;
	l)	OPT_DIRCMD="$OPTARG"
		;;
	?)      print error argument $OPTARG is illegal
		error=1
		;;
	esac
done
shift OPTIND-1
if ((error)) ; then
	echo "$USAGE"
	exit 1
fi
if [[ $# -ne 2 && $# -ne 3 ]] ; then
	echo "$USAGE"
	exit 1
fi
SYSTEM=$1
USER=$2
DIRECTORY=$3
[[ -z $DIRECTORY ]] && DIRECTORY=.

#
#  Read password file if one is supplied

if [[ -n $OPT_PASSWORDFILE ]] ; then
	read PASSWORD < $OPT_PASSWORDFILE
fi


#
#  Request password if it didn't come in via env or file

if [[ -z $PASSWORD ]] ; then
	print -n password -
	stty -echo
	read PASSWORD
	echo
	stty echo
fi

#
#  FD 3 will be the transcript of the ftp co-process.  If the user
#  supplied a file for this, we will use that.  Otherwise it will go
#  to a nameless file in /tmp

if print -u3 " Transcript of the ftp co-process for HardFeed" 2>/dev/null ; then
	LOGFILE=""
else
	LOGFILE=/tmp/HardFeed.log.$$
	exec 3>$LOGFILE
	rm $LOGFILE
fi

#
#  Max time to wait for arrivial of file.  This is a long time.  During
#  an interactive run, the user can use SIGINT if it seems to be taking
#  too long.  This max is intended to assure that a cron job will not
#  hang forever.

OPT_MAXWAIT=15
TIMEOUT=/tmp/HardFeed.timeout.$$

#
#  Various other initializations

LEV=0
date "+%Y %m" | IFS=" " read THISYEAR THISMONTH
((LASTYEAR=THISYEAR-1))
STARTPATH=$(pwd)
set -A DIR_FILE_NAME
set -A DIR_LINE_NUM

#
#  Function to convert month to numeric

conv_month() {
	typeset -l month
	month=$1
	case $month in
	jan)	nmonth=1  ;;
	feb)	nmonth=2  ;;
	mar)	nmonth=3  ;;
	apr)	nmonth=4  ;;
	may)	nmonth=5  ;;
	jun)	nmonth=6  ;;
	jul)	nmonth=7  ;;
	aug)	nmonth=8  ;;
	sep)	nmonth=9  ;;
	oct)	nmonth=10 ;;
	nov)	nmonth=11 ;;
	dec)	nmonth=12 ;;
	*)	nmonth=0  ;;
	esac
	echo $nmonth
	return $((!nmonth))
}


#
# Function to determine if a file system object exists
#
# neither -a nor -e is really portable  8(
  
exists() {
	[[ -f $1 || -d $1 || -L $1 || -p $1 || -S $1 || -b $1 || -c $1 ]]
	return $?
	}


#
# Function to wait for a file to arrive

waitfor() {
	wanted=$1
	if ((OPT_MAXWAIT)) ; then
		((GIVEUP=SECONDS+OPT_MAXWAIT))
	else
		GIVEUP="-1"
	fi

	while 	[[ ! -f $wanted && $SECONDS -lt $GIVEUP ]] ; do
		sleep 1
	done
	if [[ ! -f $wanted ]] ; then
		echo "FATAL ERROR:" timed out waiting for:  2>&1
		echo "            " "$wanted"               2>&1
		echo 
		print -p bye  2>/dev/null
		exit 2
	fi
	return 0
}

#
#  Function to decode an "ls -l" line.

lsdcode() {

	typeset -Z2 nmonth day
	typeset -i8 octal

	#
	#  get the line, get the first character, split line into words

	line="$1"
	char1=${line%%${line#?}}
	IFS=" "
	set -A  things -- $line
	IFS=""

	#
	#  We may have a "total" line which needs to be ignored

	if [[ ${things[0]} = total ]] ; then
		set -A  lsdc --  skip 000 000000000000 x x
		return 0
	fi

	#
	#
	parser=1
	month=${things[5]}
	xmonth=$(conv_month $month)
	if  conv_month $month > /dev/null ; then
		parser=1
	else
		parser=0
	fi

	if ((parser)); then
		#
		# Strict Left to Right Parse Routine 
		#
		# Break out the fields that we want.  This technique requires
		# that the user, group, and size fields never run together and
		# so they must have at least one space between them.  But it 
		# allows some limited support of filenames with embedded spaces.

		echo "$line" | IFS=" " read permstring junk junk junk junk \
						month day swing rawname
		if [[ $char1 = l ]] ; then
			link=${rawname#*-\> }
			name=${rawname% -\>*}
		else
			name="$rawname"
			link=""
		fi
	else
		#
		# Outside to Inside Parse Routine 
		#
		# Break out the fields that we want.  This technique requires 
		# that no white space exist in the filename.  But the user, 
		# group, and size  fields may sometimes run together without 
		# causing a problem.

		echo "WARNING:" badly formatted line in directory listing for:    >&2
		echo "        " "${line}"                                         >&2
		echo "        " attempting outside-to-inside scan                 >&2
		echo                                                              >&2

		((pname=${#things[*]}-1))
		if [[ $char1 = l ]] ; then
			link=${things[pname]}
			((pname=pname-2))
		else
			link=
		fi
		permstring=${things[0]}
		name=${things[pname]}
		month=${things[pname-3]}
		day=${things[pname-2]}
		swing=${things[pname-1]}
		if  conv_month $month > /dev/null ; then
			:
		else
			echo "ERROR: " outside-to-inside scan has also failed >&2
			echo "       " giving up on:                          >&2
			echo "       " "$line"                                >&2
			echo                                                  >&2
			set -A  lsdc --  skip 000 000000000000 x x
			return 0
		fi
	fi


	#
	#  Ignore . and ..

	if [[ $name = . || $name = .. ]] ; then
			set -A  lsdc --  skip 000 000000000000 x x
			return 0
	fi

	#
	#  decode permissions  (the permission string is first word

	set -A perms -- $(print -- ${permstring#?} | sed 's/./& /g')
	extras=0
	[[ ${perms[2]} = S ]] && { ((extras=extras+4000)); perms[2]=- ; }
	[[ ${perms[2]} = s ]] && { ((extras=extras+4000)); perms[2]=x ; }
	[[ ${perms[5]} = S ]] && { ((extras=extras+2000)); perms[5]=- ; }
	[[ ${perms[5]} = s ]] && { ((extras=extras+2000)); perms[5]=x ; }
	[[ ${perms[8]} = T ]] && { ((extras=extras+1000)); perms[8]=- ; }
	[[ ${perms[8]} = t ]] && { ((extras=extras+1000)); perms[8]=x ; }

	binary=2#$(print -- ${perms[@]} | sed 's/ //g;s/-/0/g;s/[^0]/1/g')
	((octal=binary))
	result=$(echo $octal)
	result=${result#??}
	((result=result+extras))

	#
	# Decode date and time and convert it to yyyymmddhhmm

	nmonth=$(conv_month $month)
	if [[ $swing = *:* ]] ; then
		if [[ $nmonth > $THISMONTH ]] ; then
			((year=LASTYEAR))
		else
			((year=THISYEAR))
		time1=${swing%???}
		time2=${swing#???}
		time="${time1}${time2}"
		fi
        else
                year=$swing
		time="0000"
        fi

	#
	#  Output the final record

	set -A lsdc -- ${char1} ${result} ${year}${nmonth}${day}${time} ${name} ${link}
	return
}


#
#  Function to process a remote file
#  We will not overwrite and existing file unless we in "freshen" mode.
#  And unless we are in "freshen" mode, it is an error for a file to
#  pre-exist.

process_remote_file() {
	VMESS="${VMESS} is a remote file that"
	do_get=0
	if [[ -f $name ]] ; then
		VMESS="${VMESS} already exists"
		if ((OPT_FRESHEN)) ; then
			line2=$(ls -ld "$name")
			lsdcode "$line2" 
			char12=${lsdc[0]}
			mode2=${lsdc[1]}
			datestamp2=${lsdc[2]}
			name2=${lsdc[3]}
			link2=${lsdc[4]}
			if [[ $datestamp > $datestamp2 ]] ; then
				VMESS="${VMESS} but is out-of-date and"
				do_get=1
			else
				VMESS="${VMESS} and is current"
			fi
		else
			VMESS="${VMESS} and cannot be retrieved"
			echo WARNING: no get since $name exists in ${localpath} >&2
		fi
	else
		do_get=1
	fi
	if ((do_get)) ; then
		print -p get \""$name"\"
		waitfor $name
		VMESS="${VMESS} has been retrieved"
		if ((OPT_MODE)) ; then
			chmod $mode "$name"
		fi
	fi
	if (($OPT_VERBOSE)) ; then
		echo "$VMESS"
	fi
	return 0
}


#  Function to process a remote directory
#  To this function, a remote directory is just an object that
#  may need to be duplicated in the current directory

process_remote_directory() {

	VMESS="${VMESS} is a remote directory that"
	if ((OPT_DIRECTORIES)) ; then
		if exists $name  ; then
			if [[ ! -d $name ]] ; then
				VMESS="${VMESS} cannot be created due to pre-existing object"
				echo WARNING: no mkdir since $name exists in ${localpath} >&2
			else
				VMESS="${VMESS} already exists"
			fi
		else
			mkdir "$name"
			VMESS="${VMESS} has been created locally"
			if ((OPT_MODE)) ; then
				chmod $mode "$name"
			fi
		fi
	else
		VMESS="${VMESS} has been ignored"
	fi
	if (($OPT_VERBOSE)) ; then
		echo "$VMESS"
	fi
	if ((OPT_RECURS)) ; then
		if [[ -d "$name" ]] ; then
			cd "$name"
			print -p lcd \""$name"\"
			exec 4<&-
			obtain_and_process_remote_ls "$name"
			print -p cd ..
			print -p lcd ..
			cd ..
			exec 4< ${DIR_FILE_NAME[LEV]}
			lineno=0
			while (( lineno != ${DIR_LINE_NUM[LEV]})) ; do
				read -u4 junk
				((lineno=lineno+1))
			done
		fi
	fi
	return 0
}


#
#  Function to process a remote symlink
#  Note that we deal with th symlink only --  not
#  the object (if any) that the link points to.

process_remote_symlink() {
	VMESS="${VMESS} is a remote symlink that"
	if ((OPT_SYMLINKS)) ; then
		if exists "$name" ; then
			if [[ ! -L $name ]] ; then
				VMESS="${VMESS} cannot be created due to pre-existing object"
				echo WARNING: no symlink since $name exists in ${localpath} >&2
			else
				VMESS="${VMESS} already exists"
			fi
		else
			ln -s "$link" "$name"
			VMESS="${VMESS} has been duplicated locally"
		fi
	else
		VMESS="${VMESS} has been ignored"
	fi
	if (($OPT_VERBOSE)) ; then
		echo "$VMESS"
	fi
}


#
#  If a remote object is not a file, directory, or
#  symlink, we come here.  

process_remote_weirdo() {
	VMESS="${VMESS} is a remote unknown object that has been ignored"
	return 0
	}

#
#  This function obtains an "ls" listing from the remote ftp system.  Then it 
#  scans the listing line by line to figure out what to do.  It will completely 
#  process the current directory.

obtain_and_process_remote_ls() {

	typeset rdir tmpfile okfile   ## local scope variables ##
	rdir=$1

	#
	#  Set up variables or modify them if we have recursed

	((LEV=LEV+1))
	tmpfile=/tmp/HardFeed.tp.$$.${LEV}
	okfile=/tmp/HardFeed.ok.$$.${LEV}
	if ((LEV == 1)) ; then
		localpath=$STARTPATH
		remotepath=$rdir
	else
		localpath=${localpath}/$rdir
		remotepath=${remotepath}/$rdir

	fi

	#
	#  Get a copy of the remote dir output in a local file
	#  called $tmpfile 

	print -p cd \""$rdir"\"
	print -p $OPT_DIRCMD $tmpfile
	print -p $OPT_DIRCMD $okfile
	waitfor $okfile
	DIR_FILE_NAME[LEV]=$tmpfile
	DIR_LINE_NUM[LEV]=0
	exec 4< $tmpfile

	#
	#  process each line
	#

	while read -u4 line ; do
		((DIR_LINE_NUM[LEV]=${DIR_LINE_NUM[LEV]}+1))
		lsdcode "$line" 
		char1=${lsdc[0]}
		mode=${lsdc[1]}
		datestamp=${lsdc[2]}
		name=${lsdc[3]}
		link=${lsdc[4]}
		VMESS="${remotepath}/${name}"
		case $char1 in
		skip)   ;;
		-)      process_remote_file
			;;
		d)      process_remote_directory
			;;
		l)      process_remote_symlink
			;;
		*)      process_remote_weirdo
			;;
		esac
	done 

#
#  We may have recursed...so we must put everything back the way
#  we found it

	localpath=${localpath%$rdir}
	localpath=${localpath%/}
	remotepath=${remotepath%$rdir}
	remotepath=${remotepath%/}
	rm $tmpfile
	rm $okfile
	((LEV=LEV-1))

	return 0
}


#
#  Main Program
#


ftp -inv >&3 2>&1 |&
print -p open $SYSTEM
print -p user $USER $PASSWORD
print -p binary

i=0
while ((OPT_CMDS>i)) ; do
	print -p ${OPT_CMDS_LIST[i]}
	((i=i+1))
done

obtain_and_process_remote_ls $DIRECTORY

print -p bye
wait
exit 0