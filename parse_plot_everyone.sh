#!/usr/bin/env bash
set -euo pipefail

# Combine the repo's existing parsers/plotters for one test point/tag.
# Run from the repository root.
#
# Examples:
#   ./plot-testpoint.sh run1
#   ./plot-testpoint.sh out-run1
#
# This script does not implement new parsing logic. It only calls the
# already existing scripts in the repository.

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <tag|out-tag>"
  echo "Example: $0 run1"
  echo "Example: $0 out-run1"
  exit 1
fi

if [[ ! -d scripts ]] || [[ ! -d 01-leakage-channel-workloads ]]; then
  echo "Please run this script from the repository root."
  exit 1
fi

arg="$1"
if [[ "$arg" == out-* ]]; then
  tag="${arg#out-}"
else
  tag="$arg"
fi

run_in_dir() {
  local dir="$1"
  shift
  echo
  echo "==> (${dir}) $*"
  (
    cd "$dir"
    "$@"
  )
}

have_dir() {
  [[ -d "$1" ]]
}

found_any=0

# 01 - workload channel
if have_dir "01-leakage-channel-workloads/data/out-${tag}"; then
  found_any=1
  run_in_dir "01-leakage-channel-workloads" python ./plot.py "data/out-${tag}"
fi

# 02 - data channel (steady / drops)
if have_dir "02-leakage-channel-data/data/out-steady-${tag}"; then
  found_any=1
  run_in_dir "02-leakage-channel-data" python ./plot.py --steady "data/out-steady-${tag}"
fi

if have_dir "02-leakage-channel-data/data/out-drops-${tag}"; then
  found_any=1
  run_in_dir "02-leakage-channel-data" python ./plot.py --drops "data/out-drops-${tag}"
fi

# 03 - HD leakage model
if have_dir "03-leakage-model-hd/data/out-${tag}"; then
  found_any=1
  run_in_dir "03-leakage-model-hd" python ../scripts/parse.py --freq "data/out-${tag}"
  run_in_dir "03-leakage-model-hd" python ./plot-hd.py --freq "data/out-${tag}" hd-freq
  run_in_dir "03-leakage-model-hd" python ../scripts/parse.py --energy "data/out-${tag}"
  run_in_dir "03-leakage-model-hd" python ./plot-hd.py --energy "data/out-${tag}" hd-power
fi

# 04 - HW leakage model
# Reuse the repo's existing combined wrapper.
if have_dir "04-leakage-model-hw/data/out-${tag}" \
  || have_dir "04-leakage-model-hw/data/out-nc-${tag}" \
  || have_dir "04-leakage-model-hw/data/out-shift-${tag}" \
  || have_dir "04-leakage-model-hw/data/out-rest-${tag}"; then
  found_any=1
  run_in_dir "04-leakage-model-hw" bash ./parseandplotall.sh "${tag}"
fi

# 05 - HD/HW additivity model
if have_dir "05-leakage-model-hd_hw/data/out-${tag}"; then
  found_any=1
  run_in_dir "05-leakage-model-hd_hw" python ../scripts/parse.py --freq "data/out-${tag}"
  run_in_dir "05-leakage-model-hd_hw" python ./plot-hd-hw.py --freq "data/out-${tag}" hd-hw-freq
  run_in_dir "05-leakage-model-hd_hw" python ../scripts/parse.py --energy "data/out-${tag}"
  run_in_dir "05-leakage-model-hd_hw" python ./plot-hd-hw.py --energy "data/out-${tag}" hd-hw-power
fi

if [[ "$found_any" -eq 0 ]]; then
  echo "No matching data folders found for tag '${tag}'."
  echo "Checked the standard repo locations under 01..05."
  exit 1
fi

echo

echo "Done. Generated plots are in each experiment's plot/ directory."
