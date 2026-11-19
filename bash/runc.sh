#!/bin/bash

if [[ "$0" != "$BASH_SOURCE[0]" ]]; then
	return &>/dev/null
fi

function runc() {
	local binf=bin/pubbin
	local srcf=$1
	local ret_
	clang -std=c23 $srcf -o $binf
	ret_=$?
	if [[ $ret_ -eq 0 ]]; then
		echo -e "done : run $binf"
		bin/pubbin
	else
		echo -e "error: compile failed !"
	fi
}

function main() {
	runc $@
}

main $@
exit 0
