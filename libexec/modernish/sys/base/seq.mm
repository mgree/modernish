#! /module/for/moderni/sh

# modernish sys/base/seq
#
# Usage: seq [-w] [-f FORMAT] [-s STRING] [-S N] [-B N] [-b N] [FIRST [INCR]] LAST
# 'seq' prints a sequence of arbitrary-precision floating point numbers, one
# per line, from FIRST (default 1), to near LAST as possible, in increments of
# INCR (default 1). If FIRST is larger than LAST, the default INCR is -1.
#	-w: Equalise width by padding with leading zeros. The longest of the
#	    FIRST, INCR or LAST parameters is taken as the length that each
#	    output number should be padded to.
#	-f: printf-style floating-point format. Since this uses awk's printf,
#	    it only be used if the output base is 10.
#	-s: Use STRING to separate numbers. Default: newline. The final
#	    terminator is always a newline in any case.
#	-S: Explicitly set the scale (number of digits after decimal point).
#	    Defaults to the largest number of digits after the decimal point
#	    among the FIRST, INCR or LAST parameters.
#	-B: Set input and output base from 1 to 16. Defaults to 10.
#	-b: Set arbitrary output base from 1. Defaults to input base.
#
# --- begin license ---
# Copyright (c) 2016 Martijn Dekker <martijn@inlv.org>, Groningen, Netherlands
# 
# Permission to use, copy, modify, and/or distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
# 
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
# --- end license ---

# Harden 'bc' against both system error (excluding SIGPIPE) and invalid input.
# We can't rely on the exit status, see:
# http://pubs.opengroup.org/onlinepubs/9699919799/utilities/bc.html#tag_20_09_16
# However, at least with GNU 'bc', we can rely on normal output going to
# standard output, and error messages going to standard error. So, use -E
# to intercept standard error and check if any error message was printed.
# (Pre-2017 versions of OpenBSD 'bc' unfortunately write error messages to
# standard output, so there's nothing we can do there. This was reported as
# a bug and fixed, but on OpenBSD and FreeBSD until 2017, the below hardens
# against unsuccessful launch of 'bc' only.)
harden -f _Msh_seq_bc -p -P -E POSIXLY_CORRECT=y LC_ALL=C bc

# Harden 'awk' against system error (excluding SIGPIPE) and invalid input.
harden -f _Msh_seq_awk -p -P POSIXLY_CORRECT=y LC_ALL=C awk

# Helper function for -s (a non-newline separator).
# (GNU and BSD 'seq' behaves differently: GNU treats it like a real
# separator and prints final newline, BSD treats it as a terminator
# and doesn't print final newline. Modernish acts like GNU.)
_Msh_seq_s() {
	export _Msh_seqO_s
	_Msh_seq_awk '
		BEGIN {
			ORS=ENVIRON["_Msh_seqO_s"];
		}
		{
			if (NR>1)
				print prevline;
			prevline=$0;
		}
		END {
			ORS="\n";
			print prevline;
		}
	'
}

# Helper function for -w (padding with leading zeros).
_Msh_seq_w() {
	_Msh_seq_awk -v "L=${_Msh_seq_L}" -v "R=${_Msh_seq_R}" '{
		if ((R>0) && ($0 !~ /\./)) {
			# work around GNU & Solaris "bc" oddity: scale is suppressed on output when foo/1 == 0
			if (L==1)
				$0="";
			$0=($0)(".");
			for (i=0; i<R; i++)
				$0=($0)("0");
		}
		j=L+R-length();
		if ($0 ~ /^-/)
			for (i=0; i<j; i++)
				sub(/^-/, "-0");
		else
			for (i=0; i<j; i++)
				$0=("0")($0);
		print;
	}'
}

# Helper function for backslash-unwrapping very long numbers from 'bc' output (> 69 columns).
_Msh_seq_unwrap() {
	_Msh_seq_awk '
		/\\$/ {
			sub(/\\$/, "");
			contline=(contline)($0);
			next;
		}
		{
			print (contline)($0);
			contline="";
		}
	'
}

