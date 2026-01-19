#!/usr/bin/env bash
set -euo pipefail

# Usage:
#   ./make-plots.sh <TAG>
#
# Example:
#   ./make-plots.sh run1
#   # uses: data/out-run1, data/out-nc-run1, data/out-shift-run1, data/out-rest-run1
#
# Note: We call it "tag" to avoid implying it's a real calendar date.

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <tag>"
  echo "Example: $0 run1   (expects data/out-run1, data/out-nc-run1, ...)"
  exit 1
fi

tag="$1"

run_pair() {
  local mode="$1"      # --freq or --energy
  local infile="$2"    # data/out-...-${tag}
  local plotter="$3"   # ./plot-*.py
  local outprefix="$4" # e.g., hw-freq

  echo "==> ${mode}  ${infile}  -> ${outprefix}"
  python ../scripts/parse.py "${mode}" "${infile}"
  python "${plotter}" "${mode}" "${infile}" "${outprefix}"
}

# Figures 5a and 7a (frequency)
run_pair --freq   "data/out-${tag}"        "./plot-hw.py"        "hw-freq"
# Figures 5b and 7b (power)
run_pair --energy "data/out-${tag}"        "./plot-hw.py"        "hw-power"

# Figure 6a (frequency, no-countermeasure)
run_pair --freq   "data/out-nc-${tag}"     "./plot-hw-nc.py"     "hw-nc-freq"
# Figure 6b (power, no-countermeasure)
run_pair --energy "data/out-nc-${tag}"     "./plot-hw-nc.py"     "hw-nc-power"

# Figures 15a and 16a (frequency, shift)
run_pair --freq   "data/out-shift-${tag}"  "./plot-hw-shift.py"  "hw-shift-freq"
# Figures 15b and 16b (power, shift)
run_pair --energy "data/out-shift-${tag}"  "./plot-hw-shift.py"  "hw-shift-power"

# Figure 17a (frequency, rest)
run_pair --freq   "data/out-rest-${tag}"   "./plot-hw-rest.py"   "hw-rest-freq"
# Figure 17b (power, rest)
run_pair --energy "data/out-rest-${tag}"   "./plot-hw-rest.py"   "hw-rest-power"

echo "All plots done."

