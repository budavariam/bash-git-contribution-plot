#!/bin/bash

SELECTED_YEAR=${1:-2020}
SELECTED_USER=${2:-"------"}
GIT_FOLDER=${3:-.}

pushd "$GIT_FOLDER" >/dev/null || exit 1
INPUT_DATA=$(git log -a --date=format:'%Y-%m-%d' --pretty=format:"%ae %ad" | grep --color=no "$SELECTED_USER" | grep --color=no " $SELECTED_YEAR-" | sort -k1,1 -k2,2 | uniq -c | sed 's/^ *//')
popd >/dev/null || exit 2

contrib_cnt_for_day=()
plot=() # plot is the final result, 7 lines each containing the weekday results
max_contrib_count=0
step=-1
level1top=-1
level2top=-1
level3top=-1
level4top=-1

no_contrib="\e[48;5;0m \033[0m"
no_day="\e[48;5;8m \033[0m"
# shades of green from dark to light
g1="\e[48;5;22m \033[0m"
g2="\e[48;5;28m \033[0m"
g3="\e[48;5;40m \033[0m"
g4="\e[48;5;46m \033[0m"

nthday() {
  year=$1
  date=$2
  echo $((($(date -j -f "%Y-%m-%d" "$date" "+%s") - $(date -j -f "%Y-%m-%d" "$year-01-01" "+%s")) / 86400))
}

fill_calendar() {
  for i in {1..366}; do contrib_cnt_for_day[i]=0; done
  OLDIFS=$IFS
  IFS=$'\n'
  for line in $INPUT_DATA; do
    count=$(echo "$line" | cut -d ' ' -f 1)
    date=$(echo "$line" | cut -d " " -f 3)
    nth=$(nthday "$SELECTED_YEAR" "$date")
    contrib_cnt_for_day["$nth"]=$count
    if [ "$count" -gt "$max_contrib_count" ]; then
      max_contrib_count="$count"
    fi
  done
  IFS=$OLDIFS

  step=$((max_contrib_count / 4))
  level1top=$step
  level2top=$((2 * step))
  level3top=$((3 * step))
  level4top=$max_contrib_count
}

contrib_mark() {
  if [ "$1" -eq 0 ]; then
    printf "%b" "$no_contrib"
  elif [ "$1" -le "$level1top" ]; then
    printf "%b" "$g1"
  elif [ "$1" -le "$level2top" ]; then
    printf "%b" "$g2"
  elif [ "$1" -le "$level3top" ]; then
    printf "%b" "$g3"
  elif [ "$1" -le "$level4top" ]; then
    printf "%b" "$g4"
  fi
}

noday_mark() {
  printf "%b" "$no_day"
}

get_plot() {
  # firstday is the first day of the year, 1-7, 1 is monday
  firstday=$(($(date -j -f "%Y-%m-%d" "$SELECTED_YEAR-1-1" "+%u")))
  day=$firstday

  for ((i = 1; i < day; i++)); do
    plot[$i]="$(noday_mark)"
  done

  for i in "${!contrib_cnt_for_day[@]}"; do
    day=$(((day % 7) + 1))
    plot[day]=$(printf "%s%s" "${plot[day]}" "$(contrib_mark "${contrib_cnt_for_day[$i]}")")
  done

  for ((i = day + 1; i <= 7; i++)); do
    plot[i]=$(printf "%s%s" "${plot[i]}" "$(noday_mark)")
  done
}

print_plot() {
  for i in "${!plot[@]}"; do
    printf "%s\n" "${plot[i]}"
  done
}

fill_calendar
get_plot
print_plot
