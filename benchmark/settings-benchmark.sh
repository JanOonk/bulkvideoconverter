# ---- BEGIN OF SETTINGS ----

# full path to ffmpeg (here using Docker environment variable)
ffmpeg=$JELLYFIN_FFMPEG
# ffmpeg="/usr/bin/ffmpeg"

# if no searchFolder -sf argument is given when script is called these searchFolders will be used (enter/space seperated)
defaultSearchDirectories=(
)

# if no fileFilter -ff argument is given when script is called these fileFilters will be used (enter/space seperated)
defaultFileFilters=(
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
minFileAgeInSeconds=0

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
keepPreviousConversion=false

# after conversion delete original inputfile and if any previous failed conversions (files with the version suffix and version number)
deleteOriginalFiles=false

# is it allowed to have multiple instances running of this script (to be safe set to false), works only on the same host
multipleInstancesAllowed=true

# if runOnce is set to false it will keep running (script is never exited) and 
#  will restart scanning automatically at the next scheduled time (see rerunAt and rerunAtIsRelative settings)
# if runOnce is set to true it will only do one run and then exit
runOnce=true

# if runOnce is false then next rerun will be at a specific time OR when rerunAtIsRelative is true some hours and minutes later (HH MM)
rerunAt="03 00"
rerunAtIsRelative=false

# maximum time for a run in minutes, or disable (-1)
maxRunTimePerRunInMinutes=-1

# in this file all full filenames will be stored that has hit maximum number of retries and will therefor be skipped
filenameInputFilesWithMaxRetries="inputFilesWithMaxRetries.txt"

# call post run script
postRunScript=/videos/_benchmark/postRun-benchmark.sh
stopWhenPostRunScriptFails=false

# ---- END OF SETTINGS ----
