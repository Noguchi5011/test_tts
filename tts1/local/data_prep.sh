#!/usr/bin/env bash

db_root=$1
data_dir=$2
group_name=$3

# check arguments
if [ $# != 3 ]; then
    echo "Usage: $0 <db_root> <data_dir> <group_name>"
    echo "e.g.: $0 ${group_name}_voice_data/train"
    exit 1
fi

set -euo pipefail

# check directory existence
[ ! -e "${data_dir}" ] && mkdir -p "${data_dir}"

# set filenames
scp=${data_dir}/wav.scp
utt2spk=${data_dir}/utt2spk
spk2utt=${data_dir}/spk2utt
text=${data_dir}/text

# check file existence
[ -e "${scp}" ] && rm "${scp}"
[ -e "${utt2spk}" ] && rm "${utt2spk}"
[ -e "${text}" ] && rm "${text}"

# make scp, utt2spk, and spk2utt
find "${db_root}/voice" -name "*.wav" | sort | while read -r filename; do
    id=${group_name}_$(basename "${filename}" | sed -e "s/\.[^\.]*$//g")
    echo "${id} sox \"${filename}\" -r 44100 -t wav -c 1 -b 16 - |" >> "${scp}"
    echo "${id} ${group_name}" >> "${utt2spk}"
done
utils/utt2spk_to_spk2utt.pl "${utt2spk}" > "${spk2utt}"
echo "Successfully finished making wav.scp, utt2spk, spk2utt."

# make text
find "${db_root}" -name "*.txt" | grep "voice_text" | while read -r filename; do
    awk -F ":" -v spk=${group_name} '{print spk "_" $1 " " $2}' < "${filename}" | sort >> "${text}"
done
echo "Successfully finished making text."

utils/fix_data_dir.sh "${data_dir}"
echo "Successfully finished preparing data directory."
