#!/bin/bash
#SBATCH --job-name=04_compleasm_nt
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
#SBATCH --output=/lustre/isaac24/proj/UTK0505/agonza84/EPP622-2026-GenomeAnnotation/logs/04_compleasm_nt_%j.out
#SBATCH --error=/lustre/isaac24/proj/UTK0505/agonza84/EPP622-2026-GenomeAnnotation/logs/04_compleasm_nt_%j.err

set -euo pipefail

echo "=== ASSEMBLY COMPLETENESS WITH COMPLEASM (NUCLEOTIDE MODE) ==="
echo "Started: $(date)"
echo ""

eval "$(conda shell.bash hook)"
conda activate compleasm
compleasm --version

BASE_DIR="/lustre/isaac24/proj/UTK0505/agonza84/EPP622-2026-GenomeAnnotation"
ASM_DIR="${BASE_DIR}/results/02_assembly" #input assemblies
OUT_DIR="${BASE_DIR}/results/04_compleasm_nt"
DB_DIR="${BASE_DIR}/databases/compleasm_mb"   # lineage files downloaded
LINEAGE="nematoda_odb12" #lineage to use for completeness assessment (BUSCO proteins)
THREADS="${SLURM_CPUS_PER_TASK:-12}"

mkdir -p "${OUT_DIR}" "${DB_DIR}"
cd "${OUT_DIR}"

compleasm --version

# Step 1: Run compleasm in nucleotide mode ("compleasm run": BUSCO proteins
# are aligned to the genome with miniprot) on each assembly.
#I use a loop to run compleasm on each assembly
for ASM in \
  "${ASM_DIR}/dirofilaria_hic_asm.hic.hap1.p_ctg.fasta" \
  "${ASM_DIR}/dirofilaria_hic_asm.hic.hap2.p_ctg.fasta" \
  "${BASE_DIR}/reference/dirofilaria_reference_GCA_053925115.1.fna"
do
  OUTNAME=$(basename "${ASM}" | sed -E 's/\.(fasta|fna)$/.COMPLEASM/')
  echo "--> compleasm run: ${ASM} -> ${OUTNAME}"
  compleasm \
    run \
    -a "${ASM}" \
    -o "${OUT_DIR}/${OUTNAME}" \
    -t "${THREADS}" \
    -l "${LINEAGE}" \
    -L "${DB_DIR}"
done

# Step 2: Summaries
for SUMMARY in "${OUT_DIR}"/*.COMPLEASM/summary.txt; do
  echo "===== ${SUMMARY} ====="
  cat "${SUMMARY}"
done

echo ""
echo "Completed: $(date)"

