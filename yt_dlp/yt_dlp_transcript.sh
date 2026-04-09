# Read user input for youtube URL
echo "Please provide the desired YouTube URL. "

# The -r option stipulates that backslash does not act as an escape character
read -r YT_DLP_URL


yt-dlp --skip-download --write-subs --write-auto-subs --sub-lang en --sub-format ttml --convert-subs srt --output "transcript.%(ext)s" "${YT_DLP_URL}" && sed -i '' -e '/^[0-9][0-9]:[0-9][0-9]:[0-9][0-9].[0-9][0-9][0-9] --> [0-9][0-9]:[0-9][0-9]:[0-9][0-9].[0-9][0-9][0-9]$/d' -e '/^[[:digit:]]\{1,4\}$/d' -e 's/<[^>]*>//g' ./transcript.en.srt && sed -e 's/<[^>]*>//g' -e '/^[[:space:]]*$/d' transcript.en.srt

# OUTPUT=$(find . -type f -printf "%T@ %p\n" | sort -n | cut -d' ' -f 2- | tail -n 1)


