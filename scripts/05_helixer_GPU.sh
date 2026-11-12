#!/bin/bash
#SBATCH --job-name=05_helixer_GPU
#SBATCH -A ISAAC-UTK0505
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=10
#SBATCH --mem=50G
#SBATCH --gpus-per-node=v100s:1
#SBATCH --partition=campus-gpu
#SBATCH --qos=campus-gpu
#SBATCH --time=03:00:00
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --mail-user=agonza84@utk.edu
#SBATCH --output=/lustre/isaac24/proj/UTK0505/agonza84/EPP622-2026-GenomeAnnotation/logs/05_helixer_GPU_%j.out
#SBATCH --error=/lustre/isaac24/proj/UTK0505/agonza84/EPP622-2026-GenomeAnnotation/logs/05_helixer_GPU_%j.err

set -euo pipefail

echo "=== GENE ANNOTATION WITH HELIXER (GPU, APPTAINER CONTAINER) ==="
echo "Started: $(date)"
echo ""

eval "$(conda shell.bash hook)"
conda activate annotation

BASE_DIR="/lustre/isaac24/proj/UTK0505/agonza84/EPP622-2026-GenomeAnnotation"
CONTAINER="${BASE_DIR}/containers/helixer_v0.3.2_cuda_11.8.0-cudnn8.sif"
ASM="${BASE_DIR}/results/02_assembly/dirofilaria_hic_asm.hic.hap1.p_ctg.fasta"
OUT_DIR="${BASE_DIR}/results/05_helixer"
mkdir -p "${OUT_DIR}"
cd "${OUT_DIR}"

# Show which GPU was assigned
nvidia-smi || echo "No GPU visible"

# Step 1: Predict gene models on haplotype 1 with Helixer inside the container
#   apptainer exec -B : bind the project folder so the container can see our files
#   --nv : give the container access to the NVIDIA GPU
#   --lineage invertebrate : Helixer model for invertebrates (nematodes)
#   --species : name used in the GFF3
#   --gff-output-path : final GFF3 annotation
apptainer exec \
  --nv \
  -B "${BASE_DIR}" \
  "${CONTAINER}" \
  Helixer.py \
    --lineage invertebrate \
    --fasta-path "${ASM}" \
    --species Dirofilaria_immitis \
    --gff-output-path "${OUT_DIR}/dirofilaria_hic_asm.hic.hap1.p_ctg.gff3"

# Step 2: Quick check of the feature types and counts in the GFF3
echo "--> Feature counts"
grep -v "^#" "${OUT_DIR}/dirofilaria_hic_asm.hic.hap1.p_ctg.gff3" | cut -f3 | sort | uniq -c

echo ""
echo "Completed: $(date)"

