#!/bin/bash
# Prepare databases and containers
#  Usage: nohup bash scripts/00b_prepare_databases.sh > logs/00b_prepare_databases.out 2> logs/00b_prepare_databases.err &

set -uo pipefail   

echo "=== PREPARING DATABASES AND CONTAINERS ==="
echo "Started: $(date)"
echo ""

eval "$(conda shell.bash hook)"

BASE_DIR="/lustre/isaac24/proj/UTK0505/agonza84/EPP622-2026-GenomeAnnotation"
DB_DIR="${BASE_DIR}/databases/compleasm_mb"
CONTAINER_DIR="${BASE_DIR}/containers"
SIF="${CONTAINER_DIR}/helixer_v0.3.2_cuda_11.8.0-cudnn8.sif"

mkdir -p "${DB_DIR}" "${CONTAINER_DIR}" "${BASE_DIR}/logs"
cd "${BASE_DIR}"

echo "--> Step 1: compleasm lineage nematoda_odb12"
conda activate compleasm
compleasm --version
if compleasm download nematoda_odb12 -L "${DB_DIR}"; then
  echo "STEP 1 OK"
else
  echo "STEP 1 FAILED"
fi
ls -lh "${DB_DIR}"
echo ""

echo "--> Step 2: compleasm protein --help"
compleasm protein --help
echo "STEP 2 DONE"
conda deactivate
echo ""


echo "--> Step 3: Helixer container"
conda activate annotation
export APPTAINER_CACHEDIR="${CONTAINER_DIR}/.apptainer_cache"
export APPTAINER_TMPDIR="${CONTAINER_DIR}/.apptainer_tmp"
mkdir -p "${APPTAINER_CACHEDIR}" "${APPTAINER_TMPDIR}"

if [ -s "${SIF}" ]; then
  echo "Container already exists: ${SIF}"
  echo "STEP 3 OK"
elif apptainer pull "${SIF}" \
       docker://quay.io/biocontainers/helixer-docker:helixer_v0.3.2_cuda_11.8.0-cudnn8; then
  echo "STEP 3 OK"
else
  echo "STEP 3 FAILED"
fi
ls -lh "${CONTAINER_DIR}"
echo ""

echo "--> Step 4: Helixer invertebrate model"
if apptainer exec -B "${BASE_DIR}" "${SIF}" fetch_helixer_models.py --lineage invertebrate; then
  echo "STEP 4 OK"
else
  echo "STEP 4 FAILED"
fi
ls -lhR "${HOME}/.local/share/Helixer/models" 2>/dev/null | head -n 20
conda deactivate
echo ""

echo "Completed: $(date)"
