# Bulk Video Converter
A flexible and featured Bash shellscript that recursively scans a folder for files to convert/re-encode to different codec/encoder using ffmpeg.
Tested on Ubuntu 20.04.2 LTS

## Dependencies
`ffmpeg` - used for the actual conversion  
`ffprobe` - for getting stats like duration of videofile  
`jq` - for parsing the JSON videofile stats result of `ffprobe`  
`bc` - for math calculations  

## Script Settings
`minFileAgeInSeconds=10`  
minimum fileage in seconds for inputfiles (that means how old is the file since last write) to be considered to get converted and for outputfiles to be checked if reconverting is needed  

`maxLengthDifferenceInSeconds=1`  
`redoConversionWhenInputAndOutputDontMatch=true`  
how much tolereance between inputfile and outputfile to be a match (means conversion is succesfull)  

`keepPreviousConversion=true`  
in some rare cases you can have an outputfile which has the same filename (without extension) as an inputfile, but doesn't have the same contents which is reflected in a different duration with this setting you can preserve these files the previous outputfile will have a suffix "-prev-v#" added  

`deleteOriginalFiles=true`  
after conversion delete original inputfile  

`multipleInstancesAllowed=false`  
is it allowed to have multiple instances running of this script (to be safe set to false)  

`runOnce=false`  
if false it will keep running and restart scanning automatically next day (script is never exited)  

`rerunAt="03 00"`  
if runOnce is false then rerun next day at this time HH MM  
