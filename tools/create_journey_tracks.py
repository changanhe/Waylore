"""Create eight original synthesized instrumental miniatures; no sampled recordings."""
from pathlib import Path
import json, subprocess, wave
import numpy as np
OUT=Path('D:/Waylore/mobile/assets/audio'); SR=24000
TRACKS=[
 ('rain',57,68,[[0,3,7,10],[5,8,12,15],[8,12,15,19],[7,10,14,17]],'piano',[7,3,0,10,7,5,3,0]),
 ('sakura',72,94,[[0,4,7,11],[5,9,12,16],[2,5,9,12],[7,11,14,17]],'bell',[0,7,4,12,11,7,4,2]),
 ('trainride',60,108,[[0,4,7,12],[7,11,14,19],[9,12,16,19],[5,9,12,17]],'pluck',[0,4,7,4,9,7,4,2]),
 ('forestwalk',55,82,[[0,4,7,9],[5,9,12,14],[9,12,16,19],[7,11,14,16]],'wood',[0,7,9,4,2,7,4,0]),
 ('sunsetwalk',53,76,[[0,4,7,11],[9,12,16,19],[2,5,9,12],[7,11,14,17]],'pad',[4,7,11,7,4,2,0,7]),
 ('snowfall',74,62,[[0,4,7,11],[5,9,12,16],[9,12,16,19],[7,11,14,17]],'bell',[12,7,4,0,11,7,2,4]),
 ('coffeeshop',58,88,[[0,4,7,11],[9,12,16,19],[2,5,9,12],[7,11,14,17]],'piano',[7,11,9,7,4,2,5,4]),
 ('moonlit',50,56,[[0,3,7,10],[8,12,15,19],[5,8,12,15],[7,10,14,17]],'pad',[0,7,10,7,3,5,2,0]),
]
reports=[]
for index,(name,key,bpm,chords,timbre,motif) in enumerate(TRACKS):
 beat=60/bpm;bars=16;seconds=bars*4*beat;total=int((seconds+3)*SR);audio=np.zeros((total,2));rng=np.random.default_rng(2042+index)
 def add(start,span,midi,gain,kind,pan=0):
  pos=int(start*SR);n=min(int(span*SR),total-pos)
  if n<=0:return
  t=np.arange(n)/SR;freq=440*2**((midi-69)/12);phase=2*np.pi*freq*t
  if kind=='bell': wavelet=np.sin(phase)*np.exp(-t*1.2)+.3*np.sin(phase*2.76)*np.exp(-t*3)+.1*np.sin(phase*5.4)*np.exp(-t*5)
  elif kind=='piano':wavelet=(np.sin(phase)+.3*np.sin(phase*2)+.13*np.sin(phase*3)+.04*np.sin(phase*5))*np.exp(-t*1.7)
  elif kind=='wood':wavelet=(np.sin(phase)+.3*np.sin(phase*2.01)+.1*np.sin(phase*4))*np.exp(-t*4)
  elif kind=='pluck':wavelet=(np.sin(phase)+.35*np.sin(phase*2)+.15*np.sin(phase*3))*np.exp(-t*3)
  else:wavelet=(np.sin(phase)+.3*np.sin(phase*1.002)+.1*np.sin(phase*2))*np.minimum(t/.3,1)*np.exp(-t*.25)
  envelope=np.minimum(t/.014,1)*np.minimum((span-t)/.25,1)
  wavelet*=envelope*gain;audio[pos:pos+n,0]+=wavelet*np.sqrt((1-pan)/2);audio[pos:pos+n,1]+=wavelet*np.sqrt((1+pan)/2)
 for bar in range(bars):
  start=bar*beat*4;chord=chords[bar%4]
  for j,note in enumerate(chord): add(start+j*.025,beat*3.9,key-12+note,.04 if timbre!='pad' else .035,'pad',(j-1.5)*.35)
  add(start,beat*3.8,key-24+chord[0],.07,'piano')
  if name in ('trainride','forestwalk','coffeeshop'):
   for step in range(8):
    swing=.12*beat if name=='coffeeshop' and step%2 else 0
    add(start+step*beat/2+swing,beat*1.7,key+chord[step%4],.075,'wood' if name=='forestwalk' else 'pluck',(-1 if step%2 else 1)*.4)
  for step in range(4):
   mi=motif[(bar*3+step)%len(motif)];octave=0 if bar<8 else -12
   if name=='snowfall' and step==3:continue
   add(start+step*beat+(beat*.15 if step%2 and name=='coffeeshop' else 0),beat*2.4,key+mi+octave,.105,timbre,(-.3 if step%2 else .3))
  if name in ('trainride','coffeeshop'):
   for step in range(8):
    pos=int((start+step*beat/2)*SR);n=int(.08*SR);t=np.arange(n)/SR
    noise=rng.normal(0,1,n);noise=np.diff(noise,prepend=0)*np.exp(-t*65)*.009
    audio[pos:pos+n,:]+=noise[:,None]
 for delay,gain in [(.21,.16),(.43,.09),(.69,.05)]:
  off=int(delay*SR);audio[off:]+=audio[:-off,::-1]*gain
 audio=audio[:int(seconds*SR)];t=np.arange(len(audio))/SR
 audio*= (np.minimum(t/1.4,1)*np.minimum((seconds-t)/2.5,1))[:,None]
 peak=float(np.max(np.abs(audio)));audio*=.72/max(peak,1e-6)
 rms=float(np.sqrt(np.mean(audio*audio)));wav=OUT/(name+'.wav');mp3=OUT/(name+'.mp3')
 with wave.open(str(wav),'wb') as f:f.setnchannels(2);f.setsampwidth(2);f.setframerate(SR);f.writeframes((audio*32767).astype('<i2').tobytes())
 subprocess.run(['ffmpeg','-y','-loglevel','error','-i',str(wav),'-codec:a','libmp3lame','-b:a','112k',str(mp3)],check=True);wav.unlink()
 reports.append({'track':name,'duration':round(seconds,2),'rms':round(rms,4),'peak':.72,'bytes':mp3.stat().st_size})
 print(name,round(seconds,1),flush=True)
Path('D:/Waylore/build/new-tracks-report.json').write_text(json.dumps(reports,indent=2))
