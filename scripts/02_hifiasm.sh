#!/bin/bash
#SBATCH --job-name=02_hifiasm
#SBATCH -A ISAAC-UTK0505
#SBATCH --partition=short
#SBATCH --qos=short
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=40
#SBATCH --mem=120G
#SBATCH --time=03:00:00
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --mail-user=agonza84@utk.edu
#SBATCH --output=/lustre/isaac24/proj/UTK0505/agonza84/EPP622-2026-GenomeAnnotation/logs/02_hifiasm_%j.out
#SBATCH --error=/lustre/isaac24/proj/UTK0505/agonza84/EPP622-2026-GenomeAnnotation/logs/02_hifiasm_%j.err

set -euo pipefail

echo "=== HIFIASM GENOME ASSEMBLY (HiFi + Hi-C) ==="
echo "Started: $(date)"
echo ""

eval "$(conda shell.bash hook)"
conda activate assembly

BASE_DIR="/lustre/isaac24/proj/UTK0505/agonza84/EPP622-2026-GenomeAnnotation"
OUT_DIR="${BASE_DIR}/results/02_assembly"
HIFI_READS="${BASE_DIR}/results/01_fastplong/dirofilaria_hifi_clean.fastq.gz"
HIC_R1="${BASE_DIR}/results/01_fastp_hic/dirofilaria_hic_trimmed_R1.fastq.gz"
HIC_R2="${BASE_DIR}/results/01_fastp_hic/dirofilaria_hic_trimmed_R2.fastq.gz"
PREFIX="dirofilaria_hic_asm"
THREADS="${SLURM_CPUS_PER_TASK:-40}"

mkdir -p "${OUT_DIR}"
cd "${OUT_DIR}"

# Step 1: Assemble with hifiasm in Hi-C integrated mode
#   -o: prefix
#   -t: threads
#   --hg-size 94m : genome size (from published info; 94,056,743 bp)
#   --n-hap 2     : D. immitis is diploid
#   --n-weight 10 : rounds of Hi-C reweightin
#   --f-perturb 0.25 : fraction of the genome to "flip" in each perturbation
#   --n-perturb 100000 : number of perturbation rounds
#   --h1/--h2     : trimmed Hi-C read 1 and read 2

hifiasm \
  -o "${PREFIX}" \
  -t "${THREADS}" \
  --hg-size 94m \
  --n-hap 2 \
  --n-weight 10 \
  --f-perturb 0.25 \
  --n-perturb 100000 \
  --h1 "${HIC_R1}" \
  --h2 "${HIC_R2}" \
  "${HIFI_READS}" \
  >& "${OUT_DIR}/hifiasm_hgsize94m_nhap2_nweight10_fperturb0.25_nperturb100k.log"

# Step 2: Convert GFA produced to FASTA.
#   dirofilaria_hic_asm.hic.hap1.p_ctg.gfa and dirofilaria_hic_asm.hic.hap2.p_ctg.gfa
echo "--> Converting GFA to FASTA with gfatools"
for GFA in "${PREFIX}".*p_ctg.gfa; do   # loop over every contig produced by hifiasm
  FASTA=$(basename "${GFA}" .gfa).fasta # .gfa -> .fasta
  gfatools gfa2fa "${GFA}" > "${FASTA}" # extract the sequences (S lines) to FASTA
  echo "${GFA} -> ${FASTA}"             # record in the log which file became which
done

ls -lh "${OUT_DIR}"/*.gfa "${OUT_DIR}"/*.fasta

echo ""
echo "Completed: $(date)"
