#!/bin/bash

# *****************************************************************************
# * Author     : ohmycode-cn
# * Email      : ohcode@163.com
# * Date       : 2026-11-23
# * Language   : bash
# * Standard   : bash 5.0 or higher
# * License    : MIT (see LICENSE for the additional terms)
# * Description:
# *   A quick edit/compile helper for a single C/C++ source file, or for
# *   a small set of files. The output binary is always `pubbin` ("Public
# *   Binary"), written to `bin/` at the project root. The script never
# *   creates `bin/` itself: if the directory is absent, compilation is
# *   skipped. ANSI highlighting is disabled by default so that logs stay
# *   traceable. To keep the calling shell clean, everything runs in a
# *   subshell, and the script always ends with `exit 0`, no matter
# *   whether the compiled program succeeds.
# *****************************************************************************

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

###############################################################################
# __START:
# ANSI highlight constant value define zone
# Define: 
# reset, black, red, green, yellow, blue, purple, cyan, white

__ANSI__="\033"
__FONT__="[0;"
__CHAR__="m"

readonly __ANSI__
readonly __FONT__
readonly __CHAR__

__RESET__="${__ANSI__}${__FONT__}0${__CHAR__}"
__BLACK__="${__ANSI__}${__FONT__}30${__CHAR__}"
__RED__="${__ANSI__}${__FONT__}31${__CHAR__}"
__GREEN__="${__ANSI__}${__FONT__}32${__CHAR__}"
__YELLOW__="${__ANSI__}${__FONT__}33${__CHAR__}"
__BLUE__="${__ANSI__}${__FONT__}34${__CHAR__}"
__PURPLE__="${__ANSI__}${__FONT__}35${__CHAR__}"
__CYAN__="${__ANSI__}${__FONT__}36${__CHAR__}"
__WHITE__="${__ANSI__}${__FONT__}37${__CHAR__}"

readonly __RESET__
readonly __BLACK__
readonly __RED__
readonly __GREEN__
readonly __YELLOW__
readonly __BLUE__
readonly __PURPLE__
readonly __CYAN__
readonly __WHITE__

# __ENDOF;
###############################################################################

##############################################################################
#__START:
#Define: constant -> messages level
#        INFO, ERROR, DONE, PANIC

#IO Stream controller
__IO_FILE__="$(pwd)/iofile.txt"
__IO_TURN__="false"

#######################################
# Emit an INFO-level message with optional ANSI coloring and log-file write.
# Globals:
#   __IO_TURN__
#   __IO_FILE__
#   __GREEN__
#   __CYAN__
#   __RESET__
# Arguments:
#   $@: --color, --stder, --msgio <text>
# Outputs:
#   Writes "INFO : <text>" to stdout, or to stderr with --stder.
#   Appends a plain line to $__IO_FILE__ when $__IO_TURN__ is "true".
#######################################
function io_info() {
	local color="false"
	local stder="false"
	local msgio=""
	while (( $# > 0 )); do
		case "${1}" in
			--color)
				shift
				color="true"
				;;
			--stder)
				shift
				stder="true"
				;;
			--msgio)
				shift
				msgio="${1}"
				shift
				;;
			*)
				echo -e "Inner Error: Unknown parameter type '?' for '${1}'"
				shift
				;;
		esac
	done

	local pfx_hc=""
	local pfx_bc=""
	local set_re=""

	if [[ "true" == "${color}" ]]; then
		pfx_hc="${__GREEN__}"
		pfx_bc="${__CYAN__}"
		set_re="${__RESET__}"
	fi

	if [[ "false" == "${stder}" ]]; then
		# io out -> stdout
		echo -e "${pfx_hc}INFO ${set_re}: ${pfx_bc}${msgio}${set_re}"
	else
		# io out -> stderr
		echo -e "${pfx_hc}INFO ${set_re}: ${pfx_bc}${msgio}${set_re}" >&2
	fi

	if [[ "true" == "${__IO_TURN__}" ]]; then
		echo -e "INFO : ${msgio}" >> "${__IO_FILE__}"
	fi
}

