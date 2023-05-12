group_num=$1

#run finetuning
./run.sh \
    --stage 6 \
    --g2p pyopenjtalk_accent_with_pause \
    --min_wav_duration 0.38 \
    --fs 22050 \
    --n_fft 1024 \
    --n_shift 256 \
    --group_num $group_num \
    --dumpdir dump/student/$group_num \
    --win_length null \
    --tts_task gan_tts \
    --feats_extract linear_spectrogram \
    --feats_normalize none \
    --train_config ./conf/finetune_vits.yaml  \
    --train_args "--init_param downloads/f3698edf589206588f58f5ec837fa516/exp/tts_train_vits_raw_phn_jaconv_pyopenjtalk_accent_with_pause/train.total_count.ave_10best.pth:tts:tts" \
    --tag $group_num \
    --inference_model train.total_count.ave_10best.pth

#export some log files

    mkdir -p log/${group_num}/
    mkdir -p log/${group_num}/tsukuyomi
    cp exp/tsukuyomi/train.log log/${group_num}/tsukuyomi/
    mv log/${group_num}/tsukuyomi/train.log log/${group_num}/tsukuyomi/tsukuyomi_train.log
    mkdir -p log/${group_num}/noguchi
    cp exp/noguchi/train.log log/${group_num}/noguchi/
    mv log/${group_num}/noguchi/train.log log/${group_num}/noguchi/noguchi_train.log
    mkdir -p log/${group_num}/JVS010
    cp exp/JVS010/train.log log/${group_num}/JVS010/
    mv log/${group_num}/JVS010/train.log log/${group_num}/JVS010/JVS010_train.log
    mkdir -p log/${group_num}/${group_num}
    cp exp/${group_num}/train.log log/${group_num}/${group_num}/
    mv log/${group_num}/${group_num}/train.log log/${group_num}/${group_num}/${group_num}_train.log

# copy log files for /home/{user_name}/log
mkdir -p ~/log
mkdir -p ~/log/${group_num}  
cp -r log/${group_num}/* ~/log/${group_num}/
