#!/bin/bash
set -Euo pipefail
trap 'rm -rf -- "$TMPDIR"' EXIT
export TOP_PID=$$

TMPDIR="$(mktemp -d)"

RED='\e[0;31m'
YEL='\e[0;33m'
RCOL='\e[0m'
COLOREN=1

#!TODO add a warn flag

# empty string judgement strategy from this script are two methods
# [[ -z ${var// /} ]] # substitute space to empty and judge if it exist
# [[ ${var} =~ ^\s*$ ]] # judge if it's empty

ERROR() {
  if [[ -n "${2-}" ]]; then
    [[ -n "${COLOREN-}" ]] && printf "${YEL}"
    printf "ERR-TIPS: ${2-}\n" 1>&2
    [[ -n "${COLOREN-}" ]] && printf "${RCOL}"
  fi
  [[ -n "${COLOREN-}" ]] && printf "${RED}"
  printf "ERROR: ${1-} Script Aborting.\n" 1>&2
  [[ -n "${COLOREN-}" ]] && printf "${RCOL}"
  kill -s TERM $TOP_PID
}

WARN() {
  if [[ -z "${COLOREN-}" ]]; then
    printf "WARNING: ${1-}\n" 1>&2
  else
    printf "${YEL}WARNING: ${1-}${RCOL}\n" 1>&2
  fi
  return 1
}

question() {
  while [[ true ]]; do
    read -p "Are you sure? (Y/N):" -n 1 -r
    case "$REPLY" in
    Y | y)
      printf "\n"
      return 0
      ;;
    N | n)
      printf "\n"
      return 1
      ;;
    *) echo " Invalid Option.\n" ;;
    esac
  done
}

loadconfig() {
  local cpath="${EPATH%/*}/dotfiles.conf.sh"
  # the default conf
  conf='config_default_confirm=1 # whether prompt to confirm if default value apply to the missing settings
dotfile_basepath_src="$HOME/dotfile" # all the stuffs been placed, the default path prefix of genre src
dotfile_basepath_dst="$HOME" # the same as above
# the type of dotfiles should tracked by script
# dotfile_genre=("home" "other") 
dotfile_genre=("")

# example of genres, usage: g_[genre]_[setting]=[value]
# uncomment options below to enable it

# g_home_src_prefix="/" # use ${dotfile_bashpath} as prefix and is equivalent as "${dotfile_bashpath}/"
# g_home_files=("zshrc" "vimrc") # files list in src folder
# g_home_dst_prefix="/." # same as src, equivalent as "$HOME/"
# g_home_osonly=0 # 0 is disabled for OS specific, 1 is stand for LINUX only, 2 is stand for WINDOWS(cygwin/msys) only

# g_other_src_prefix="/script/" # just another config
# g_other_files("sync-dotfile")
# g_other_dst_prefix="/script/"
# g_other_osonly=1 # Linux only
  '
  eval "$conf" || ERROR "Your config maybe incompelete or has incorrect syntax, check it again."
  if [[ ! -e "$cpath" ]]; then
    WARN "Missing configuration file: automatically create one for you in \"$cpath\""
    echo "$conf" >"$cpath"
  fi
  . $cpath
}

# loadlib() {
#   local dir="${EPATH%/*}/libs"
#   for lib in "${config_lib_files[@]}"; do
#     local path="${dir}/${lib}.sh"
#     [[ ! -e $path ]] && ERROR "Unable to load library in \"${path}\""
#     . "${path}"
#   done
# }

check_env() {
  [[ "$#" -ne "1" ]] && ERROR "Invalid count of parameters."
  [[ "$1" != "Linux" && "$1" != "Windows" ]] && ERROR "\"$1\" is invalid name of OS"
  if [[ "$1" == "Linux" ]]; then
    MTAG=1
  else
    MTAG=2
  fi
}

judge_env() {
  case "$(uname -s)" in
  Linux*) MTAG=1 ;;
  CYGWIN* | MINGW* | MSYS*) MTAG=2 ;;
  *)
    WARN "OS can not be determined. Load from parameter (\"Windows\"/\"Linux\") alternatively."
    return 1
    ;;
  esac
  return 0
}

