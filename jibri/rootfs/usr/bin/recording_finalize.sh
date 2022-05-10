#!/bin/bash
set -e
shopt -s nullglob

if [[ -z $NOREPLY_MAIL ]]; then
    echo 'ERROR: NOREPLY_MAIL must be set'
    exit 1
fi

#
# the directory where the files and metadata exists
#
UPLOAD_DIR=$1
UPLOAD_DIR="${UPLOAD_DIR%/}"

if [ -z "$UPLOAD_DIR" ]; then
    echo "ERROR: No upload directory provided, failing..."
    exit 1
fi

if [ ! -d "$UPLOAD_DIR" ]; then
    echo "ERROR: No such directory $UPLOAD_DIR, failing..."
    exit 2
fi

METADATA_JSON="$UPLOAD_DIR/metadata.json"

if [[ ! -e "$METADATA_JSON" ]]; then
  echo "ERROR: No file found $METADATA_JSON, failing."
  exit 3
fi

#
# get recorder user information
#

RECORDER_EMAIL=$(cat $METADATA_JSON | jq -r ".recorder_identity.email")
if [ "$RECORDER_EMAIL" == "null" ]; then
    echo "ERROR: No RECORDER_EMAIL provided, failing..."
    exit 1
fi

RECORDER_NAME=$(cat $METADATA_JSON | jq -r ".recorder_identity.name")
URL=$(cat $METADATA_JSON | jq -r ".meeting_url")
# decode percent (%) encoded url so that non-ascii meeting name is decoded correctly
URL=$(input=${URL//+/ }; printf "${URL//%/\\x}")
[[ "$URL" == "null" ]] && URL=""
MEETING_NAME="${URL##*/}"
MEETING_ID_FROM_JSON=$(cat $METADATA_JSON | jq -r ".meetingId")
FDATE=$(date '+%Y-%m-%d-%H-%M-%S')

#
# copy recorded folder to the central storage (only copy video and transcript)
# generate download link and email content
# We use a random name for security and not depend on jibri random folder name
#

DOWNLOAD_LINKS=""
REC_FOLDER=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
REC_DIR=${UPLOAD_DIR}/${REC_FOLDER}
REC_FILE_PATH=""
REC_FILE_NAME=""
REC_FILE_SIZE=""
mkdir -p ${REC_DIR}

for f in ${UPLOAD_DIR}/*.{mp4,pdf}; do
    # Non ascii file name is not working correctly. either here or in url
    # detection in email. E.g., if meeting name start with english word and then
    # korean word, then gmail link detection will drop the korean part.
    # To prevent this and similar error, change file name to ascii char only
    file_name=$(basename "$f")
    file_extension=${file_name##*.}
    new_file_name="recorded_${FDATE}.${file_extension}"
    mv $f ${REC_DIR}/${new_file_name}
    REC_FILE_NAME=${REC_DIR}/${new_file_name}
    REC_FILE_SIZE=$(stat -c%s "$REC_FILE_NAME")
    LINK="${PUBLIC_URL}${RECORDING_DOWNLOAD_BASE}/${REC_FOLDER}/${new_file_name}"
    # one line for each link
    DOWNLOAD_LINKS="${LINK}"
done

# sync everything to storage
rsync -r $REC_DIR root@storage:/recordings

ENDPOINT="http://vmapi:5000/recordings"
AUTH_HEADER="Authorization: Bearer $VMEETING_DB_PASS"

curl -v -X POST -H "Date: $DATE" -H "$AUTH_HEADER" \
    -H "Content-Type: application/json" \
    -d "{\"uploadVideo\": \"$REC_FILE_NAME\", \"fileSize\": ${REC_FILE_SIZE}, \"meetingId\": \"${MEETING_ID_FROM_JSON}\", \"recorder\": \"${RECORDER_EMAIL}\", \"roomName\": \"${MEETING_NAME}\", \"roomUrl\": \"${URL}\", \"downloadUrl\": \"${DOWNLOAD_LINKS}\"}" \
    "$ENDPOINT"

#
# finally remove the recorded folder
#
rm -r ${UPLOAD_DIR}
