#!/usr/bin/env bash

set -euo pipefail

IMAGE="${1:-churn-docker:dev}"

echo "=================================="
echo " Starting Docker smoke-test"
echo " Image: $IMAGE"
echo "=================================="

echo "[1/2] Testing model and call list..."

docker run --rm "$IMAGE" python -c '
import csv
import math
import subprocess
from pathlib import Path
from churn.data import MAL, las_data

output = Path("outputs/ringlista.csv")
output.unlink(missing_ok=True)

subprocess.run(
    ["python", "-m", "churn.score"],
    check=True
)

assert output.is_file(), "Ringlista saknas!"

with output.open(newline="") as file:
    reader = csv.DictReader(file)
    assert reader.fieldnames == ["kund_id", "risk"], \
        f"Fel kolumner: {reader.fieldnames}"
    rows = list(reader)

assert len(rows) == 100, \
    f"Förväntade 100 kunder, fick {len(rows)}"

ids = [row["kund_id"] for row in rows]
assert all(ids), "Tomma kund-ID hittades"
assert len(ids) == len(set(ids)), \
    "Dubbla kund-ID hittades"
# Check that listed customers exist in the source data.
customers = las_data()
known_ids = set(customers["kund_id"].astype(str))
listed_ids = set(ids)

unknown_ids = listed_ids - known_ids
assert not unknown_ids, \
    f"Unknown customer IDs in call list: {sorted(unknown_ids)}"

# Only customers with an active subscription may appear.
active_customers = customers[customers[MAL] == 0]
active_ids = set(active_customers["kund_id"].astype(str))

inactive_ids = listed_ids - active_ids
assert not inactive_ids, \
    f"Customers with ended subscriptions in call list: {sorted(inactive_ids)}"

risker = [float(row["risk"]) for row in rows]

assert all(
    math.isfinite(risk) and 0 <= risk <= 1
    for risk in risker
), "Ogiltiga riskvärden hittades"

assert risker == sorted(risker, reverse=True), \
    "Ringlistan är inte sorterad efter risk"

print("PASS: 100 valid customers with active subscriptions")
'

echo "[2/2] Testing missing model handling..."

if output=$(docker run --rm "$IMAGE" \
    python -m churn.score outputs/missing-model.joblib 2>&1)
then
    echo "FAIL: Missing model was accepted"
    exit 1
fi

if [[ "$output" == *"FEL: hittar inte outputs/missing-model.joblib"* ]]; then
    echo "PASS: Missing model correctly rejected"
else
    echo "FAIL: Unexpected error from container"
    echo "$output"
    exit 1
fi

echo "=================================="
echo " ALL SMOKE TESTS PASSED"
echo "=================================="