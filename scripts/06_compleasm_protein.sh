#!/bin/bash
#SBATCH --job-name=06_compleasm_protein
#SBATCH -A ISAAC-UTK0505
#SBATCH --partition=short
#SBATCH --qos=short
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=12
#SBATCH --mem=50G
#SBATCH --time=03:00:00
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --mail-user=agonza84@utk.edu
#SBATCH --output=/lustre/isaac24/proj/UTK0505/agonza84/EPP622-2026-GenomeAnnotation/logs/06_compleasm_protein_%j.out
#SBATCH --error=/lustre/isaac24/proj/UTK0505/agonza84/EPP622-2026-GenomeAnnotation/logs/06_compleasm_protein_%j.err

set -euo pipefail

echo "=== PROTEIN COMPLETENESS OF HELIXER GENES (gffread + compleasm protein) ==="
echo "Started: $(date)"
echo ""

eval "$(conda shell.bash hook)"
conda activate annotation

BASE_DIR="/lustre/isaac24/proj/UTK0505/agonza84/EPP622-2026-GenomeAnnotation"
ASM="${BASE_DIR}/results/02_assembly/dirofilaria_hic_asm.hic.hap1.p_ctg.fasta"
GFF="${BASE_DIR}/results/05_helixer/dirofilaria_hic_asm.hic.hap1.p_ctg.gff3"
OUT_DIR="${BASE_DIR}/results/06_compleasm_protein"
DB_DIR="${BASE_DIR}/databases/compleasm_mb"   
LINEAGE="nematoda_odb12"
THREADS="${SLURM_CPUS_PER_TASK:-12}"
PROTEINS="${OUT_DIR}/dirofilaria_hic_asm.hic.hap1.p_ctg.PROTEINS.fasta"

mkdir -p "${OUT_DIR}"
cd "${OUT_DIR}"

# Step 1: Extract the predicted protein sequences with gffread
#   -g : genome FASTA that the GFF3 coordinates refer to
#   -y : write the translated CDS (protein) FASTA
gffread \
  "${GFF}" \
  -g "${ASM}" \
  -y "${PROTEINS}"

echo "--> Number of proteins: $(grep -c '^>' "${PROTEINS}")"

# Switch to the compleasm environment
conda deactivate
conda activate compleasm
compleasm --version

# Step 2: Run compleasm on the predicted proteins
compleasm \
  protein \
  -p "${PROTEINS}" \
  -o "${OUT_DIR}/dirofilaria_hic_asm.hic.hap1.p_ctg.PROTEINS.COMPLEASM" \
  -t "${THREADS}" \
  -l "${LINEAGE}" \
  -L "${DB_DIR}"

cat "${OUT_DIR}/dirofilaria_hic_asm.hic.hap1.p_ctg.PROTEINS.COMPLEASM/summary.txt"

echo ""
echo "Completed: $(date)"

