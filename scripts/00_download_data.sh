#!/bin/bash
#SBATCH --job-name=00_download_dirofilaria
#SBATCH -A ISAAC-UTK0505
#SBATCH --partition=short
#SBATCH --qos=short
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=2
#SBATCH --mem=16G
#SBATCH --time=02:00:00
#SBATCH --mail-type=BEGIN,END,FAIL
#SBATCH --mail-user=agonza84@utk.edu
#SBATCH --output=/lustre/isaac24/proj/UTK0505/agonza84/EPP622-2026-GenomeAnnotation/logs/00_download_dirofilaria_%A_%a.out
#SBATCH --error=/lustre/isaac24/proj/UTK0505/agonza84/EPP622-2026-GenomeAnnotation/logs/00_download_dirofilaria_%A_%a.err

set -euo pipefail

echo "=== DOWNLOADING RAW DATA FOR DIROFILARIA IMMITIS (BioProject PRJNA1245491) ==="
echo "Started: $(date)"
echo ""

# ------------------------------------------------------------------
# Data source (ENA)
#   BioProject : PRJNA1245491  (University of Melbourne, isolate JYD-34)
#   BioSample  : SAMN47757825  (one sample used for both libraries)
#   SRR32971245: PacBio Sequel IIe HiFi (CCS), 772,280 reads, 6.81 Gb
#   SRR32971244: Hi-C, Illumina NextSeq 2000, paired-end,
#                201,265,978 read pairs, 60.38 Gb
# ------------------------------------------------------------------

BASE_DIR="/lustre/isaac24/proj/UTK0505/agonza84/EPP622-2026-GenomeAnnotation"
RAW_DIR="${BASE_DIR}/raw_data"
ENA="https://ftp.sra.ebi.ac.uk/vol1/fastq/SRR329"

mkdir -p "${RAW_DIR}" "${BASE_DIR}/logs"
cd "${RAW_DIR}"

# Step 1: PacBio HiFi long reads (saved as SRR32971245.fastq.gz)
echo "--> 1. Downloading PacBio HiFi reads (SRR32971245)"
wget -c -nv -O SRR32971245.fastq.gz \
  "${ENA}/045/SRR32971245/SRR32971245_subreads.fastq.gz"

# Step 2: Hi-C paired-end reads
echo "--> 2. Downloading Hi-C reads, read 1 (SRR32971244_1)"
wget -c -nv -O SRR32971244_1.fastq.gz \
  "${ENA}/044/SRR32971244/SRR32971244_1.fastq.gz"

echo "--> 2. Downloading Hi-C reads, read 2 (SRR32971244_2)"
wget -c -nv -O SRR32971244_2.fastq.gz \
  "${ENA}/044/SRR32971244/SRR32971244_2.fastq.gz"

# Step 3: Verify file integrity against the MD5 values published by ENA
echo "--> 3. Verifying MD5 checksums"
cat > ena_md5.txt << 'EOF'
b68621e31e26b4fb1474e3b576f0ab2d  SRR32971245.fastq.gz
86ffe1170ebe812d0d6e170d4f406984  SRR32971244_1.fastq.gz
f8e380dae83b897a0cdda4e2f00bbd6d  SRR32971244_2.fastq.gz
EOF
md5sum -c ena_md5.txt

# Step 4: Download the published reference assembly (GCA_053925115.1,
# Campos et al. 2025) for evaluation of the assembly and annotation results. 
REF_DIR="${BASE_DIR}/reference"
NCBI="https://ftp.ncbi.nlm.nih.gov/genomes/all/GCA/053/925/115/GCA_053925115.1_ASM5392511v1"
mkdir -p "${REF_DIR}"
cd "${REF_DIR}"

echo "--> 4. Downloading published reference assembly (GCA_053925115.1)"
wget -c -nv "${NCBI}/GCA_053925115.1_ASM5392511v1_genomic.fna.gz"
wget -c -nv "${NCBI}/md5checksums.txt"
grep "_genomic.fna.gz" md5checksums.txt | # keep lines for *_genomic.fna.gz (genome + cds_from_genomic + rna_from_genomic)
  grep -v -e "_cds_" -e "_rna_" |  # -v removes the cds and rna lines
  sed 's#\./##' | # strip the "./" NCBI puts before the name 
  md5sum -c -  # -c recalculates the checksum and compares
            
# Uncompressed copy for bbmap and compleasm
zcat GCA_053925115.1_ASM5392511v1_genomic.fna.gz > dirofilaria_reference_GCA_053925115.1.fna

echo "--> 5.Final files" #check that all files are present 
ls -lh "${RAW_DIR}"/*.fastq.gz "${REF_DIR}"/*.fna

echo ""
echo "Completed: $(date)"
