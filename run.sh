#!/usr/bin/env bash
set -uo pipefail

# CTRL+C kills all jobs
cleanup() {
  echo "Interrupted, terminating all jobs…"
  jobs -p | xargs -r kill
  exit 1
}
trap cleanup INT TERM

DRIVER="./build/MAPD"
TIMEOUT=60
MAX_JOBS=${1:-$(nproc)} # allow override: ./benchmark.sh 8

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
RESULTS_DIR="results_${TIMESTAMP}"
mkdir -p "$RESULTS_DIR"

# Collect all maps and tasks
MAPS=(examples/kiva-agent-maps/*.map)
TASKS=(examples/kiva-tasks/*/*.task)

job_count=0
total_jobs=$(( ${#MAPS[@]} * ${#TASKS[@]} ))

echo "Running $total_jobs jobs with up to $MAX_JOBS parallel workers..."
echo "Results will be written into $RESULTS_DIR"

run_job() {
  local map="$1"
  local task="$2"
  local job_id="$3"

  local map_name
  map_name=$(basename "$map" .map)
  
  # include parent directory for uniqueness
  local task_path_sanitized
  task_path_sanitized=$(echo "$task" | sed 's|/|_|g' | sed 's|\.task||')
  
  local out_file="$RESULTS_DIR/out_${map_name}_${task_path_sanitized}.csv"

  echo "[Job $job_id] Starting: map=$map_name task=$task_path_sanitized"

  $DRIVER \
    -m "$map" \
    -a "$map" \
    -t "$task" \
    -s PP \
    --capacity 1 \
    --only-update-top \
    --objective total-travel-time \
    --anytime \
    -c $TIMEOUT \
    --kiva \
    --group-size 5 \
    --destory-method random \
    -o "$out_file"

  local exit_code=$?
  if [[ $exit_code -eq 0 ]]; then
    echo "[Job $job_id] Completed: map=$map_name task=$task_path_sanitized -> $out_file"
  else
    echo "[Job $job_id] ERROR (exit $exit_code): map=$map_name task=$task_path_sanitized"
  fi
}

for map in "${MAPS[@]}"; do
  for task in "${TASKS[@]}"; do
    ((job_count++))

    if [[ $MAX_JOBS -gt 1 ]]; then
      while [[ $(jobs -r | wc -l) -ge $MAX_JOBS ]]; do
        wait -n
      done
      run_job "$map" "$task" "$job_count" &
    else
      run_job "$map" "$task" "$job_count"
    fi
  done
done

wait
echo "All $job_count jobs finished."
echo "Results stored in: $RESULTS_DIR"