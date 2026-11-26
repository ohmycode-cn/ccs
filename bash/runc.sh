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

# Compile C source files with the selected compiler and run the resulting binary.

if [[ "${0}" != "${BASH_SOURCE[0]}" ]]; then
	echo -e "ERROR: Usage: bash runc.sh [flag] (options)"
	return 1 &>/dev/null
fi

__BIN_NAME__="pubbin"
__BIN_DIR__="bin"
__SRC_FILES__=()
__PARSE_STATUS__=1
__EDIT_FILE__="nof"
__STATIC_LINK__="off"
__EDIT_MODE__="off"
__C_STD__="c23"
__COMPILER__="clang"
__CMP_LIST__=(
	"clang"
	"clang++"
	"g++"
	"gcc"
)

###############################################################################
# __START:
# ANSI highlight constant value definition zone
# Define: 
# reset, black, red, green, yellow, blue, purple, cyan, white

__ANSI_ESC__="\033"
__ANSI_PREFIX__="[0;"
__ANSI_SUFFIX__="m"

readonly __ANSI_ESC__
readonly __ANSI_PREFIX__
readonly __ANSI_SUFFIX__

__RESET__="${__ANSI_ESC__}${__ANSI_PREFIX__}0${__ANSI_SUFFIX__}"
__BLACK__="${__ANSI_ESC__}${__ANSI_PREFIX__}30${__ANSI_SUFFIX__}"
__RED__="${__ANSI_ESC__}${__ANSI_PREFIX__}31${__ANSI_SUFFIX__}"
__GREEN__="${__ANSI_ESC__}${__ANSI_PREFIX__}32${__ANSI_SUFFIX__}"
__YELLOW__="${__ANSI_ESC__}${__ANSI_PREFIX__}33${__ANSI_SUFFIX__}"
__BLUE__="${__ANSI_ESC__}${__ANSI_PREFIX__}34${__ANSI_SUFFIX__}"
__PURPLE__="${__ANSI_ESC__}${__ANSI_PREFIX__}35${__ANSI_SUFFIX__}"
__CYAN__="${__ANSI_ESC__}${__ANSI_PREFIX__}36${__ANSI_SUFFIX__}"
__WHITE__="${__ANSI_ESC__}${__ANSI_PREFIX__}37${__ANSI_SUFFIX__}"

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
#Define: constant -> message levels
#        INFO, ERROR, DONE, PANIC

#IO Stream controller
__IO_LOG_FILE__="$(pwd)/iofile.txt"
__IO_LOG_ENABLED__="false"

#######################################
# Emit an INFO-level message with optional ANSI coloring and log-file write.
# Globals:
#   __IO_LOG_ENABLED__
#   __IO_LOG_FILE__
#   __GREEN__
#   __CYAN__
#   __RESET__
# Arguments:
#   $@: --color, --stder, --msgio <text>
# Outputs:
#   Writes "INFO : <text>" to stdout, or to stderr with --stder.
#   Appends a plain line to $__IO_LOG_FILE__ when $__IO_LOG_ENABLED__ is "true".
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

	if [[ "true" == "${__IO_LOG_ENABLED__}" ]]; then
		echo -e "INFO : ${msgio}" >> "${__IO_LOG_FILE__}"
	fi
}

#######################################
# Emit an ERROR-level message with optional ANSI coloring and log-file write.
# Globals:
#   __IO_LOG_ENABLED__
#   __IO_LOG_FILE__
#   __RED__
#   __YELLOW__
#   __RESET__
# Arguments:
#   $@: --color, --stder, --msgio <text>
# Outputs:
#   Writes "ERROR: <text>" to stdout, or to stderr with --stder.
#   Appends a plain line to $__IO_LOG_FILE__ when $__IO_LOG_ENABLED__ is "true".
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

	if [[ "true" == "${__IO_LOG_ENABLED__}" ]]; then
		echo -e "ERROR: ${msgio}" >> "${__IO_LOG_FILE__}"
	fi
}

#######################################
# Emit a PANIC-level message with optional ANSI coloring and log-file write.
# Globals:
#   __IO_LOG_ENABLED__
#   __IO_LOG_FILE__
#   __PURPLE__
#   __RED__
#   __RESET__
# Arguments:
#   $@: --color, --stder, --msgio <text>
# Outputs:
#   Writes "PANIC: <text>" to stdout, or to stderr with --stder.
#   Appends a plain line to $__IO_LOG_FILE__ when $__IO_LOG_ENABLED__ is "true".
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

	if [[ "true" == "${__IO_LOG_ENABLED__}" ]]; then
		echo -e "PANIC: ${msgio}" >> "${__IO_LOG_FILE__}"
	fi
}