read_trace() {
  KEEPIT="${EPATH%/*}/.sync-dotfile.sh.keepit"
  if [[ ! -f "$KEEPIT" ]]; then
    [[ -e "$KEEPIT" ]] && rm $KEEPIT
    WARN "Tracing file does not exist and is being created now. You may the first time running this script, DO NOT remove the file \"$KEEPIT\"."
    FILEOLD=' '
    return 1
  fi
  while LFS= read -r line; do
    #!TODO Corrupt File
    [[ ! -z ${line// /} ]] && FILEOLD+=("$line")
  done <"$KEEPIT"
  return 0
}

if_link_correct() {
  local src=$1 dst=$2
  [[ $(realpath $dst) = $src ]]
}

link_correctly() {
  local src=$1 dst=$2 extinfo=" "
  # the check part is in check_and_enforce_to_queue()
  [[ -z ${src// /} ]] || [[ -z ${dst// /} ]] && return
  [[ ! -d ${dst%/*} ]] && { mkdir -p "${dst%/*}" || WARN "Can not mkdir at \"${dst%/*}\" for creating link, skipped" || return 1; }
  [[ ! ${dst%/*} = $(realpath ${dst%/*}) ]] && { WARN "!!Cautious!!: the realpath of destination \"${dst}\" is not the dest per se, you may try to put your source \"${src}\" into a endless recursive link. Check whether the dest path is under a linked folder. Skipped." || return 1; }
  [[ -e $dst ]] && { rm -r "$dst" || WARN "Can not remove dstfile \"${dst}\" for creating a new link, skipped" || return 1; }
  ln -s "$src" "$dst" || WARN "ln: Can not link from \"${src}\" to \"${dst}\", skipped it, consider following the issue bash points to." || return 1
  [[ -d $src ]] && extinfo+="folder "
  printf "[INFO] Link created from${extinfo}\"${src}\" to \"${dst}\"\n"
  return 0
}

oldlink_removal() {
  local osrc="$1" odst="$2" extinfo=" "
  if if_link_correct "$osrc" "$odst"; then
    rm -r "$odst"
    [[ -d $osrc ]] && extinfo+="folder "
    printf "[INFO] Link destoryed due to${extinfo}\"${odst}\" is removed from config\n"
  else
    WARN "Found a early deleted link from config, but do not correctly mapped from \"$osrc\" to \"$odst\", consider to remove it manually."
  fi
}

link_file() {
  # how to keep trace of configuration ?
  # file: sync-dotfile.sh.KEEPIT
  # structure: the path of links that has been created
  # method: construct a list form current config, sort it
  #         then compare it with the sorted keeping content
  #         and remove the deleted or append the missing that found.
  # begin
  local fok=0 once=0
  read_trace && fok=1
  IFS=$'\n' FILEOLD=($(sort <<<"${FILEOLD[*]}"))
  unset IFS
  IFS=$'\n' FILE=($(sort <<<"${FILE[*]}"))
  unset IFS
  # settings for OLDFILE
  declare -i count=0
  declare -i maxcount=${#FILEOLD[@]}
  [[ -z ${FILEOLD[@]// /} ]] && maxcount=0
  # settings for FILE
  declare -i amount="$((${#FILE[@]} - 1))"
  if [[ $amount -lt 0 ]]; then
    WARN "No file(s) has been found from your config."
    once=1
    amount=0
    FILE=' '
  fi
  [[ -z $KEEPIT ]] && ERROR "DO NOT REMOVE \"read_trace\" above this line, which \$KEEPIT variable rely on, or your edit it carefully."
  # remove KEEPIT
  [[ $fok -eq 1 ]] && { mv "$KEEPIT" "$KEEPIT.bk" || ERROR "Can not rename it, Check permission for \"$KEEPIT\"(or .bk) ?" || return 1; }
  local ldst=" "
  for i in $(seq 0 $amount); do
    local dst src
    read dst src <<<${FILE[$i]/\/\// }
    if [[ ! $dst = $ldst ]]; then
      while [[ $count -lt $maxcount ]]; do
        local odst osrc
        read odst osrc <<<${FILEOLD[$count]/\/\// }
        if [[ -z ${FILEOLD[$count]// /} ]]; then
          count+=1
        elif [[ $dst = $odst ]]; then
          [[ ! $src = $osrc ]] && oldlink_removal "$osrc" "$odst"
          count+=1
          break
        elif [[ $dst > $odst ]]; then
          oldlink_removal "$osrc" "$odst"
          count+=1
        else # [[ ${FILE[$i]} < ${FILEOLD[$count]} ]]
          break
        fi
      done
      if_link_correct "$src" "$dst" || link_correctly "$src" "$dst"
      [[ ! -z ${FILE[$amount]// /} ]] && { echo "$dst//$src" >>"$KEEPIT" || ERROR "Can not edit it, check permission for \"$KEEPIT\"?"; }
      [[ $once -eq 1 ]] && break
      ldst=$dst
    fi
  done
  while [[ $count -lt $maxcount ]]; do
    local odst osrc
    read odst osrc <<<${FILEOLD[$count]/\/\// }
    oldlink_removal "$osrc" "$odst"
    count+=1
  done
  [[ ! -e $KEEPIT ]] && touch "$KEEPIT"
  [[ $fok -eq 1 ]] && { rm "$KEEPIT.bk" || ERROR "Cannot remove it, check permission for \"$KEEPIT.bk\"?" || return 1; }
  return 0
}

check_and_enforce_to_queue() {
  for name in "${!GF}"; do
    [[ ${name} =~ /{2,} ]] && { WARN "Genre \"${GT}\": file \"${name}\" is not a valid path, skipped. (Tips: remove multiple '/' from name)" || continue; }
    [[ ${name} =~ /$ ]] && name="${name%/*}"
    local fsrc="${dotfile_basepath_src}${!GS}${name}"
    local fdst="${dotfile_basepath_dst}${!GD}${name}"
    [[ ${fdst} =~ /{2,} ]] || [[ ${fsrc} =~ /{2,} ]] && { WARN "Genre \"${GT}\": source \"$fsrc\" or destination \"$fdst\" is not a valid path, skipped. (Tips: check your config and remove multiple '/' from option(s))" || continue; }
    [[ -z ${name// /} ]] && { WARN "Genre \"${GT}\": file field \"${name}\" is empty in config, skipped" || continue; }
    mkdir -p "$TMPDIR$fdst" || WARN "Genre \"${GT}\": file \"${fdst}\" is not a valid path" || continue
    rmdir "$TMPDIR$fdst"
    [[ ! -e $fsrc ]] && { WARN "Genre \"${GT}\": Source file \"${fsrc}\" is not exist, skipped" || continue; }
    # [[ -L $fsrc ]] && { WARN "Genre \"${GT}\": Source file \"${fsrc}\" is a symbolic link, skipped" || continue; }
    # [[ -e $fdst && ! -L $fdst ]] && WARN "Genre \"${!GT}\": Destination file \"${fdst}\" has been occupied by another file, skipped" || continue
    # [[ -L $fdst ]] && [[ $(realpath $fdst) != $fsrc ]] && continue # removed
    [[ -e $fdst ]] && [[ $fdst -nt $fsrc ]] && { WARN "Genre \"${GT}\": Destination file \"${fdst}\" has a newer modified time than the source \"${fsrc}\"" || question "Do you really want to override \"${fdst}\" by creating link from \"${fsrc}\"?" || continue; }
    FILE+=("$fdst//$fsrc") # split with the dilimiter //
  done
  return 0
}

parser_genre_confrim() {
  echo "Genre \"${GT}\": Are you confirm to LINK the file(s) named ${!GF} from \"$dotfile_basepath_src${!GS}\", to the folder \"$dotfile_basepath_dst${!GD}\" on this system?"
  question
}

#!TODO Test eval() usable

parser_genre() {
  [[ ! ${dotfile_basepath_src} =~ ^/* ]] || [[ ! ${dotfile_basepath_dst} =~ ^/* ]] && { ERROR "You need set the setting dotfile_basepath_src(/dst) to a absolute path."; }
  [[ -n "${dotfile_genre-}" ]] && for t in "${dotfile_genre[@]}"; do
    GT=$t
    GS="g_${t}_src_prefix"
    GF="g_${t}_files[@]"
    GD="g_${t}_dst_prefix"
    GO="g_${t}_osonly"
    local sc=0
    [[ ${!GF-} =~ ^\s*$ ]] && { WARN "No file(s) gived from setting \"${GF/\[@\]/}\", skipped." || continue; }
    [[ -z ${GT// /} ]] && { WARN "A empty genre name from setting \"dotfile_genre\" is found, skipped." || continue; }
    [[ ! ${GT} =~ ^[a-zA-Z]+$ ]] && { WARN "Weird genre name \"${GT}\" found. Only English characters are supported, skipped." || continue; }
    # [[ -z ${!GF-} ]] && ERROR "No files are specified in the config" "you must specify at least one file with setting \"${GF}\" for the genre \"${GT}\""
    [[ -z ${!GS-} ]] && { WARN "You are not completely setting for \"${GS}\", we will use the conventional default settings for it" || eval $GS="/" && sc=1; }
    [[ -z ${!GD-} ]] && { WARN "You are not completely setting for \"${GD}\", we will use the conventional default settings for it" || eval $GD="/." && sc=1; }
    [[ -z ${!GO-} ]] && { WARN "You are not completely setting for \"${GO}\", we will use the conventional default settings for it" || eval $GO="0" && sc=1; }
    # judge is this OS allow or not, this setting is follow the config
    [[ -z $MTAG ]] && ERROR "No type of OS gived."
    [[ "${GO}" -eq 0 ]] || [[ ! "${GO}" -eq "$MTAG" ]] || continue
    [[ "$sc" -eq 1 ]] && [[ $config_default_confirm -eq 1 ]] && { WARN "You need to confirm when default setting(s) automatically appliance" || parser_genre_confrim || { WARN "Ignored." || continue; }; }
    check_and_enforce_to_queue
    printf "[INFO] Genre \"${GT}\" is loaded.\n"
  done
  link_file
}

main() {
  [[ ! -n ${BASH_SOURCE} ]] && ERROR "Can not get \${BASH_SOURCE}, please check if you are running with bash."
  export EPATH=$BASH_SOURCE && EPATH=$(realpath $EPATH)
  loadconfig
  # [[ $config_lib_enable -eq 1 ]] && loadlib
  [[ -z ${1-} ]] && judge_env
  [[ -z ${MTAG-} ]] && check_env "$@"
  parser_genre || WARN "Unknown problems happened, check last warning for details." || return 1
  echo "[INFO] sync-dotfile: finished"
}

main "$@"
