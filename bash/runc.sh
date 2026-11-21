#!/bin/bash
#
# Compile C source files with clang and run the resulting binary.

if [[ "${0}" != "${BASH_SOURCE[0]}" ]]; then
	echo -e "Fatal: Usage bash runc.sh [flag] (options)"
	return 1 &>/dev/null
fi

BINF="pubbin"
DIRF="bin"
C_SRC_FILES=()
FLAG=1
__STATIC__="off"
__EDIT__="off"
__APPOINT_F__="nof"
__STD__="c23"

#######################################
# Parse command-line arguments into global compile settings.
# Globals:
#   C_SRC_FILES
#   FLAG
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
	echo -e "Info : Parser start"
	while (( $# > 0 )); do
		case "${1}" in 
			--file | --f)
				shift
				if (( $# == 0 )) || [[ "${1}" == -* ]]; then
					echo -e "Error: At least one actual argument for --file/--f must be provided"
					return 1
				fi
				while (( $# > 0 )) && [[ "${1}" != -* ]]; do
					C_SRC_FILES+=("${1}")
					shift
				done
				;;
			--static)
				if (( $# < 2 )); then
					echo -e "Error: --static ?, ?:{off/on}"
					return 1
				fi
				shift
				if [[ "${1}" != "on" && "${1}" != "off" ]]; then
					echo -e "Error: --static ?, ?:{off/on}. But you provided is ${1}"
					return 1
				else
					__STATIC__="${1}"
					shift
				fi
				;;
			--std)
				if (( $# < 2 )); then
					echo -e "Error: --std ?, ?:{99,11,17,18,23}"
					return 1
				fi
				shift
				if [[ "${1}" != "99" && "${1}" != "11" && "${1}" != "17" ]] && [[ "${1}" != "18" && "${1}" != "23" ]]; then
					echo -e "Error: -std ?, ?:{99,11,17,18,23}. But you provided is ${1}"
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
				shift
				__EDIT__="on"
				;;
			*)
				echo -e "Panic: Unknown parameter :("
				FLAG=1
				return 1
			;;
	    esac
	done
	FLAG=0
}

#######################################
# Compile the collected C sources with clang and run the binary.
# Globals:
#   BINF
#   DIRF
#   C_SRC_FILES
#   __STATIC__
#   __STD__
# Arguments:
#   None
# Outputs:
#   Writes progress messages and program output to stdout.
#######################################
function runc() {
	echo -e "Info : Running compile ..."

	local ret

	if [[ "on" == "${__EDIT__}" && "nof" == "${__APPOINT_F__}" ]]; then
		nvim "${C_SRC_FILES[0]}"
	elif [[ "on" == "${__APPOINT_F__}" && "nof" != "${__APPOINT_F__}" ]]; then
		local flag_=1
		for f in "${C_SRC_FILES[@]}"; do
			if cmp -s "${__APPOINT_F__}" "${f}"; then
				flag_=0
				nvim "${__APPOINT_F__}"
			fi
		done
		if [[ "1" == "${flag_}" ]]; then
			echo -e "Panic: Can't found file ${__APPOINT_F__}"
			return 1
		fi
	fi

	if [[ "on" == "${__STATIC__}" ]]; then
		clang -std="${__STD__}" -static "${C_SRC_FILES[@]}" -o "${DIRF}/${BINF}"
	else
		clang -std="${__STD__}" "${C_SRC_FILES[@]}" -o "${DIRF}/${BINF}"
	fi

	ret="${?}"

	if [[ 0 == "${ret}" ]]; then
		bin/pubbin
	else
		echo -e "Panic: run bin/pubbin failed !"
	fi
}

#######################################
# Parse arguments, then compile and run the sources.
# Globals:
#   FLAG
# Arguments:
#   $@: program options forwarded to parser.
# Outputs:
#   Writes status and error messages to stdout.
# Returns:
#   0 on success, 1 if argument parsing fails.
#######################################
function main() {
	parser "${@}"

	if [[ $FLAG -ne 0 ]]; then
		echo -e "Error: Current is uncompiliable qualification"
		return 1
	fi

	runc
	return 0
}

main "${@}"

exit 0 # This is expected exit status '--contract-exit'
