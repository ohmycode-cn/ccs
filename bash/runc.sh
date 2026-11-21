#!/bin/bash
#
# Compile C source files with clang and run the resulting binary.

if [[ "${0}" != "${BASH_SOURCE[0]}" ]]; then
	echo -e "ERROR: Usage bash runc.sh [flag] (options)"
	return 1 &>/dev/null
fi

__BINF__="pubbin"
__DIRF__="bin"
__FILE__=()
__FLAG__=1
__APPOINT_F__="nof"
__STATIC__="off"
__EDIT__="off"
__STD__="c23"

#######################################
# Parse command-line arguments into global compile settings.
# Globals:
#   __FILE__
#   __FLAG__
#   __STATIC__
#   __STD__
# Arguments:
#   $@: --file/--f <src>..., --static on|off, --std 11|17|23
# Outputs:
#   Writes status and error messages to stdout.
# Returns:
#   0 on success, 1 on invalid arguments.
#######################################
function parser() {
	echo -e "INFO : Parser start"
	while (( $# > 0 )); do
		case "${1}" in 
			--file | --f)
				shift
				if (( $# == 0 )) || [[ "${1}" == -* ]]; then
					echo -e "ERROR: At least one actual argument for --file/--f must be provided"
					return 1
				fi
				while (( $# > 0 )) && [[ "${1}" != -* ]]; do
					__FILE__+=("${1}")
					shift
				done
				;;
			--static)
				if (( $# < 2 )); then
					echo -e "ERROR: --static ?, ?:{off/on}"
					return 1
				fi
				shift
				if [[ "${1}" != "on" && "${1}" != "off" ]]; then
					echo -e "ERROR: --static ?, ?:{off/on}. But you provided is ${1}"
					return 1
				else
					__STATIC__="${1}"
					shift
				fi
				;;
			--std)
				if (( $# < 2 )); then
					echo -e "ERROR: --std ?, ?:{99,11,17,18,23}"
					return 1
				fi
				shift
				if [[ "${1}" != "99" && "${1}" != "11" && "${1}" != "17" ]] && [[ "${1}" != "18" && "${1}" != "23" ]]; then
					echo -e "ERROR: -std ?, ?:{99,11,17,18,23}. But you provided is ${1}"
					return 1;
				else
					case "${1}" in
						"99")
							__STD__="c99"
							;;
						"11")
							__STD__="c11"
							;;
						"17")
							__STD__="c17"
							;;
						"18")
							__STD__="c18"
							;;
						"*")
							__STD__="c23"
							;;
						esac
					shift
				fi
				;; 
			--edit | --e)
				if (( $# == 2 )); then
					shift
					__APPOINT_F__="${1}"
				fi
				__EDIT__="on"
				shift
				;;
			*)
				echo -e "PANIC: Unknown parameter :("
				__FLAG__=1
				return 1
			;;
	    esac
	done
	__FLAG__=0
}

#######################################
# Compile the collected C sources with clang and run the binary.
# Globals:
#   __BINF__
#   __DIRF__
#   __FILE__
#   __STATIC__
#   __STD__
# Arguments:
#   None
# Outputs:
#   Writes progress messages and program output to stdout.
#######################################
function runc() {
	echo -e "INFO : Running compile ..."

	local ret

	if [[ "on" == "${__EDIT__}" && "nof" == "${__APPOINT_F__}" ]]; then
		nvim "${__FILE__[0]}"
	elif [[ "on" == "${__EDIT__}" && "nof" != "${__APPOINT_F__}" ]]; then
		local flag_=1
		for f in "${__FILE__[@]}"; do
			if cmp -s "${__APPOINT_F__}" "${f}"; then
				flag_=0
				nvim "${__APPOINT_F__}"
			fi
		done
		if [[ "1" == "${flag_}" ]]; then
			echo -e "PANIC: Can't found file ${__APPOINT_F__}"
			return 1
		fi
	fi

	if [[ "on" == "${__STATIC__}" ]]; then
		clang -std="${__STD__}" -static "${__FILE__[@]}" -o "${__DIRF__}/${__BINF__}"
	else
		clang -std="${__STD__}" "${__FILE__[@]}" -o "${__DIRF__}/${__BINF__}"
	fi

	ret="${?}"

	if [[ 0 == "${ret}" ]]; then
		"${__DIRF__}/${__BINF__}"
	else
		echo -e "PANIC: run ${__DIRF__}/${__BINF__} failed !"
	fi
}

#######################################
# Parse arguments, then compile and run the sources.
# Globals:
#   __FLAG__
# Arguments:
#   $@: program options forwarded to parser.
# Outputs:
#   Writes status and error messages to stdout.
# Returns:
#   0 on success, 1 if argument parsing fails.
#######################################
function main() {
	parser "${@}"

	if [[ $__FLAG__ -ne 0 ]]; then
		echo -e "ERROR: Current is uncompiliable qualification"
		return 1
	fi

	runc
	return 0
}

main "${@}"

exit 0 # This is expected exit status '--contract-exit'
