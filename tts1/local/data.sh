#!/usr/bin/env bash

set -e
set -u
set -o pipefail

data_name=$1

log() {
    local fname=${BASH_SOURCE[1]##*/}
    echo -e "$(date '+%Y-%m-%dT%H:%M:%S') (${fname}:${BASH_LINENO[0]}:${FUNCNAME[1]}) $*"
}
SECONDS=0

stage=0
stop_stage=2
threshold=45
nj=8

log "$0 $*"
# shellcheck disable=SC1091
. utils/parse_options.sh

if [ $# -ne 1 ]; then
    log "Error: No positional arguments are required."
    exit 2
fi

# shellcheck disable=SC1091
. ./path.sh || exit 1;
# shellcheck disable=SC1091
. ./cmd.sh || exit 1;
# shellcheck disable=SC1091
. ./db.sh || exit 1;

if [ -z "${data_name}" ]; then
#    log "Fill the value of ${data_name} of db.sh"
   log "Fill the value of ${data_name} of db.sh"
   
   exit 1
fi

# if [ -z "${noguchi}" ]; then
#    log "Fill the value of 'noguchi' of db.sh"
#    exit 1
# fi

db_root=dataset/student
# db_root=${noguchi}
train_set=tr_no_dev
dev_set=dev
eval_set=eval1


if [ ${stage} -le 0 ] && [ ${stop_stage} -ge 0 ]; then
    log "stage 0: local/data_prep.sh ${db_root}/${data_name}_voice_data"
    local/data_prep.sh "${db_root}/${data_name}_voice_data" data/${data_name}/all ${data_name}
fi

# if [ ${stage} -le 0 ] && [ ${stop_stage} -ge 0 ]; then
#     log "stage 0: local/data_prep.sh"
#     local/data_prep.sh "${db_root}/noguchi_voice_data" data/noguchi/all
# fi

if [ ${stage} -le 1 ] && [ ${stop_stage} -ge 1 ]; then
    log "stage 1: scripts/audio/trim_silence.sh"
    # shellcheck disable=SC2154
    scripts/audio/trim_silence.sh \
        --cmd "${train_cmd}" \
        --nj "${nj}" \
        --fs 44100 \
        --win_length 2048 \
        --shift_length 512 \
        --threshold "${threshold}" \
        data/${data_name}/all data/${data_name}/all/log
fi

# if [ ${stage} -le 1 ] && [ ${stop_stage} -ge 1 ]; then
#     log "stage 1: scripts/audio/trim_silence.sh"
#     # shellcheck disable=SC2154
#     scripts/audio/trim_silence.sh \
#         --cmd "${train_cmd}" \
#         --nj "${nj}" \
#         --fs 44100 \
#         --win_length 2048 \
#         --shift_length 512 \
#         --threshold "${threshold}" \
#         data/noguchi/all data/noguchi/all/log
# fi

if [ ${stage} -le 2 ] && [ ${stop_stage} -ge 2 ]; then
    log "stage 2: utils/subset_data_dir.sh"
    utils/subset_data_dir.sh data/${data_name}/all 4 data/${data_name}/deveval
    utils/subset_data_dir.sh --first data/${data_name}/deveval 2 "data/${data_name}/${dev_set}"
    utils/subset_data_dir.sh --last data/${data_name}/deveval 2 "data/${data_name}/${eval_set}"
    utils/copy_data_dir.sh data/${data_name}/all "data/${data_name}/${train_set}"
    utils/filter_scp.pl --exclude data/${data_name}/deveval/wav.scp \
        data/${data_name}/all/wav.scp > "data/${data_name}/${train_set}/wav.scp"
    utils/fix_data_dir.sh "data/${data_name}/${train_set}"
fi

# if [ ${stage} -le 2 ] && [ ${stop_stage} -ge 2 ]; then
#     log "stage 2: utils/subset_data_dir.sh"
#     utils/subset_data_dir.sh data/noguchi/all 2 data/noguchi/deveval
#     utils/subset_data_dir.sh --first data/noguchi/deveval 1 "data/noguchi/${dev_set}"
#     utils/subset_data_dir.sh --last data/noguchi/deveval 1 "data/noguchi/${eval_set}"
#     utils/copy_data_dir.sh data/noguchi/all "data/noguchi/${train_set}"
#     utils/filter_scp.pl --exclude data/noguchi/deveval/wav.scp \
#         data/noguchi/all/wav.scp > "data/noguchi/${train_set}/wav.scp"
#     utils/fix_data_dir.sh "data/noguchi/${train_set}"
# fi

log "Successfully finished. [elapsed=${SECONDS}s]"
