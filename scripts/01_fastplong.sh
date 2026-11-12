#!/bin/bash
#SBATCH --job-name=01_fastplong
#SBATCH -A ISAAC-UTK0505
#SBATCH --partition=short
#SBATCH --qos=short
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=60G
#SBATCH --time=02:59:00
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --mail-user=agonza84@utk.edu
#SBATCH --output=/lustre/isaac24/proj/UTK0505/agonza84/EPP622-2026-GenomeAnnotation/logs/01_fastplong_%j.out
#SBATCH --error=/lustre/isaac24/proj/UTK0505/agonza84/EPP622-2026-GenomeAnnotation/logs/01_fastplong_%j.err

set -euo pipefail

echo "=== QUALITY CONTROL OF PACBIO HIFI READS WITH FASTPLONG ==="
echo "Started: $(date)"
echo ""

eval "$(conda shell.bash hook)"
conda activate assembly

BASE_DIR="/lustre/isaac24/proj/UTK0505/agonza84/EPP622-2026-GenomeAnnotation"
OUT_DIR="${BASE_DIR}/results/01_fastplong"
cd "${BASE_DIR}"
mkdir -p "${OUT_DIR}"

# Step 1: Run fastplong on the single HiFi file (SRR32971245)
#   --in   : one long-read FASTQ input
#   --out  : cleaned reads 
#   --disable_quality_filtering : HiFi reads are already high base quality (~Q30+)
#   --json/--html : QC reports used for the Results table
fastplong \
  --in raw_data/SRR32971245.fastq.gz \
  --out "${OUT_DIR}/dirofilaria_hifi_clean.fastq" \
  --disable_quality_filtering \
  --thread "${SLURM_CPUS_PER_TASK:-16}" \
  --json "${OUT_DIR}/dirofilaria_hifi_report.json" \
  --html "${OUT_DIR}/dirofilaria_hifi_report.html"

# Step 2: Compress the cleaned reads (multi-threaded bgzip)
bgzip -f -@ "${SLURM_CPUS_PER_TASK:-16}" "${OUT_DIR}/dirofilaria_hifi_clean.fastq"

ls -lh "${OUT_DIR}" #check the output files

echo ""
echo "Completed: $(date)"

