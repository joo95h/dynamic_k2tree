#!/bin/bash
DATASETDIR="../../datasets/dmgen/prepared_datasets/dmgen"
TYPE="dmgen"
UNION_DATA="time-data-sdk"
RUNS_TIME="union_sdk"

declare -a WEBGRAPH=("uk-2007-05@100000" "in-2004" "uk-2014-host" "indochina-2004")
declare -a WEBGRAPH_NODES=(100000 1382908 4769354 7414866)
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
create_serialized_tree() { #[create_serialized_test $dataset $vertice]
  #  ./create "$DATASETDIR/$1/$1.tsv" "$2" "$1/test.kt"
  TIME_COMPLEXITY+=("$(./create_sdk "$DATASETDIR/$1/$1.tsv" "$2" "$1/test_sdk")")
}

declare -a MEMORY=()
declare -a VERTICES=()
declare -a TIME=()
eval_memory_union() {
  #  $1 - number of vertices of the current test file
  #  valgrind --tool=massif --massif-out-file=$1/$1.union.mem.out ./union $1/test.kt $1/test.kt
  /usr/bin/time -v --output="$1/mem_union_sdk.txt" ./union_sdk "$1/test_sdk">>"$1/$RUNS_TIME-$TYPE"
  TIME+=("$(./union_sdk "$1/test_sdk")")
  MEMORY+=("$(grep -oP 'Maximum resident set size \(kbytes\): \K[0-9]+' "$1/mem_union_sdk.txt")")
  VERTICES+=("$2")
  #  valgrind --tool=massif --massif-out-file=$vertices/$vertices.union.mem.out ./union $vertices/test.kt $vertices/test.kt
}

i=0
prepared_data() {
  for el in "${TIME_COMPLEXITY[@]}"; do
    echo "${TIME[${i}]} ${MEMORY[${i}]} ${VERTICES[${i}]} $el" >>$UNION_DATA-$TYPE
    i=$((i + 1))
  done
}

plot_data_time_dmgen() {
  echo "Ploting time..."
  gnuplot -persist <<-EOF
  set terminal pdfcairo mono font "sans, 16"
  set datafile separator whitespace
  set output 'union_time_$TYPE-sdk.pdf'
  set title "Union ($TYPE)"
  set grid
  set xlabel "n + m (10^6)"
  set ylabel "t (s)"
  set style data linespoints
  plot "$UNION_DATA-$TYPE" using 4:1 with linespoints pt 8 notitle
EOF
}

plot_data_mem_dmgen() {
  echo "Ploting memory..."
  gnuplot -persist <<-EOF
  set terminal pdfcairo mono font "sans, 16"
  set datafile separator whitespace
  set output 'union_mem_$TYPE-sdk.pdf'
  set title "Union ($TYPE)"
  set grid
  set xlabel "n"
  set ylabel "memory (MB)"
  set style data linespoints
  plot "$UNION_DATA-$TYPE" using 3:2 with linespoints pt 8 notitle
EOF
}

plot_data_time() {
  echo "Ploting time..."
  gnuplot -persist <<-EOF
  set terminal pdfcairo mono font "sans, 16"
  set datafile separator whitespace
  set output 'union_time_$TYPE-sdk.pdf'
  set title "Union ($TYPE)"
  set grid
  set xlabel "n + m (10^6)"
  set ylabel "t (s)"
  set style data linespoints
  plot "$UNION_DATA-$TYPE" using 4:1 with linespoints pt 8 notitle
EOF
}

plot_data_mem() {
  echo "Ploting memory..."
  gnuplot -persist <<-EOF
  set terminal pdfcairo mono font "sans, 16"
  set datafile separator whitespace
  set output 'union_mem_$TYPE-sdk.pdf'
  set title "Union ($TYPE)"
  set grid
  set xlabel "n (10^6)"
  set ylabel "memory (MB)"
  set style data linespoints
  plot "$UNION_DATA-$TYPE" using 3:2 with linespoints pt 8 notitle
EOF
}

if [[ $2 != "-plot" ]]; then
  echo "Compiling..."
  make --keep-going clean_sdk create_sdk union_sdk

  echo "Evaluating..."
  echo "Cleaning up..."
  rm $UNION_DATA-$TYPE
  echo "Done!"
  if [[ $TYPE == "dmgen" ]]; then
    for vertices in $(ls $DATASETDIR | sort --version-sort); do
      rm "$vertices/mem_union_sdk.txt"
      rm "$vertices/$RUNS_TIME-$TYPE"
    done

    for vertices in $(ls $DATASETDIR | sort --version-sort); do
      mkdir -p $vertices
      create_serialized_tree $vertices $vertices

      eval_memory_union $vertices $vertices
    done
  fi

  if [[ $TYPE == "webgraph" ]]; then
    for dataset in "${WEBGRAPH[@]}"; do
      rm "$dataset/mem_union_sdk.txt"
    done

    k=0
    for dataset in "${WEBGRAPH[@]}"; do
      create_serialized_tree "$dataset" "${WEBGRAPH_NODES[${k}]}"
      eval_memory_union "$dataset" "${WEBGRAPH_NODES[${k}]}"
      k=$((k + 1))
    done
  fi

  #PLOT data
  echo "Preparing data..."
  prepared_data
fi
#
#if [[ $TYPE == "dmgen" ]]; then
#  plot_data_time_dmgen
#  plot_data_mem_dmgen
#else
#  plot_data_time
#  plot_data_mem
#fi