#######################################
# Emit a DONE-level message with optional ANSI coloring and log-file write.
# Globals:
#   __IO_LOG_ENABLED__
#   __IO_LOG_FILE__
#   __BLUE__
#   __GREEN__
#   __RESET__
# Arguments:
#   $@: --color, --stder, --msgio <text>
# Outputs:
#   Writes "DONE : <text>" to stdout, or to stderr with --stder.
#   Appends a plain line to $__IO_LOG_FILE__ when $__IO_LOG_ENABLED__ is "true".
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

	if [[ "true" == "${__IO_LOG_ENABLED__}" ]]; then
		echo -e "DONE : ${msgio}" >> "${__IO_LOG_FILE__}"
	fi
}

#######################################
# Emit a continuation message (indented, no level tag) with optional body
# coloring and log-file write.
# Globals:
#   __IO_LOG_ENABLED__
#   __IO_LOG_FILE__
#   __BLACK__
#   __RED__
#   __GREEN__
#   __YELLOW__
#   __BLUE__
#   __PURPLE__
#   __CYAN__
#   __WHITE__
#   __RESET__
# Arguments:
#   $@: --color [black|red|green|yellow|blue|purple|cyan|white],
#       --stder, --msgio <text>
# Outputs:
#   Writes "       <text>" to stdout, or to stderr with --stder.
#   Appends a plain line to $__IO_LOG_FILE__ when $__IO_LOG_ENABLED__ is "true".
#######################################
function io_continue() {
	local color="false"
	local stder="false"
	local nasi_="none"
	local msgio=""
	while (( $# > 0 )); do
		case "${1}" in
			--color)
				if (( $# >= 2 )) && [[ "${2}" != -* ]]; then
					shift
					nasi_="${1}"
				fi
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

	local pfx_bc=""
	local set_re=""

	if [[ "true" == "${color}" ]]; then
		set_re="${__RESET__}"
		case "${nasi_}" in
			"black")
				pfx_bc="${__BLACK__}"
				;;
			"red")
				pfx_bc="${__RED__}"
				;;
			"green")
				pfx_bc="${__GREEN__}"
				;;
			"yellow")
				pfx_bc="${__YELLOW__}"
				;;
			"blue")
				pfx_bc="${__BLUE__}"
				;;
			"purple")
				pfx_bc="${__PURPLE__}"
				;;
			"cyan")
				pfx_bc="${__CYAN__}"
				;;
			"white")
				pfx_bc="${__WHITE__}"
				;;
			*)
				pfx_bc=""
				;;
		esac
	fi

	if [[ "false" == "${stder}" ]]; then
		# io out -> stdout
		echo -e "       ${pfx_bc}${msgio}${set_re}"
	else
		# io out -> stderr
		echo -e "       ${pfx_bc}${msgio}${set_re}" >&2
	fi

	if [[ "true" == "${__IO_LOG_ENABLED__}" ]]; then
		echo -e "       ${msgio}" >> "${__IO_LOG_FILE__}"
	fi
}

#######################################
# Emit a plain message line with optional purple ANSI coloring.
# Globals:
#   __PURPLE__
#   __RESET__
# Arguments:
#   $1: "true" to colorize, any other value prints plain.
#   $2: message text.
# Outputs:
#   Writes "<text>" to stdout, purple when $1 is "true".
#######################################
function ifmt() {
	local color="${1}"
	local msgio="${2}"
	if [[ "true" == "${color}" ]]; then
		echo -e "${__PURPLE__}${msgio}${__RESET__}"
	else
		echo -e "${msgio}"
	fi
}

#######################################
# Print the help document with flags, example and output note.
# Globals:
#   __BIN_DIR__
#   __BIN_NAME__
# Arguments:
#   None
# Outputs:
#   Writes the help document to stdout via io_info and ifmt.
#######################################
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
	ifmt "${color}" "  --compile, --cmp        Select the compiler: clang|clang++|gcc|g++ (default: clang)"
	ifmt "${color}" "  --edit, --e [file]     Open [file] (or the first source) in nvim before build"
	ifmt "${color}" "  --iofile, --iof        Write a plain log to ./iofile.txt"
	ifmt "${color}" "  --help                 Show this help document"
	ifmt "${color}" ""
	ifmt "${color}" "Example: bash runc.sh --file main.c --std 23 --edit main.c"
	ifmt "${color}" ""
	ifmt "${color}" "Output : ${__BIN_DIR__}/${__BIN_NAME__}"
	ifmt "${color}" "Note   : ${__BIN_DIR__}/ must exist beforehand; the script never creates it"
}