#######################################
# Emit an ERROR-level message with optional ANSI coloring and log-file write.
# Globals:
#   __IO_TURN__
#   __IO_FILE__
#   __RED__
#   __YELLOW__
#   __RESET__
# Arguments:
#   $@: --color, --stder, --msgio <text>
# Outputs:
#   Writes "ERROR: <text>" to stdout, or to stderr with --stder.
#   Appends a plain line to $__IO_FILE__ when $__IO_TURN__ is "true".
#######################################
function io_error() {
	local color="false"
	local stder="false"
	local msgio=""
	while (( $# > 0 )); do
		case "${1}" in
			--color)
				shift
				color="true"
				;;
			--stder)
				shift
				stder="true"
				;;
			--msgio)
				shift
				msgio="${1}"
				shift
				;;
			*)
				echo -e "Inner Error: Unknown parameter type '?' for '${1}'"
				shift
				;;
		esac
	done

	local pfx_hc=""
	local pfx_bc=""
	local set_re=""

	if [[ "true" == "${color}" ]]; then
		pfx_hc="${__RED__}"
		pfx_bc="${__YELLOW__}"
		set_re="${__RESET__}"
	fi

	if [[ "false" == "${stder}" ]]; then
		# io out -> stdout
		echo -e "${pfx_hc}ERROR${set_re}: ${pfx_bc}${msgio}${set_re}"
	else
		# io out -> stderr
		echo -e "${pfx_hc}ERROR${set_re}: ${pfx_bc}${msgio}${set_re}" >&2
	fi

	if [[ "true" == "${__IO_TURN__}" ]]; then
		echo -e "ERROR: ${msgio}" >> "${__IO_FILE__}"
	fi
}

#######################################
# Emit a PANIC-level message with optional ANSI coloring and log-file write.
# Globals:
#   __IO_TURN__
#   __IO_FILE__
#   __PURPLE__
#   __RED__
#   __RESET__
# Arguments:
#   $@: --color, --stder, --msgio <text>
# Outputs:
#   Writes "PANIC: <text>" to stdout, or to stderr with --stder.
#   Appends a plain line to $__IO_FILE__ when $__IO_TURN__ is "true".
#######################################
function io_panic() {
	local color="false"
	local stder="false"
	local msgio=""
	while (( $# > 0 )); do
		case "${1}" in
			--color)
				shift
				color="true"
				;;
			--stder)
				shift
				stder="true"
				;;
			--msgio)
				shift
				msgio="${1}"
				shift
				;;
			*)
				echo -e "Inner Error: Unknown parameter type '?' for '${1}'"
				shift
				;;
		esac
	done

	local pfx_hc=""
	local pfx_bc=""
	local set_re=""

	if [[ "true" == "${color}" ]]; then
		pfx_hc="${__PURPLE__}"
		pfx_bc="${__RED__}"
		set_re="${__RESET__}"
	fi

	if [[ "false" == "${stder}" ]]; then
		# io out -> stdout
		echo -e "${pfx_hc}PANIC${set_re}: ${pfx_bc}${msgio}${set_re}"
	else
		# io out -> stderr
		echo -e "${pfx_hc}PANIC${set_re}: ${pfx_bc}${msgio}${set_re}" >&2
	fi

	if [[ "true" == "${__IO_TURN__}" ]]; then
		echo -e "PANIC: ${msgio}" >> "${__IO_FILE__}"
	fi
}

#######################################
# Emit a DONE-level message with optional ANSI coloring and log-file write.
# Globals:
#   __IO_TURN__
#   __IO_FILE__
#   __BLUE__
#   __GREEN__
#   __RESET__
# Arguments:
#   $@: --color, --stder, --msgio <text>
# Outputs:
#   Writes "DONE : <text>" to stdout, or to stderr with --stder.
#   Appends a plain line to $__IO_FILE__ when $__IO_TURN__ is "true".
#######################################
function io_done() {
	local color="false"
	local stder="false"
	local msgio=""
	while (( $# > 0 )); do
		case "${1}" in
			--color)
				shift
				color="true"
				;;
			--stder)
				shift
				stder="true"
				;;
			--msgio)
				shift
				msgio="${1}"
				shift
				;;
			*)
				echo -e "Inner Error: Unknown parameter type '?' for '${1}'"
				shift
				;;
		esac
	done

	local pfx_hc=""
	local pfx_bc=""
	local set_re=""

	if [[ "true" == "${color}" ]]; then
		pfx_hc="${__BLUE__}"
		pfx_bc="${__GREEN__}"
		set_re="${__RESET__}"
	fi

	if [[ "false" == "${stder}" ]]; then
		# io out -> stdout
		echo -e "${pfx_hc}DONE ${set_re}: ${pfx_bc}${msgio}${set_re}"
	else
		# io out -> stderr
		echo -e "${pfx_hc}DONE ${set_re}: ${pfx_bc}${msgio}${set_re}" >&2
	fi

	if [[ "true" == "${__IO_TURN__}" ]]; then
		echo -e "DONE : ${msgio}" >> "${__IO_FILE__}"
	fi
}

function ifmt() {
	local color="${1}"
	local msgio="${2}"
	if [[ "true" == "${color}" ]]; then
		echo -e "${__PURPLE__}${msgio}${__RESET__}"
	else
		echo -e "${msgio}"
	fi
}

