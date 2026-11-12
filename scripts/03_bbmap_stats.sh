#!/bin/bash
#SBATCH --job-name=03_bbmap_stats
#SBATCH -A ISAAC-UTK0505
#SBATCH --partition=short
#SBATCH --qos=short
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=2
#SBATCH --mem=8G
#SBATCH --time=00:30:00
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --mail-user=agonza84@utk.edu
#SBATCH --output=/lustre/isaac24/proj/UTK0505/agonza84/EPP622-2026-GenomeAnnotation/logs/03_bbmap_stats_%j.out
#SBATCH --error=/lustre/isaac24/proj/UTK0505/agonza84/EPP622-2026-GenomeAnnotation/logs/03_bbmap_stats_%j.err

set -euo pipefail

echo "=== CONTIGUITY STATISTICS WITH BBMAP (stats.sh) ==="
echo "Started: $(date)"
echo ""

eval "$(conda shell.bash hook)"
conda activate assembly  #use this environment because it has bbmap installed

BASE_DIR="/lustre/isaac24/proj/UTK0505/agonza84/EPP622-2026-GenomeAnnotation"
ASM_DIR="${BASE_DIR}/results/02_assembly"
OUT_DIR="${BASE_DIR}/results/03_bbmap_stats"
mkdir -p "${OUT_DIR}"
cd "${OUT_DIR}"

# Assemblies to evaluate: two phased haplotypes + the published reference
HAP1="${ASM_DIR}/dirofilaria_hic_asm.hic.hap1.p_ctg.fasta"
HAP2="${ASM_DIR}/dirofilaria_hic_asm.hic.hap2.p_ctg.fasta"
REF="${BASE_DIR}/reference/dirofilaria_reference_GCA_053925115.1.fna"

# Step 1: Full stats.sh report for each assembly 
for ASM in "${HAP1}" "${HAP2}" "${REF}"; do
  STATS=$(basename "${ASM}" | sed -E 's/\.(fasta|fna)$/.stats.txt/')
  stats.sh -Xmx8g in="${ASM}" > "${OUT_DIR}/${STATS}"
  echo "${ASM} -> ${STATS}"
done

# Step 2: One tab-delimited table with one row per assembly (format=3)
statswrapper.sh -Xmx8g in="${HAP1},${HAP2},${REF}" format=3 > "${OUT_DIR}/dirofilaria_contiguity_summary.tsv"

column -t "${OUT_DIR}/dirofilaria_contiguity_summary.tsv"

echo ""
echo "Completed: $(date)"

