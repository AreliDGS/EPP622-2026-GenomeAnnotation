#!/bin/bash
#SBATCH --job-name=01_fastp_hic
#SBATCH -A ISAAC-UTK0505
#SBATCH --partition=short
#SBATCH --qos=short
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=32G
#SBATCH --time=02:59:00
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --mail-user=agonza84@utk.edu
#SBATCH --output=/lustre/isaac24/proj/UTK0505/agonza84/EPP622-2026-GenomeAnnotation/logs/01_fastp_hic_%j.out
#SBATCH --error=/lustre/isaac24/proj/UTK0505/agonza84/EPP622-2026-GenomeAnnotation/logs/01_fastp_hic_%j.err


set -euo pipefail

echo "=== TRIMMING OF HI-C FASTP ==="
echo "Started: $(date)"
echo ""

eval "$(conda shell.bash hook)"
conda activate assembly

BASE_DIR="/lustre/isaac24/proj/UTK0505/agonza84/EPP622-2026-GenomeAnnotation"
OUT_DIR="${BASE_DIR}/results/01_fastp_hic"
mkdir -p "${OUT_DIR}"
cd "${OUT_DIR}"

# Variables
READ_1="${BASE_DIR}/raw_data/SRR32971244_1.fastq.gz"
READ_2="${BASE_DIR}/raw_data/SRR32971244_2.fastq.gz"


# Step 1: Trim adapters and poly-G tails 
#   --detect_adapter_for_pe : detect adapters
#   --trim_poly_g: remove poly-G tails, as it was sequenced on a NextSeq 2000cd (two-colour chemistry, where "no signal" is read as G)
#   --json/--html: QC reports
fastp \
  -i "${READ_1}" -o "${OUT_DIR}/dirofilaria_hic_trimmed_R1.fastq.gz" \
  -I "${READ_2}" -O "${OUT_DIR}/dirofilaria_hic_trimmed_R2.fastq.gz" \
  --detect_adapter_for_pe \
  --trim_poly_g \
  --thread "${SLURM_CPUS_PER_TASK:-16}" \
  --json "${OUT_DIR}/dirofilaria_hic_fastp.json" \
  --html "${OUT_DIR}/dirofilaria_hic_fastp.html"

ls -lh "${OUT_DIR}"

echo ""
echo "Completed: $(date)"