#######################################
# Parse command-line arguments into global compile settings.
# Globals:
#   __SRC_FILES__
#   __PARSE_STATUS__
#   __STATIC_LINK__
#   __C_STD__
#   __COMPILER__
#   __EDIT_MODE__
#   __EDIT_FILE__
#   __IO_LOG_ENABLED__
#   __IO_LOG_FILE__
# Arguments:
#   $@: --file/--f <src>..., --static on|off, --std 99|11|17|18|23,
#       --edit/--e (file), --iofile/--iof, --compile/--cmp (name)
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
					__SRC_FILES__+=("${1}")
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
					io_error --color --msgio "--static ?, ?:{off/on}. But you provided ${1}"
					return 1
				else
					__STATIC_LINK__="${1}"
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
					io_error --color --msgio "--std ?, ?:{99,11,17,18,23}. But you provided ${1}"
					return 1;
				else
					case "${1}" in
						"99")
							__C_STD__="c99"
							;;
						"11")
							__C_STD__="c11"
							;;
						"17")
							__C_STD__="c17"
							;;
						"18")
							__C_STD__="c18"
							;;
						"*")
							__C_STD__="c23"
							;;
						esac
					shift
				fi
				;; 
			--edit | --e)
				if (( $# >= 2 )) && [[ "${2}" != -* ]]; then
					shift
					__EDIT_FILE__="${1}"
				fi
				__EDIT_MODE__="on"
				shift
				;;
			--iofile | --iof)
				__IO_LOG_ENABLED__="true"
				echo "" > "${__IO_LOG_FILE__}" # clean last log.
				shift
				;;
			--help)
				shift
				help_doc
				__PARSE_STATUS__=2
				return 1
				;;
			--compile | --cmp)
				if (( $# >= 2 )) && [[ "${2}" != -* ]]; then
					shift
					__COMPILER__="${1}"
				fi
				shift
				;;
			*)
				io_panic --color --msgio "Unknown parameter :("
				__PARSE_STATUS__=1
				return 1
			;;
	    esac
	done
	io_info --color --msgio "Current compiler: '${__COMPILER__}'"
	io_done --color --msgio "edit file: ${__EDIT_FILE__}"
	io_done --color --msgio "settings : {compilation-std:${__C_STD__}}"
	if (( ${#__SRC_FILES__} == 0 )); then
		io_error --color --msgio "You must provide a compilable C file :( !"
		__PARSE_STATUS__=1
		return 1
	fi
	__PARSE_STATUS__=0
}

#######################################
# Compile the collected C sources with the selected compiler and run the binary.
# Globals:
#   __BIN_NAME__
#   __BIN_DIR__
#   __SRC_FILES__
#   __STATIC_LINK__
#   __C_STD__
#   __EDIT_MODE__
#   __EDIT_FILE__
#   __COMPILER__
#   __CMP_LIST__
# Arguments:
#   None
# Outputs:
#   Writes progress messages and program output to stdout.
#######################################
function runc() {
	io_info --color --msgio "Running compile ..."

	local ret

	if [[ "on" == "${__EDIT_MODE__}" && "nof" == "${__EDIT_FILE__}" ]]; then
		nvim "${__SRC_FILES__[0]}"
	elif [[ "on" == "${__EDIT_MODE__}" && "nof" != "${__EDIT_FILE__}" ]]; then
		local flag_=1
		for f in "${__SRC_FILES__[@]}"; do
			if cmp -s "${__EDIT_FILE__}" "${f}"; then
				flag_=0
				nvim "${__EDIT_FILE__}"
			fi
		done
		if [[ "1" == "${flag_}" ]]; then
			io_panic --color --msgio "Can't find file ${__EDIT_FILE__}"
			return 1
		fi
	fi

	local exec_cmp="false"
	for i in "${__CMP_LIST__[@]}"; do
		if [[ "${i}" == "${__COMPILER__}" ]]; then
			exec_cmp="true"
			break
		fi
	done

	if [[ "false" == "${exec_cmp}" ]]; then
		io_panic --color --msgio "Unknown compiler '${__COMPILER__}' :( !"
		io_continue --color --msgio "Run 'bash runc.sh --help' to get more help"
		return 1
	fi

	if [[ "on" == "${__STATIC_LINK__}" ]]; then
		"${__COMPILER__}" -std="${__C_STD__}" -static "${__SRC_FILES__[@]}" -o "${__BIN_DIR__}/${__BIN_NAME__}"
	else
		"${__COMPILER__}" -std="${__C_STD__}" "${__SRC_FILES__[@]}" -o "${__BIN_DIR__}/${__BIN_NAME__}"
	fi

	ret="${?}"

	if [[ 0 == "${ret}" ]]; then
		"${__BIN_DIR__}/${__BIN_NAME__}"
	else
		io_panic --color --msgio "Running ${__BIN_DIR__}/${__BIN_NAME__} failed !"
	fi
}

#######################################
# Parse arguments, then compile and run the sources.
# Globals:
#   __PARSE_STATUS__
# Arguments:
#   $@: program options forwarded to parser.
# Outputs:
#   Writes status and error messages to stdout.
# Returns:
#   0 on success, 1 if argument parsing fails.
#######################################
function main() {
	if (( $# == 0 )); then
		io_panic --color --msgio "You must provide at least one parameter"
		io_continue --color "red" --msgio "You can run 'bash runc.sh --help' to get more help"
		return 1
	fi

	parser "${@}"

	if [[ $__PARSE_STATUS__ -eq 2 ]]; then
		# If runc.sh --help ...... exit 0
		return 1
	fi

	if [[ $__PARSE_STATUS__ -ne 0 ]]; then
		io_error --color --msgio "Current configuration is not compilable"
		return 1
	fi

	runc
	return 0
}

main "${@}"

exit 0 # This is the expected exit status '--contract-exit'