function help_doc() {
	io_info --color --msgio "WELCOME TO RUNC.SH HELP DOC"
	local color="true"
	ifmt "${color}" ""
	ifmt "${color}" "Usage: bash runc.sh [flag] (options)"
	ifmt "${color}" ""
	ifmt "${color}" "Flags:"
	ifmt "${color}" "  --file, --f <src>...   Collect C source files to compile and run"
	ifmt "${color}" "  --static on|off        Toggle static linking (default: off)"
	ifmt "${color}" "  --std 99|11|17|18|23   Select the C standard (default: 23)"
	ifmt "${color}" "  --edit, --e [file]     Open [file] (or the first source) in nvim before build"
	ifmt "${color}" "  --iofile, --iof        Write a plain log to ./iofile.txt"
	ifmt "${color}" "  --help                 Show this help document"
	ifmt "${color}" ""
	ifmt "${color}" "Example: bash runc.sh --file main.c --std 23 --edit main.c"
	ifmt "${color}" ""
	ifmt "${color}" "Output : ${__DIRF__}/${__BINF__}"
	ifmt "${color}" "Note   : ${__DIRF__}/ must exist beforehand, the script never creates it"
}

#######################################
# Parse command-line arguments into global compile settings.
# Globals:
#   __FILE__
#   __FLAG__
#   __STATIC__
#   __STD__
#   __EDIT__
#   __APPOINT_F__
#   __IO_TURN__
#   __IO_FILE__
# Arguments:
#   $@: --file/--f <src>..., --static on|off, --std 99|11|17|18|23,
#       --edit/--e (file), --iofile/--iof
# Outputs:
#   Writes status and error messages to stdout.
# Returns:
#   0 on success, 1 on invalid arguments.
#######################################
function parser() {
	io_info --color --msgio "Parser start"
	while (( $# > 0 )); do
		case "${1}" in 
			--file | --f)
				shift
				if (( $# == 0 )) || [[ "${1}" == -* ]]; then
					io_error --color --msgio "At least one actual argument for --file/--f must be provided"
					return 1
				fi
				while (( $# > 0 )) && [[ "${1}" != -* ]]; do
					__FILE__+=("${1}")
					shift
				done
				;;
			--static)
				if (( $# < 2 )); then
					io_error --color --msgio "--static ?, ?:{off/on}"
					return 1
				fi
				shift
				if [[ "${1}" != "on" && "${1}" != "off" ]]; then
					io_error --color --msgio "--static ?, ?:{off/on}. But you provided is ${1}"
					return 1
				else
					__STATIC__="${1}"
					shift
				fi
				;;
			--std)
				if (( $# < 2 )); then
					io_error --color --msgio "--std ?, ?:{99,11,17,18,23}"
					return 1
				fi
				shift
				if [[ "${1}" != "99" && "${1}" != "11" && "${1}" != "17" ]] && [[ "${1}" != "18" && "${1}" != "23" ]]; then
					io_error --color --msgio "-std ?, ?:{99,11,17,18,23}. But you provided is ${1}"
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
				if (( $# >= 2 )) && [[ "${2}" != -* ]]; then
					shift
					__APPOINT_F__="${1}"
				fi
				__EDIT__="on"
				shift
				;;
			--iofile | --iof)
				__IO_TURN__="true"
				echo "" > "${__IO_FILE__}" # clean last log.
				shift
				;;
			--help)
				shift
				help_doc
				__FLAG__=2
				return 1
				;;
			*)
				io_panic --color --msgio "Unknown parameter :("
				__FLAG__=1
				return 1
			;;
	    esac
	done
	__FLAG__=0
	io_done --color --msgio "settings: {compilation-std:${__STD__}}"
}

#######################################
# Compile the collected C sources with clang and run the binary.
# Globals:
#   __BINF__
#   __DIRF__
#   __FILE__
#   __STATIC__
#   __STD__
#   __EDIT__
#   __APPOINT_F__
# Arguments:
#   None
# Outputs:
#   Writes progress messages and program output to stdout.
#######################################
function runc() {
	io_info --color --msgio "Running compile ..."

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
			io_panic --color --msgio "Can't found file ${__APPOINT_F__}"
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
		io_panic --color --msgio "Run ${__DIRF__}/${__BINF__} failed !"
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

	if [[ $__FLAG__ -eq 2 ]]; then
		# If runc.sh --help ...... exit 0
		return 1
	fi

	if [[ $__FLAG__ -ne 0 ]]; then
		io_error --color --msgio "Current is uncompiliable qualification"
		return 1
	fi

	runc
	return 0
}

main "${@}"

exit 0 # This is expected exit status '--contract-exit'
