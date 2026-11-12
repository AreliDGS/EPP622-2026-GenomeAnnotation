#!/bin/bash
#SBATCH --job-name=07_agat_summary
#SBATCH -A ISAAC-UTK0505
#SBATCH --partition=short
#SBATCH --qos=short
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=2
#SBATCH --mem=15G
#SBATCH --time=01:00:00
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --mail-user=agonza84@utk.edu
#SBATCH --output=/lustre/isaac24/proj/UTK0505/agonza84/EPP622-2026-GenomeAnnotation/logs/07_agat_summary_%j.out
#SBATCH --error=/lustre/isaac24/proj/UTK0505/agonza84/EPP622-2026-GenomeAnnotation/logs/07_agat_summary_%j.err

set -euo pipefail

echo "=== ANNOTATION STATISTICS (AGAT) AND SUMMARY TABLES ==="
echo "Started: $(date)"
echo ""

eval "$(conda shell.bash hook)"
conda activate agat

BASE_DIR="/lustre/isaac24/proj/UTK0505/agonza84/EPP622-2026-GenomeAnnotation"
OUT_DIR="${BASE_DIR}/results/07_summary"
GFF="${BASE_DIR}/results/05_helixer/dirofilaria_hic_asm.hic.hap1.p_ctg.gff3"
AGAT_STATS="${OUT_DIR}/dirofilaria_hic_asm.hic.hap1.p_ctg.agat_stats.txt"

NT_HAP1="${BASE_DIR}/results/04_compleasm_nt/dirofilaria_hic_asm.hic.hap1.p_ctg.COMPLEASM/summary.txt"
NT_HAP2="${BASE_DIR}/results/04_compleasm_nt/dirofilaria_hic_asm.hic.hap2.p_ctg.COMPLEASM/summary.txt"
NT_REF="${BASE_DIR}/results/04_compleasm_nt/dirofilaria_reference_GCA_053925115.1.COMPLEASM/summary.txt"
PROT_HAP1="${BASE_DIR}/results/06_compleasm_protein/dirofilaria_hic_asm.hic.hap1.p_ctg.PROTEINS.COMPLEASM/summary.txt"

mkdir -p "${OUT_DIR}"
cd "${OUT_DIR}"

# ------------------------------------------------------------------
# Step 1: Annotation statistics with AGAT
# ------------------------------------------------------------------
agat_sp_statistics.pl \
  --gff "${GFF}" \
  -o "${AGAT_STATS}"

# ------------------------------------------------------------------
# Step 2: Create table of gene count, mean gene length, mean exons per gene, and compare to published reference (Campos et al. 2025)
# ------------------------------------------------------------------
read -r GENES MRNAS EXONS MEAN_GENE_LEN < <(
  awk -F'\t' '
    $3=="gene" {g++; glen += $5 - $4 + 1}
    $3=="mRNA" {m++}
    $3=="exon" {e++}
    END {printf "%d %d %d %.1f\n", g, m, e, glen/g}' "${GFF}")
EXONS_PER_GENE=$(awk -v e="${EXONS}" -v g="${GENES}" 'BEGIN{printf "%.2f", e/g}')

# Values reported by AGAT (first match of each line in the stats file)
agat_value() { grep -i -m1 "$1" "${AGAT_STATS}" | awk '{print $NF}'; }

TABLE_B="${OUT_DIR}/annotation_summary.md"
{
  echo "| Metric | AGAT (hap1) | awk check (hap1) | Published (Campos et al. 2025) |"
  echo "|---|---|---|---|"
  echo "| Protein-coding genes | $(agat_value 'Number of gene ') | ${GENES} | 11,852 |"
  echo "| Transcripts (mRNA) | $(agat_value 'Number of mrna ') | ${MRNAS} | 14,247 |"
  echo "| Mean gene length (bp) | $(agat_value 'mean gene length') | ${MEAN_GENE_LEN} | 4,447 |"
  echo "| Mean exons per gene | $(agat_value 'mean exons per mrna') | ${EXONS_PER_GENE} | 9.4 |"
  echo "| Single-exon genes | $(agat_value 'Number of single exon gene') | – | not reported |"
} > "${TABLE_B}"

# ------------------------------------------------------------------
# Step 3: compleasm completeness table, nucleotide vs protein
# compleasm summary.txt lines look like:  S:97.73%, 4390
# ------------------------------------------------------------------
cell() {  # $1 = summary.txt, $2 = category letter -> "97.73% (4390)"
  grep -E "^$2:" "$1" | sed -E 's/^[A-Z]:([0-9.]+)%, *([0-9]+).*/\1% (\2)/' || echo "–"
}
complete() {  # S + D
  awk -F'[:%,]' '/^S:/{s=$2} /^D:/{d=$2} END{printf "%.2f%%", s+d}' "$1"
}

TABLE_A="${OUT_DIR}/completeness_nucleotide_vs_protein.md"
{
  echo "| Category | Nucleotide: hap1 | Nucleotide: hap2 | Nucleotide: published reference | Protein: Helixer hap1 |"
  echo "|---|---|---|---|---|"
  echo "| Complete (S + D) | $(complete "$NT_HAP1") | $(complete "$NT_HAP2") | $(complete "$NT_REF") | $(complete "$PROT_HAP1") |"
  for cat in S D F I M; do
    case $cat in
      S) label="Single-copy (S)";; D) label="Duplicated (D)";; F) label="Fragmented (F)";;
      I) label="Incomplete (I)";; M) label="Missing (M)";;
    esac
    echo "| ${label} | $(cell "$NT_HAP1" $cat) | $(cell "$NT_HAP2" $cat) | $(cell "$NT_REF" $cat) | $(cell "$PROT_HAP1" $cat) |"
  done
  echo "| Total BUSCOs (N) | $(grep -E '^N:' "$NT_HAP1" | cut -d: -f2) | $(grep -E '^N:' "$NT_HAP2" | cut -d: -f2) | $(grep -E '^N:' "$NT_REF" | cut -d: -f2) | $(grep -E '^N:' "$PROT_HAP1" | cut -d: -f2) |"
} > "${TABLE_A}"

cat "${TABLE_A}"
echo ""
cat "${TABLE_B}"

echo ""
echo "Completed: $(date)"

