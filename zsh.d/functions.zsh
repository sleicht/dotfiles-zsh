#!/usr/bin/env zsh

# `functions.zsh` provides helper functions for shell.


# === Commonly used functions ===

pyclean () {
  # Cleans py[cod] and cache dirs in the current tree:
  fd -I -H \
    '(__pycache__|\.(pytest_|mypy_)?cache|\.hypothesis\.py[cod]$)' \
  | xargs rm -rf
}


mc () {
  if [ $# -ne 1 ]; then
    echo 'usage: mc <dir-name>'
    return 137
  fi
  # Create a new directory and enter it
  local dir_name="$1"
  mkdir -p "$dir_name" && cd "$dir_name"
}


# Create a new directory and enter it
function mkd() {
	mkdir -p "$@" && cd "$_" || return;
}

# Change working directory to the top-most Finder window location
function cdf() { # short for `cdfinder`
	cd "$(osascript -e 'tell app "Finder" to POSIX path of (insertion location as alias)')" || return;
}

# Create a .tar.gz archive, using `zopfli`, `pigz` or `gzip` for compression
function targz() {
	local tmpFile="${*%/}.tar";
	tar -cvf "${tmpFile}" --exclude=".DS_Store" "${@}" || return 1;

	size=$(
		stat -f"%z" "${tmpFile}" 2> /dev/null; # macOS `stat`
		stat -c"%s" "${tmpFile}" 2> /dev/null;  # GNU `stat`
	);

	local cmd="";
	if (( size < 52428800 )) && hash zopfli 2> /dev/null; then
		# the .tar file is smaller than 50 MB and Zopfli is available; use it
		cmd="zopfli";
	else
		if hash pigz 2> /dev/null; then
			cmd="pigz";
		else
			cmd="gzip";
		fi;
	fi;

	echo "Compressing .tar ($((size / 1000)) kB) using \`${cmd}\`…";
	"${cmd}" -v "${tmpFile}" || return 1;
	[ -f "${tmpFile}" ] && rm "${tmpFile}";

	zippedSize=$(
		stat -f"%z" "${tmpFile}.gz" 2> /dev/null; # macOS `stat`
		stat -c"%s" "${tmpFile}.gz" 2> /dev/null; # GNU `stat`
	);

	echo "${tmpFile}.gz ($((zippedSize / 1000)) kB) created successfully.";
}

# Determine size of a file or total size of a directory
function fs() {
	if du -b /dev/null > /dev/null 2>&1; then
		local arg=-sbh;
	else
		local arg=-sh;
	fi
	if [[ -n "$*" ]]; then
		du $arg -- "$@";
	else
		du $arg .[^.]* ./*;
	fi;
}

# Use Git’s colored diff when available
if hash git &>/dev/null; then
	function diff() {
		git diff --no-index --color-words "$@";
	}
fi;

# Create a data URL from a file
function dataurl() {
	local mimeType;
	mimeType=$(file -b --mime-type "$1");
	if [[ $mimeType == text/* ]]; then
		mimeType="${mimeType};charset=utf-8";
	fi
	echo "data:${mimeType};base64,$(openssl base64 -in "$1" | tr -d '\n')";
}

# Start an HTTP server from a directory, optionally specifying the port
function server() {
	local port="${1:-8000}";
	sleep 1 && open "http://localhost:${port}/" &
	# Set the default Content-Type to `text/plain` instead of `application/octet-stream`
	# And serve everything as UTF-8 (although not technically correct, this doesn’t break anything for binary files)
	python -c $'import SimpleHTTPServer;\nmap = SimpleHTTPServer.SimpleHTTPRequestHandler.extensions_map;\nmap[""] = "text/plain";\nfor key, value in map.items():\n\tmap[key] = value + ";charset=UTF-8";\nSimpleHTTPServer.test();' "$port";
}

# Start a PHP server from a directory, optionally specifying the port
# (Requires PHP 5.4.0+.)
function phpserver() {
	local port, ip;
	port="${1:-4000}";
	ip=$(ipconfig getifaddr en1);
	sleep 1 && open "http://${ip}:${port}/" &
	php -S "${ip}:${port}";
}

# Compare original and gzipped file size
function gz() {
	local origsize, gzipsize, ratio;
	origsize=$(wc -c < "$1");
	gzipsize=$(gzip -c "$1" | wc -c);
	ratio=$(echo "$gzipsize * 100 / $origsize" | bc -l);
	printf "orig: %d bytes\n" "$origsize";
	printf "gzip: %d bytes (%2.2f%%)\n" "$gzipsize" "$ratio";
}

# Run `dig` and display the most useful info
function digga() {
	dig +nocmd "$1" any +multiline +noall +answer;
}

# Show all the names (CNs and SANs) listed in the SSL certificate
# for a given domain
function getcertnames() {
	if [ -z "${1}" ]; then
		echo "ERROR: No domain specified.";
		return 1;
	fi;

	local domain, tmp, certText;

	domain="${1}";
	echo "Testing ${domain}…";
	echo ""; # newline

	tmp=$(echo -e "GET / HTTP/1.0\nEOT" \
		| openssl s_client -connect "${domain}:443" -servername "${domain}" 2>&1);

	if [[ "${tmp}" = *"-----BEGIN CERTIFICATE-----"* ]]; then
		certText=$(echo "${tmp}" \
			| openssl x509 -text -certopt "no_aux, no_header, no_issuer, no_pubkey, \
			no_serial, no_sigdump, no_signame, no_validity, no_version");
		echo "Common Name:";
		echo ""; # newline
		echo "${certText}" | grep "Subject:" | sed -e "s/^.*CN=//" | sed -e "s/\/emailAddress=.*//";
		echo ""; # newline
		echo "Subject Alternative Name(s):";
		echo ""; # newline
		echo "${certText}" | grep -A 1 "Subject Alternative Name:" \
			| sed -e "2s/DNS://g" -e "s/ //g" | tr "," "\n" | tail -n +2;
		return 0;
	else
		echo "ERROR: Certificate not found.";
		return 1;
	fi;
}

# Normalize `open` across Linux, macOS, and Windows.
# This is needed to make the `o` function (see below) cross-platform.
if [ ! "$(uname -s)" = 'Darwin' ]; then
	if grep -q Microsoft /proc/version; then
		# Ubuntu on Windows using the Linux subsystem
		alias open='explorer.exe';
	else
		alias open='xdg-open';
	fi
fi

# `o` with no arguments opens the current directory, otherwise opens the given
# location
function o() {
	if [ $# -eq 0 ]; then
		open .;
	else
		open "$@";
	fi;
}

# `tre` is a shorthand for `tree` with hidden files and color enabled, ignoring
# the `.git` directory, listing directories first. The output gets piped into
# `less` with options to preserve color and line numbers, unless the output is
# small enough for one screen.
function tre() {
	tree -aC -I '.git|node_modules|bower_components' --dirsfirst "$@" | less -FRNX;
}

#
# Functions Work in Progress (WIP)
# (sorted alphabetically by function name)
# (order should follow README)
#

# Similar to `gunwip` but recursive "Unwips" all recent `--wip--` commits not just the last one
function gunwipall() {
  _commit=$(git log --grep='--wip--' --invert-grep --max-count=1 --format=format:%H)
	local _commit

  # Check if a commit without "--wip--" was found and it's not the same as HEAD
  if [[ "$_commit" != "$(git rev-parse HEAD)" ]]; then
    git reset "$_commit" || return 1
  fi
}

# Warn if the current branch is a WIP
function work_in_progress() {
  command git -c log.showSignature=false log -n 1 2>/dev/null | grep -q -- "--wip--" && echo "WIP!!"
}

# This script was automatically generated by the broot program
# More information can be found in https://github.com/Canop/broot
# This function starts broot and executes the command
# it produces, if any.
# It's needed because some shell commands, like `cd`,
# have no useful effect if executed in a subshell.
function br {
    local cmd cmd_file code
    cmd_file=$(mktemp)
    if broot --outcmd "$cmd_file" "$@"; then
        cmd=$(<"$cmd_file")
        command rm -f "$cmd_file"
        eval "$cmd"
    else
        code=$?
        command rm -f "$cmd_file"
        return "$code"
    fi
}

load_gitlab_projects () {
  SEARCH=$1
  curl "https://gitlab.sanet17.ch/api/graphql?private_token=${GITLAB_TOKEN}" -H 'content-type: application/json' --compressed -s --data "{\"query\":\"{ projects(first: 100, search: \\\"$SEARCH\\\") { nodes { sshUrlToRepo fullPath }}}\"}"
}
clone_repo() {
  if [[ "$target_dir" == "." ]]; then
    git clone "$REPOS" "$REPO_NAME"
  else
    mkdir -p "$(dirname "$FULL_PATH")"
    git clone "$REPOS" "$FULL_PATH"
  fi
}
clone () {
  local target_dir="${2:-$GITLAB_BASE_PATH}"

  if [[ $1 == git"@"* ]]
  then
    REPOS=$1
  else
    REPOS=$(load_gitlab_projects "$1" | jq '.data.projects.nodes | .[] | .sshUrlToRepo' -r | fzf)
  fi

  REPO_PATH=$(echo "$REPOS" | sed 's/^.*://' | sed 's/\.git$//')
  REPO_NAME=$(basename "$REPO_PATH")

  if [[ "$target_dir" == "." ]]; then
    FULL_PATH="$(pwd)/$REPO_NAME"
    search_dir="$(pwd)"
  else
    FULL_PATH="$target_dir/$REPO_PATH"
    search_dir="$target_dir"
  fi

  if [ -n "$REPO_PATH" ]; then
    # Check if repository exists at the exact path
    if [ -d "$FULL_PATH" ]; then
      echo "Repository already exists at $FULL_PATH" >&2
    else
      # Define fzf options once to avoid duplication
      local fzf_opts="--select-1 --exit-0 --height=15 --prompt=\"Select existing repository: \""

      # Use fd/find and fzf to search for directories with the same name
      local existing_repo

      # Try to use fd if available (faster), fall back to find
      if command -v fd >/dev/null 2>&1; then
        existing_repo=$(fd -t d -H "^${REPO_NAME}$" "$search_dir" 2>/dev/null | eval "fzf $fzf_opts 2>/dev/null")
      else
        existing_repo=$(find "$search_dir" -type d -name "$REPO_NAME" 2>/dev/null | eval "fzf $fzf_opts 2>/dev/null")
      fi

      if [ -n "$existing_repo" ] && [ -d "$existing_repo/.git" ]; then
        # Found a valid git repository
        echo "Repository found at $existing_repo" >&2
        FULL_PATH="$existing_repo"
      else
        # No valid repository found, clone it
        clone_repo
      fi
    fi
    echo "$FULL_PATH"
    echo "$FULL_PATH" >&2
  fi
}
function ideaclone () {
  clone "$1" "$2" | xargs -r idea
}
function codeclone () {
  clone "$1" "$2" | xargs -r code
}
