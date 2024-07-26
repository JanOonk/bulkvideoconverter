# Bulk Video Converter
A flexible and featured Bash shellscript that recursively scans folders for certain video files and convert/re-encode them to a different codec using ffmpeg.  
It can run just once or every time at (or after) a certain time(period). For other features see `Script Settings`.

## Context
I am using this script inside a Jellyfin Debian docker container running on my Synology NAS.
I tested it both directly and inside Jellyfin container:
-on my older DS720+ NAS (Intel Celeron J4125 4-core CPU + 6GB) which support hardware acceleration using vaapi or qsv.
-on my newer DS923+ (AMD Ryzen R1600 2-core CPU + 16GB) which sadly didn't have hardware acceleration.

It daily converts all the MPEG2 recordings made by NextPVR with my HDHomeRun tuner to H.265 MP4 using vaapi hardware acceleration.

## Dependencies
Packages:  
`ffmpeg` - used for the actual video conversion  
`bc` - for math calculations  

```
sudo apt update
sudo apt install ffmpeg bc
ffmpeg -version
bc -version
```

## Installation

Easiest way to get the ffmpeg dependencies and even have hardware acceleration on your Synology NAS (if supported) is by running a Jellyfin docker container from `https://hub.docker.com/r/jellyfin/jellyfin`.
See next paragraph. Else you should install dependencies manually.

1. `git clone https://github.com/JannemanDev/bulkvideoconverter.git` 
2. install dependencies (see above)
3. copy `settings.default.sh` to `settings.sh` and adapt it
4. optionally implement a post run script (see `postRun.example.sh`)
5. `convertVideos.sh`

## How to use on Synology NAS

If you want to run this on Synology and use Jellyfin (which includes ffmpeg and has hardware acceleration if your NAS supports it) follow these steps:
1. Create an `Apps` Shared Folder first (see `Control Panel > Shared Folder`)
2. Optional: Install `Git` (not `Git Server`!) package for easy repo cloning (or just download sources and unpack it)
3. Optional: if you want to run directly on NAS and not using Jellyfin docker container you also need `SynoCli misc. Tools` (Community) package for `bc` dependency. Goto `Control Panel > Package Center` to install.
4. SSH into your NAS (for example by using Putty) and then goto the created Shared Folder: `cd /volume1/Apps/`
5. Follow the steps above from `Installation`

To have the Jellyfin container autostart at NAS boot up and also auto start the bulkvideoconverter use:
1. Under `Control Panel > Task Scheduler` create a `Triggered Task > User defined script`
2. Use these General Settings: `User: root`, `Event: Boot-up`
3. Use these Task Settings: `User-defined script: /volume1/Apps/bulkvideoconverter/startDockerContainer.sh`

Create a Jellyfin docker container (using DSM 7)
1. Install `Container Manager` from `Package Center`
2. Start `Container Manager`
3. Registry > Search edit box > jellyfin
4. Download
5. Container > Create > Image: jellyfin/jellyfin:latest
6. Next
7. Volume Settings > Add Folder: expand the Shared Folder from step 1 of `Installation` and search for the installation folder. Map this folder for this container to `/Apps`.
8. Volume Settings > Add Folder: search your video folder. Map this folder for this container to `/videos`.

## Benchmarking different encoders

If you want to easily benchmark the converting of videos with different encoders goto `/benchmark` folder:
1. adjust settings in `settings-benchmarks.sh`
2. adjust the `benchmark settings` section in `benchmarkConvertVideosLogged.sh` 
3. run one of the `runBenchmark*.sh` predefined scripts or adapt it to use different encoders (see supported encoders by running `ffmpeg -encoders`)
4. converted videos will be saved in the same folder as the source videofile(s) and the time it took to convert (and other details) can be found in `benchmark.txt`

## Different encoders

Supported ffmpeg encoders can be checked with:  
  `ffmpeg -encoders`

