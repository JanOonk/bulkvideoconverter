# ---- BEGIN OF SETTINGS ----
# full path to ffmpeg (here using Docker environment variable)
ffmpeg=$JELLYFIN_FFMPEG
# full path to ffprobe (here using Docker environment variable) by first taking the directory of JELLYFIN_FFMPEG
ffprobe=${JELLYFIN_FFMPEG%/*}/ffprobe

# if no (second) searchFolder argument is given when script is called this searchFolder will be used (space seperated)
defaultSearchFolders=(
	"/videos/"
)

# if no (third) fileFilter argument is given when script is called this fileFilter will be used (space seperated)
defaultFileFilters=(
	"*.ts"
)

defaultLogFile="convertVideos-logfile.txt"

# if no (fourth) encoder argument is given when script is called this encoder will be used
# These encoders has been tested on Synology DS713+ using Docker:
#  libx264 
#  h264_vaapi
#  libx265 
#  hevc_vaapi
#  hevc_qsv 
defaultEncoder="hevc_vaapi"

# minimum fileage in seconds for inputfiles to be considered to get converted and for outputfiles to be checked if reconverting is needed
# to prevent using .ts files that are still being recorded or for .mp4 files which are getting converted (in case multipleInstancesAllowed=true)
minFileAgeInSeconds=10

# exclude folders, be sure to end with a / (space separated)
defaultExcludedDirectories=( 
	"/videos/test/"
	"/videos/test2/"
	"/videos/test3/"
	"/videos/test4/"
)

# ffmpeg quality of encoding
qualityLevel_software=25
qualityLevel_vaapi=25
qualityLevel_qsv=25

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
loglevel=verbose

# how many conversion retries (1 try per run)
maxRetries=3

# after successfull conversion delete corresponding .xml file which HDHomeRun generates?
removeVideoXMLFile=true

# how much tolereance between inputfile and outputfile to be a match (means conversion is succesfull)
maxDurationDifferenceAsPercentage=1
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

# is it allowed to have multiple instances running of this script (to be safe set to false)
multipleInstancesAllowed=false

# if false it will keep running (script is never exited) and 
# will restart scanning automatically at the next scheduled time (see rerunAt and rerunAtIsRelative settings)
runOnce=false

# if runOnce is false then next rerun will be at a specific time or when rerunAtIsRelative is true some hours and minutes later (HH MM)
rerunAt="03 00"
rerunAtIsRelative=false

# maximum time for a run in minutes, or disable (-1)
maxRunTimePerRunInMinutes=-1

filenameInputFilesWithMaxRetries="inputFilesWithMaxRetries.txt"
# ---- END OF SETTINGS ----