# Main function.
seq() {
	# --- begin option parser (generated by opts/parsergen module) ---
	# The command used to generate this parser was:
	# generateoptionparser -o -n 'w' -a 'sfBbS' -f 'seq' -v '_Msh_seqO_'
	unset -v _Msh_seqO_w _Msh_seqO_s _Msh_seqO_f _Msh_seqO_B _Msh_seqO_b _Msh_seqO_S
	forever do
		case ${1-} in
		( -[!-]?* ) # split a set of combined options
			_Msh_seqO__o=${1#-}
			shift
			forever do
				case ${_Msh_seqO__o} in
				( '' )	break ;;
				# if the option requires an argument, split it and break out of loop
				# (it is always the last in a combined set)
				( [sfBbS]* )
					_Msh_seqO__a=-${_Msh_seqO__o%"${_Msh_seqO__o#?}"}
					push _Msh_seqO__a
					_Msh_seqO__o=${_Msh_seqO__o#?}
					if not empty "${_Msh_seqO__o}"; then
						_Msh_seqO__a=${_Msh_seqO__o}
						push _Msh_seqO__a
					fi
					break ;;
				esac
				# split options that do not require arguments (and invalid options) until we run out
				_Msh_seqO__a=-${_Msh_seqO__o%"${_Msh_seqO__o#?}"}
				push _Msh_seqO__a
				_Msh_seqO__o=${_Msh_seqO__o#?}
			done
			while pop _Msh_seqO__a; do
				set -- "${_Msh_seqO__a}" "$@"
			done
			unset -v _Msh_seqO__o _Msh_seqO__a
			continue ;;
		( -[w] )
			eval "_Msh_seqO_${1#-}=''" ;;
		( -[sfBbS] )
			let "$# > 1" || die "seq: $1: option requires argument" || return
			eval "_Msh_seqO_${1#-}=\$2"
			shift ;;
		( -- )	shift; break ;;
		( -* )	die "seq: invalid option: $1" || return ;;
		( * )	break ;;
		esac
		shift
	done
	# ^^^ end option parser ^^^

	# Check the input base (defaults to 10) and determine valid input digits.
	if not isint "${_Msh_seqO_B=10}" || let "(_Msh_seqO_B < 2) || (_Msh_seqO_B > 16)"; then
		die "seq: invalid input base: ${_Msh_seqO_B}" || return
	fi
	case $((_Msh_seqO_B)) in
	( 2 )	_Msh_seq_digits=01 ;;
	( 3 )	_Msh_seq_digits=012 ;;
	( 4 )	_Msh_seq_digits=0123 ;;
	( 5 )	_Msh_seq_digits=01234 ;;
	( 6 )	_Msh_seq_digits=012345 ;;
	( 7 )	_Msh_seq_digits=0123456 ;;
	( 8 )	_Msh_seq_digits=01234567 ;;
	( 9 )	_Msh_seq_digits=012345678 ;;
	( 10 )	_Msh_seq_digits=0123456789 ;;
	( 11 )	_Msh_seq_digits=0123456789Aa ;;
	( 12 )	_Msh_seq_digits=0123456789ABab ;;
	( 13 )	_Msh_seq_digits=0123456789ABCabc ;;
	( 14 )	_Msh_seq_digits=0123456789ABCDabcd ;;
	( 15 )	_Msh_seq_digits=0123456789ABCDEabcde ;;
	( 16 )	_Msh_seq_digits=0123456789ABCDEFabcdef ;;
	esac

	# Check the output base. Defaults to input base.
	if not isint "${_Msh_seqO_b=${_Msh_seqO_B}}" || let "_Msh_seqO_b < 2"; then
		die "seq: invalid output base: ${_Msh_seqO_b}" || return
	fi

	# Check the scale. Defaults to none; in the 'bc' script, we're using a trick to make it
	# default to the input number with the largest amount of digits after decimal point.
	if isset _Msh_seqO_S && { not isint "${_Msh_seqO_S}" || let "_Msh_seqO_S < 1"; }; then
		die "seq: invalid scale: ${_Msh_seqO_S}" || return
	fi

	# Parse non-option arguments.
	unset -v _Msh_seq_incr
	case $# in
	( 1 )	_Msh_seq_first=1; _Msh_seq_last=$1 ;;
	( 2 )	_Msh_seq_first=$1; _Msh_seq_last=$2 ;;
	( 3 )	_Msh_seq_first=$1; _Msh_seq_incr=$2; _Msh_seq_last=$3 ;;
	( * )	die "seq: need 1 to 3 floating point numbers." \
		"${CCn}Usage: seq [-w] [-f FORMAT] [-s STRING] [-S N] [-B N] [-b N] [FIRST [INCR]] LAST" || return ;;
	esac

	# Check the increment.
	case ${_Msh_seq_incr-u} in
	( u )	_Msh_seq_incr=0 ;;			# let bc script choose default
	( [+-]*[!0]* | *[!0+-]* ) ;;			# if it contains any non-zero character, it's either non-zero or invalid
	( * )	die "seq: zero increment" || return ;;	# block infinite loop (like BSD 'seq'); use 'yes' for that
	esac

	# Check that _first, _incr and _last are all valid float numbers in the given input base.
	for _Msh_seq_n in "${_Msh_seq_first}" "${_Msh_seq_incr}" "${_Msh_seq_last}"; do
		case ${_Msh_seq_n} in
		( '' | [+-] | ?*[+-]* | *.*.* | *[!"${_Msh_seq_digits}.+-"]* )
			shellquote _Msh_seq_n
			die "seq: invalid base ${_Msh_seqO_B} floating point number: ${_Msh_seq_n}" || return ;;
		esac
	done

	# Convert any A-F digits to upper case, as 'bc' requires.
	let "_Msh_seqO_B > 10" && toupper _Msh_seq_first _Msh_seq_incr _Msh_seq_last

	# Figure out the max total length of digits to the [L]eft and [R]ight of the decimal point.
	_Msh_seq_L=0
	_Msh_seq_R=0
	for _Msh_seq_S in "${_Msh_seq_first#+}" "${_Msh_seq_incr#+}" "${_Msh_seq_last#+}"; do
		_Msh_seq_S=${_Msh_seq_S%.*}
		let "_Msh_seq_L < ${#_Msh_seq_S}" && _Msh_seq_L=${#_Msh_seq_S}
	done
	if isset _Msh_seqO_S; then
		_Msh_seq_R=${_Msh_seqO_S}
	else
		for _Msh_seq_S in "${_Msh_seq_first}" "${_Msh_seq_incr}" "${_Msh_seq_last}"; do
			identic "${_Msh_seq_S}" "${_Msh_seq_S#*.}" && continue
			_Msh_seq_S=${_Msh_seq_S#*.}
			let "_Msh_seq_R < ${#_Msh_seq_S}" && _Msh_seq_R=${#_Msh_seq_S}
		done
	fi
	contains "${_Msh_seq_first}${_Msh_seq_incr}${_Msh_seq_last}" '.' && let "_Msh_seq_L += 1"
	unset -v  _Msh_seq_S

	# Construct a shell pipeline based on the options given.
	if let "_Msh_seq_L + _Msh_seq_R > 69"; then
		# Backslash-unwrap 'bc' output.
		_Msh_seq_cmd="_Msh_seq_bc | _Msh_seq_unwrap"
	else
		_Msh_seq_cmd="_Msh_seq_bc"
	fi
	if isset _Msh_seqO_f; then
		let "_Msh_seqO_b == 10" || die "seq: '-f' can only be used with output base 10 (is ${_Msh_seqO_b})" || return
		_Msh_seqO_f='{ printf("'"${_Msh_seqO_f}"'\n", $0); }'
		shellquote _Msh_seqO_f
		_Msh_seq_cmd="${_Msh_seq_cmd} | _Msh_seq_awk ${_Msh_seqO_f}"
	elif isset _Msh_seqO_w; then
		_Msh_seq_cmd="${_Msh_seq_cmd} | _Msh_seq_w"
	fi
	if isset _Msh_seqO_s && not identic "${_Msh_seqO_s}" "$CCn"; then
		_Msh_seq_cmd="${_Msh_seq_cmd} | _Msh_seq_s"
	fi

	# Flag for "no scale specified".
	not isset _Msh_seqO_S && _Msh_seqO_noS='' || unset -v _Msh_seqO_noS

	# Do the magic. Read up on 'bc' and its intricacies here:
	# http://pubs.opengroup.org/onlinepubs/9699919799/utilities/bc.html
	# (note: the 'f+i+l-i-l' dummy calculation in the 'for' loop init has the effect of setting the
	# scale to the largest of f, i or l from the start, resulting in a consistent number of digits
	# after the decimal point from the start; this is only done if option S, scale, was not given.
	# Likewise, if scale *was* given, divide each output by 1 to trigger output with that scale.)
	# QRK_HDPARQUOT compat: no quotes within par.subst. in here-doc, i.e. ${var+x} not ${var+"x"}
	eval "${_Msh_seq_cmd}" <<-end_of_bc_program	
		${_Msh_seqO_S+scale = $((_Msh_seqO_S))}
		obase = $((_Msh_seqO_b))
		ibase = $((_Msh_seqO_B))

		f = ${_Msh_seq_first#+}
		i = ${_Msh_seq_incr#+}
		l = ${_Msh_seq_last#+}

		/* as in BSD 'seq', the default incr is -1 if first > last */
		if (i == 0) {
			if (f <= l) i = 1
			if (f > l) i = -1
		}

		/* do the seq */
		if (i < 0) {
			for (n = f${_Msh_seqO_noS++i+l-i-l}; n >= l; n += i) {
				n${_Msh_seqO_S+/1}
			}
		}
		if (i > 0) {
			for (n = f${_Msh_seqO_noS++i+l-i-l}; n <= l; n += i) {
				n${_Msh_seqO_S+/1}
			}
		}
	end_of_bc_program
	unset -v _Msh_seq_first _Msh_seq_incr _Msh_seq_last _Msh_seq_n _Msh_seq_digits _Msh_seq_cmd \
		_Msh_seq_L _Msh_seq_R _Msh_seq_S \
		_Msh_seqO_w _Msh_seqO_s _Msh_seqO_f _Msh_seqO_B _Msh_seqO_b _Msh_seqO_S _Msh_seqO_noS
}

if thisshellhas ROFUNC; then
	readonly -f _Msh_seq_bc _Msh_seq_awk _Msh_seq_s _Msh_seq_w _Msh_seq_unwrap seq
fi
