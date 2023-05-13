## General lib
import re
import sys
import subprocess

## Some lib for tts prediction and generate wav file
from espnet2.bin.tts_inference import Text2Speech
import time
import torch
import soundfile as sf

## Some lib for build Web API
from fastapi import FastAPI, status
from fastapi.responses import FileResponse
from fastapi.responses import JSONResponse 
import uvicorn

app = FastAPI()

fs, lang = 44100, "Japanese"

def run_tts(text: str, model: str='tsukuyomi'):
    '''
    [INPUT]
    text : str, The text you want to talk message for tts model.
    model : str, A model names. (e.g.) tsukuyomi, noguchi, JVS010, jvs01 

    [OUTPUT]
    zip file (via FileResponse(path, finename) )
    '''

    use_model = f'exp/{model}/train.total_count.ave_10best.pth'

    ## predicate speach generation task using tts model
    text2speech = Text2Speech.from_pretrained(
        model_file=use_model,
        device="cpu",
        speed_control_alpha=1.0,
        noise_scale=0.333,
        noise_scale_dur=0.333,)

    ## postprocessing
    with torch.no_grad():
        start = time.time()
        pred_wav = text2speech(text)["wav"]

    rtf = (time.time() - start) / (len(pred_wav) / text2speech.fs)

    raw_wav = pred_wav.view(-1).cpu().numpy()
    sample_rate=text2speech.fs

    file_name = f'gen_wav/{model}_{text}.wav'

    return(file_name, raw_wav, sample_rate)


@app.get("/train/")
def finetuning(group_name: str):
    '''
    [INPUT]
    group_name : str, The group name. (e.g.) A-team group-1 -> "A_1"

    [OUTPUT]
    zip file (via FileResponse(path, finename) )

    '''
    pattern = re.match("^[A-H]_[1-8]$", group_name)
    ## Error handling
    if pattern == None:
        return JSONResponse( 
            status_code=status.HTTP_401_UNAUTHORIZED, 
            content={"message": f'Review your group name : {group_name}. Defferent format.'} )

    ## Run preprocess.sh
    pp_res = subprocess.run(["preprocess.sh", group_name], stdout=subprocess.PIPE, text=True)
    
    ## Run finetuning.sh
    ft_res = subprocess.run(["finetuning.sh", group_name], stdout=subprocess.PIPE, text=True)
    
    ## Compress some train log files
    comp_res = subprocess.run(["compression.sh", group_name], stdout=subprocess.PIPE, text=True) 

    zip_file_path = "log/zip_files/"
    zip_file_name = f"{group_name}.zip"

    return FileResponse(path=zip_file_path, filename=zip_file_name)

@app.get("/submit/")
def retAudio(text: str, model: str='tsukuyomi'):
    '''
    [INPUT]
    text : str, The text you want to talk message for tts model.
    model : str, A model names. (e.g.) tsukuyomi, noguchi, JVS010, jvs01 

    [OUTPUT]
    zip file (via FileResponse(path, finename) )

    '''

    write_file_name, wav_data, sample_rate = run_tts(text, model)
    sf.write(write_file_name, wav_data, sample_rate)

    return FileResponse(path=write_file_name, filename=write_file_name)

if __name__ == '__main__':
    args = sys.argv

    if(len(args) == 3):
        write_file_name, wav_data, sample_rate = tts(args[1], args[2])
    else:
        write_file_name, wav_data, sample_rate = tts(args[1])

    sf.write(write_file_name, wav_data, sample_rate)







