group_name=$1


# We compress some log files for api return. 

cd ~/espnet2/tts1/log
zip -r zip_files/${group_name}.zip ${group_name}
cd ~/espnet2/tts1
