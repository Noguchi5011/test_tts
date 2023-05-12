group_num=$1

#1.Unzip dataset on "dataset/student/" directory.
#2.Rename "voice_text.txt" because it has a problem that "voice_text.txt" file name will chage to "voice_text.txt.txt" when execute unzip command. 
# we don't know why it's problem will happen

unzip dataset/student/${group_num}_voice_data.zip -d dataset/student/
mv dataset/student/${group_num}_voice_data/voice_text.txt.* dataset/student/${group_num}_voice_data/voice_text.txt

#run preprocess including data spliting,feature value extraction and create token list for finetuning
./run.sh \
    --stage 1 \
    --stop-stage 5 \
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
    --train_config ./conf/finetune_vits.yaml 

# change token list from default to finetuning

pyscripts/utils/make_token_list_from_config.py downloads/f3698edf589206588f58f5ec837fa516/exp/tts_train_vits_raw_phn_jaconv_pyopenjtalk_accent_with_pause/config.yaml
mv dump/student/$group_num/token_list/phn_jaconv_pyopenjtalk_accent_with_pause/tokens.{txt,txt.bak}
ln -s $(pwd)/downloads/f3698edf589206588f58f5ec837fa516/exp/tts_train_vits_raw_phn_jaconv_pyopenjtalk_accent_with_pause/tokens.txt dump/student/$group_num/token_list/phn_jaconv_pyopenjtalk_accent_with_pause/