Encoders benchmark results:
![test](https://github.com/JannemanDev/bulkvideoconverter/blob/b0deae5074e642f6cad04898c1bc9c32eae38bc3/Encoders%20benchmark%20results/Encoders%20benchmark%20results.png)
  
## Script Settings

All settings can be set using a shellscript. By default `convertVideos.sh` will search for `settings.sh`.

```shellscript
# ---- BEGIN OF SETTINGS ----

# full path to ffmpeg (here using Docker environment variable)
ffmpeg=$JELLYFIN_FFMPEG

# if no searchFolder -sf argument is given when script is called these searchFolders will be used (enter/space seperated)
defaultSearchDirectories=(
	"/videos/"
)

# if no fileFilter -ff argument is given when script is called these fileFilters will be used (enter/space seperated)
defaultFileFilters=(
	"*.ts"
)

# if no logFile -lf argument is given when script is called this logFile will be used
defaultLogFile="convertVideos-logfile.txt"

# if no encoder argument is given when script is called this encoder will be used
# These encoders has been tested on Synology DS713+ using Docker:
#  libx264 
#  h264_vaapi
#  libx265 
#  hevc_vaapi
#  hevc_qsv 
#
# But all encoders your ffmpeg installation supports should work, see `ffmpeg -encoders` or when using Jellyfin `$JELLYFIN_FFMPEG -encoders`
defaultEncoder="hevc_vaapi"

# minimum fileage in seconds for inputfiles to be considered to get converted and for outputfiles to be checked if reconverting is needed
# to prevent using .ts files that are still being recorded or for .mp4 files which are getting converted (in case multipleInstancesAllowed=true)
minFileAgeInSeconds=10

# exclude folders, be sure to end with a / (space separated)
defaultExcludedDirectories=(
)

# ffmpeg quality of encoding
defaultQuality=25

# Loglevel ffmpeg
# quiet   - Show nothing at all; be silent.
# panic   - Only show fatal errors which could lead the process to crash, such as and assert failure. This is not currently used for anything.
# fatal   - Only show fatal errors. These are errors after which the process absolutely cannot continue after.
# error   - Show all errors, including ones which can be recovered from.
# warning - Show all warnings and errors. Any message related to possibly incorrect or unexpected events will be shown.
# info    - Show informative messages during processing. This is in addition to warnings and errors. This is the default value.
# verbose - Same as info, except more verbose.
# debug   - Show everything, including debugging information.
# trace
loglevel=quiet

# how many conversion retries (1 try per run)
maxRetries=2

# after successfull conversion delete corresponding .xml file which HDHomeRun generates?
removeVideoXMLFile=true

# how much tolereance between inputfile and outputfile to be a match (means conversion is succesfull)
maxDurationDifferenceAsPercentage=1.5
redoConversionWhenInputAndOutputDontMatch=true

# In some rare cases you can have an outputfile which has the same filename (without extension) as an inputfile,
# but doesn't have the same contents which is reflected in a different duration.
# With this setting you can preserve these files.
# Also use this setting if you want to preserve previous (failed, interrupted, incomplete, ...) conversion.
# The previous outputfile will have a version suffix with version number added.
versionSuffix="-prev-v"
keepPreviousConversion=true

# after conversion delete original inputfile and if any previous failed conversions (files with the version suffix and version number)
deleteOriginalFiles=true

# is it allowed to have multiple instances running of this script (to be safe set to false), works only on the same host
multipleInstancesAllowed=true

# if runOnce is set to false it will keep running (script is never exited) and 
#  will restart scanning automatically at the next scheduled time (see rerunAt and rerunAtIsRelative settings)
# if runOnce is set to true it will only do one run and then exit
runOnce=false

# if runOnce is false then next rerun will be at a specific time OR when rerunAtIsRelative is true some hours and minutes later (HH MM)
rerunAt="03 00"
rerunAtIsRelative=false

# maximum time for a run in minutes, or disable (-1)
maxRunTimePerRunInMinutes=-1

# in this file all full filenames will be stored that has hit maximum number of retries and will therefor be skipped
filenameInputFilesWithMaxRetries="inputFilesWithMaxRetries.txt"

# call post run script
postRunScript="./postRun.sh"
stopWhenPostRunScriptFails=false

# ---- END OF SETTINGS ----
```

## Script parameters

All settings are loaded by default from `settings.sh` but overridable by settingsFile `-sf` option.
Also some settings from the settings file can also be set and overriden by using parameters when `convertVideos.sh` is called.

<pre>
Convert videos v1.1 - 23 July 2024
Syntax is:
 convertVideos.sh [option(s)]
  where option is:
   -h
     this help
   -sf [settingsFile]
     settings file where to load all settings from
   -sd [searchDirectory]
     1 or more directories from where to start (recursively) to find files
   -ff [filefilter]
     1 or more file filters
   -lf [logFile]
     log file where to write all output to
   -e [encoder]
     any supported ffmpeg encoder, for example (and tested):
       libx264
       h264_vaapi (hardware accelerated)
       h264_qsv (hardware accelerated)
       libx265
       hevc_vaapi (hardware accelerated)
       hevc_qsv (hardware accelerated)
   -ed [excludeDirectory]
     1 or more directories to exclude when searching for files
   -q [quality]
     quality of encoding (value between 1-51). Lower value is better quality/lower compression, higher value is lower quality/higher compression
</pre>

## Examples
<pre>
  convertVideos.sh
    All settings are used from "settings.sh"
  convertVideos.sh -q 30
    All settings are used from "settings.sh" and quality value of encoding is 30
  convertVideos.sh -sd "/videos/" -ff "*.ts"
    All settings are used from "settings.sh" but searchDirectory is "/videos/" and file filter is "*.ts"
  convertVideos.sh -sd "/videos/" -sf "/videos2/" -ff "*.ts" -ff "*.mpeg2"
    All settings are used from "settings.sh" but searchDirectories are "/videos/" and "/videos2/" and file filters are "*.ts" and "*.mpeg2"
  convertVideos.sh -sd "/videos/" -ff "*.ts" libx264
    All settings are used from "settings.sh" but searchDirectory is "/videos/"
    File filter is "*.ts" with libx264 (software) encoder
  convertVideos.sh -sf "settings-dev.sh" -sd "/videos/" -ff "*.ts" hevc_vaapi
    All settings are now used from "settings-dev.sh" but searchDirectory is "/videos/"
    File filter is "*.ts" with h.265/hevc codec using VAAPI hardware acceleration
  convertVideos.sh -sf "settings-dev.sh" -sd "/videos/" -ff "*.ts" libx264 -lf "logfile.txt"
    All settings are now used from "settings-dev.sh" but searchDirectory is "/videos/"
    File filter is "*.ts" with libx264 (software) encoder
    Everything is logged to "logfile.txt"
  convertVideos.sh -sf "settings-dev.sh" -sd "/videos/" -ff "*.ts" libx264 -lf "logfile.txt" -ed "/videos/example1/" -ed "/videos/example2/"
    All settings are now used from "settings-dev.sh" but searchDirectory is "/videos/"
    File filter is "*.ts" with libx264 (software) encoder
    Everything is logged to "logfile.txt".
    When searching two directories are excluded: "/videos/example1/" and "/videos/example2/"
</pre>
