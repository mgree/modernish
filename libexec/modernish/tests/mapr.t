#! test/for/moderni/sh
# See the file LICENSE in the main modernish directory for the licence.

# Regression tests for var/mapr

doTest1() {
	title='read all the lines of a text file'
	runExpensive || return
	foo=
	foo() {
		push IFS
		IFS=$CCn
		foo=$foo"$*"$CCn  # quote "$*" for BUG_PP_* compat
		pop IFS
	}
	mapr foo < $MSH_PREFIX/libexec/modernish/safe.mm || return 1
	trim foo $CCn
	identic $foo $(cat $MSH_PREFIX/libexec/modernish/safe.mm)
}

doTest2() {
	title='skip, limit and quantum'
	v=$(putln "\
     1	y
     2	y
     3	y
     4	y
     5	y
     6	y
     7	y
     8	y
     9	y
    10	y
    11	y
    12	y
    13	y
    14	y
    15	y" | mapr -s 3 -n 10 -c 4 printf '\t\t[%s]\n' '--------')

	identic $v "\
		[--------]
		[     4	y]
		[     5	y]
		[     6	y]
		[     7	y]
		[--------]
		[     8	y]
		[     9	y]
		[    10	y]
		[    11	y]
		[--------]
		[    12	y]
		[    13	y]"
}

doTest3() {
	title='delim; max total args length; abort exec'
	foo() {
		printf '%s,' "$@"
		return 255  # abort
	}
	v=$(put " 1${CCt}y/ 2${CCt}y/ 3${CCt}y/ 4${CCt}y/ 5${CCt}y/ 6${CCt}y/ " | mapr -d / -m 18 foo)
	if ne $? 1; then
		failmsg='bad exit status'
		return 1
	fi
	identic "$v" " 1${CCt}y, 2${CCt}y, 3${CCt}y, 4${CCt}y,"
}

doTest4() {
	title='max args length per batch, args aligned'
	runExpensive || return
	OutputOneBatch() {
		IFS=; v="$*"
		extern -p printf %s "$@" || return
		return 255  # abort
	}
	setlocal v test_arg='' arg_len max_len result arg_len arg_len_algn expected_num; do
		max_len=$(PATH=$DEFPATH exec getconf ARG_MAX 2>/dev/null) || max_len=262144
		dec max_len 2048
		if ne max_len _Msh_mapr_max; then
			failmsg="wrong ARG_MAX"
			return 1
		fi
		# On macOS, arguments are aligned on 8 byte boundaries and have an 8 byte length count each.
		# We also have to account for 1 extra byte for the 0 byte that terminates a C string.
		# Hopefully there is no system that aligns its arguments to even wider intervals.
		let "arg_len = ${RANDOM:-$$} % 256 + 1" \
			"arg_len_algn = ((arg_len % 8 == 0) ? arg_len : (arg_len - arg_len % 8 + 8)) + 9" \
			"expected_num = max_len / arg_len_algn"
		while lt ${#test_arg} arg_len; do
			test_arg=${test_arg}x
		done
		result=$(use sys/base/yes && yes $test_arg | mapr OutputOneBatch)
		if ne $? 1; then
			failmsg='bad exit status'
			return 1
		fi
		if let "${#result} != expected_num * arg_len"; then
			failmsg='wrong result length'
			return 1
		fi
	endlocal
}

lastTest=4
