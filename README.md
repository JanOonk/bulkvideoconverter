# Bulk Video Converter
A flexible and featured Bash shellscript that recursively scans a folder for files to convert/re-encode to different codec/encoder using ffmpeg.  

Tested on Ubuntu 20.04.2 LTS

## Context
I am using this script inside a Ubuntu docker container running on my Synology DS720+ NAS (Intel Celeron J4125 4-core CPU + 6GB). It daily converts all the MPEG2 recordings made by NextPVR with my HDHomeRun tuner.  
I am converting them to `libx264` which is generally about ~7x times smaller and converts at a 2.4x speed.  
Using `libx265` it's about ~12x times smaller and converts at a 0.7x speed.  

## Dependencies
Packages:  
`ffmpeg` - used for the actual conversion  
`ffprobe` - for getting stats like duration of videofile  
`bc` - for math calculations  

`jq` - for parsing the JSON videofile stats result of `ffprobe` - https://stedolan.github.io/jq/  

## Script Settings
`minFileAgeInSeconds=10`  
minimum fileage in seconds for inputfiles (that means how old is the file since last write) to be considered to get converted and for outputfiles to be checked if reconverting is needed  

`maxLengthDifferenceInSeconds=1`  
how much tolereance between inputfile and outputfile to be a match (means conversion is succesfull)  

`redoConversionWhenInputAndOutputDontMatch=true`  
Previous converted files which are not completed, got interrupted or failed can be redone when the inputfile and outputfile do not match  

`keepPreviousConversion=true`  
in some rare cases you can have an outputfile which has the same filename (without extension) as an inputfile, but doesn't have the same contents which is reflected in a different duration with this setting you can preserve these files the previous outputfile will have a suffix "-prev-v#" added  

`deleteOriginalFiles=true`  
after conversion delete original inputfile  

`multipleInstancesAllowed=false`  
is it allowed to have multiple instances running of this script (to be safe set to false)  

`runOnce=false`  
if false it will keep running and restart scanning automatically next day (script is never exited)  

`rerunAt="03 00"`  
if `runOnce` is false then rerun next day at this time HH MM  


## Script parameters
<pre>
Syntax is:  
 convertToMP4 [rootFolder] [filefilter] [encoder]  
  [rootFolder] root folder from where to start (recursively) to find files (mandatory), for example:  
    /videos  
  [filefilter] file filter (mandatory), for example:  
    *.ts  
    movie*.mpeg2  
  [encoder] any supported ffmpeg codec (optionally), for example:  
    libx264 (default)  
    libx265  

Supported ffmpeg encoders/codecs can be checked with:  
  ffmpeg -codecs  

 Examples how to run this script:  
  convertToMP4.sh /videos *.ts  
  convertToMP4.sh /videos *.ts libx264  
  convertToMP4.sh /videos *.ts libx265  
</pre>  
