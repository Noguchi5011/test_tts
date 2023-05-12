from espnet2.bin.tts_inference import Text2Speech
import time
import torch
import soundfile as sf
import sys
# Web APIを作成するためのライブラリ
from fastapi import FastAPI
from fastapi.responses import FileResponse
import uvicorn

app = FastAPI()

fs, lang = 44100, "Japanese"

def tts(text, model='tsukuyomi'):

    test_model = "exp/{model_name}/train.total_count.ave_10best.pth"
    use_model = test_model.format(model_name=model)
    print(use_model)
    text2speech = Text2Speech.from_pretrained(
        model_file=use_model,
        device="cpu",
        speed_control_alpha=1.0,
        noise_scale=0.333,
        noise_scale_dur=0.333,
    )

    with torch.no_grad():
        start = time.time()
        wav = text2speech(text)["wav"]
    rtf = (time.time() - start) / (len(wav) / text2speech.fs)
    print(f"RTF = {rtf:5f}")

    wavdata = wav.view(-1).cpu().numpy()
    samplerate=text2speech.fs

    soundname = "gen_wav/{model_name}_{text_name}.wav"
    filename = soundname.format(model_name=model, text_name=text)
    print(filename)
    return(filename, wavdata, samplerate)

@app.get("/submit/")
def retAudio(text: str, model: str = 'tsukuyomi'):
    print(model)
    writefile, wavedata, samplerates = tts(text, model)
    sf.write(writefile, wavedata, samplerates)
    return FileResponse(path = writefile, filename = writefile)

if __name__ == '__main__':
    args = sys.argv
    if(len(args) == 3):
        writefile, wavedata, samplerates = tts(args[1], args[2])
    else:
        writefile, wavedata, samplerates = tts(args[1])
    sf.write(writefile, wavedata, samplerates)
