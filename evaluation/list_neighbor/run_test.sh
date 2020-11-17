#!/bin/bash
DATASETDIR="../../datasets/dmgen/prepared_datasets/dmgen"
TYPE="dmgen"
DATA="time-data"
LIMITS="limits-data"
RUNS=5

declare -a WEBGRAPH=("uk-2007-05@100000" "in-2004" "uk-2014-host" "eu-2015-host")
declare -a WEBGRAPH_NODES=(100000 1382908 4769354 11264052)
#declare -a WEBGRAPH=("uk-2007-05@100000" "in-2004" "uk-2014-host")
#declare -a WEBGRAPH_NODES=(100000 1382908 4769354)
#declare -a WEBGRAPH=("eu-2015-host")
#declare -a WEBGRAPH_NODES=(11264052)

if [[ $1 != "-dmgen" && $1 != "-webgraph" && $1 != "" ]]; then
  echo "Usage: ./run_test.sh [-dmgen/webgraph]"
  exit
elif [[ $1 == "-webgraph" ]]; then
  DATASETDIR="../../datasets/webgraph"
  TYPE="webgraph"
fi

declare -a TIME_COMPLEXITY=()
declare -a MEMORY_COMPLEXITY=()
create_serialized_tree() { #[create_serialized_test $dataset $vertice]
  echo "$1"
  bo=$(./create "$DATASETDIR/$1/$1.tsv" "$2" "$1")
  complexity=($(echo "$bo" | tr ' ' '\n'))
  TIME_COMPLEXITY+=("${complexity[0]}")
  MEMORY_COMPLEXITY+=("${complexity[1]}")
}

declare -a TIME=()
eval_time_union() {
  TIME+=("$(./list "$DATASETDIR/$1/$1.tsv" $RUNS "$1")")
}

declare -a MEMORY=()
eval_memory_union() {
  /usr/bin/time -v --output="$1/mem.txt" ./list "$DATASETDIR/$1/$1.tsv" $RUNS "$1"
  MEMORY+=("$(grep -oP 'Maximum resident set size \(kbytes\): \K[0-9]+' "$1/mem.txt")")
}

i=0
prepared_data() {
  for el in "${TIME_COMPLEXITY[@]}"; do
    echo "$el ${TIME[${i}]} ${MEMORY_COMPLEXITY[${i}]} ${MEMORY[${i}]}" >>"$DATA-$TYPE"
    i=$((i + 1))
  done
  echo ${TIME_COMPLEXITY[0]} ${TIME_COMPLEXITY[-1]} ${TIME[0]} ${TIME[-1]} ${MEMORY_COMPLEXITY[0]} ${MEMORY_COMPLEXITY[-1]} ${MEMORY[0]} ${MEMORY[-1]} >>"$LIMITS-$TYPE"
}

plot_data_time() {
  bo=$(head -n 1 "$LIMITS-$TYPE")
  info=($(echo "$bo" | tr ' ' '\n'))
  MIN=${info[0]}
  MAX=${info[1]}
  MIN_y=${info[2]}
  MAX_y=${info[3]}
  gnuplot -persist <<-EOF
  set terminal pngcairo
  set datafile separator whitespace
  set output 'list_time_$TYPE.png'
  set xlabel "sqrt(m)"
  set ylabel "Time (s)"
  plot "$DATA-$TYPE" using 1:2 with linespoints linestyle 7 title "list neighbor operation"
EOF
}

plot_data_mem() {
  bo="$(head -n 1 "$LIMITS-$TYPE")"
  info=($(echo "$bo" | tr ' ' '\n'))
  MIN=${info[4]}
  MAX=${info[5]}
  MIN_y=${info[6]}
  MAX_y=${info[7]}
  gnuplot -persist <<-EOF
  set terminal pngcairo
  set datafile separator whitespace
  set output 'list_mem_$TYPE.png'
  set xlabel "n+m"
  set ylabel "Memory (kbytes)"
  plot "$DATA-$TYPE" using 3:4 with linespoints linestyle 7 title "list neighbor operation"
EOF
}

if [[ $2 != "-plot" ]]; then
  echo "Compiling..."
  make --keep-going clean all
  echo "Cleaning up..."
  rm "$DATA-$TYPE"
  rm "$LIMITS-$TYPE"
  echo "Done!"
  echo "Evaluating..."
  if [[ $TYPE == "dmgen" ]]; then
    for vertices in $(ls $DATASETDIR | sort --version-sort); do
      rm -r $vertices
    done

    for vertices in $(ls $DATASETDIR | sort --version-sort); do
      mkdir -p $vertices
      create_serialized_tree $vertices $vertices

      eval_time_union $vertices
      eval_memory_union $vertices $vertices
    done
  fi

  if [[ $TYPE == "webgraph" ]]; then
    for dataset in "${WEBGRAPH[@]}"; do
      rm -r $dataset
    done

    k=0
    for dataset in "${WEBGRAPH[@]}"; do
      mkdir -p "$dataset"

      create_serialized_tree "$dataset" "${WEBGRAPH_NODES[${k}]}"
      eval_time_union "$dataset"
      eval_memory_union "$dataset" "${WEBGRAPH_NODES[${k}]}"
      k=$((k + 1))
    done
  fi
  #PLOT data
  echo "Preparing data..."
  prepared_data
fi

echo "Ploting time..."
plot_data_time

echo "Ploting memory..."
plot_data_mem