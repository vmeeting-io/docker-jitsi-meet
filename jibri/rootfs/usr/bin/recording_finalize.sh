#!/bin/bash
set -e
shopt -s nullglob

#
# the directory where the files and metadata exists
#
UPLOAD_DIR=$1
UPLOAD_DIR="${UPLOAD_DIR%/}"

if [ -z "$UPLOAD_DIR" ]; then
    echo "No upload directory provided, failing..."
    exit 1
fi

if [ ! -d "$UPLOAD_DIR" ]; then
    echo "No such directory $UPLOAD_DIR, failing..."
    exit 2
fi

METADATA_JSON="$UPLOAD_DIR/metadata.json"

if [[ ! -e "$METADATA_JSON" ]]; then
  echo "No file found $METADATA_JSON, failing."
  exit 3
fi

#
# get recorder user information
#

RECORDER_EMAIL=$(cat $METADATA_JSON | jq -r ".recorder_identity.email")
RECORDER_NAME=$(cat $METADATA_JSON | jq -r ".recorder_identity.name")
URL=$(cat $METADATA_JSON | jq -r ".meeting_url")
[[ "$URL" == "null" ]] && URL=""
MEETING_NAME="${URL##*/}"

#
# copy recorded folder to the central storage (only copy video and transcript)
# and generate download link
# We use a random name for security and not depend on jibri random folder name
#

DOWNLOAD_LINKS=""
REC_FOLDER=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
REC_DIR=${UPLOAD_DIR}/${REC_FOLDER}
mkdir -p ${REC_DIR}

for f in ${UPLOAD_DIR}/*.{mp4,pdf}; do
    file_name=$(basename "$f")
    mv $f ${REC_DIR}/
    LINK="${PUBLIC_URL}${RECORDING_DOWNLOAD_BASE}/${REC_FOLDER}/${file_name}"
    # one line for each link
    DOWNLOAD_LINKS="${DOWNLOAD_LINK}
${LINK}"
done

rsync -r $REC_DIR root@storage:/recordings

#
# send email about download link to the recorder user
#

FROM_EMAIL="vmeeting-info@postech.ac.kr"
TO_EMAIL="${RECORDER_EMAIL}"
EMAIL_SUBJECT="[Vmeeting] Download recorded file for Vmeeting ${MEETING_NAME}"
EMAIL_MESSAGE="Dear ${RECORDER_NAME},

Thank you for using Vmeeting!

The recorded file(s) for the Vmeeting "${MEETING_NAME}" is now avaiable for download at:
${DOWNLOAD_LINKS}

NOTE: The recorded file(s) will be automatically DELETED from our servers after ${RECORDING_RETETION_DAYS} days.


This is out-going email only.
Copyright@2020 Pohang University of Science and Technology. ALL RIGHTS RESERVED."

DATE="$(date -R)"
SIGNATURE="$(echo -n "$DATE" | openssl dgst -sha256 -hmac "${AWS_SECRET_ACCESS_KEY}" -binary | base64 -w 0)"
AUTH_HEADER="X-Amzn-Authorization: AWS3-HTTPS AWSAccessKeyId=${AWS_ACCESS_KEY_ID}, Algorithm=HmacSHA256, Signature=$SIGNATURE"
ENDPOINT="https://email.us-west-2.amazonaws.com/"

ACTION="Action=SendEmail"
SOURCE="Source=$FROM_EMAIL"
DEST="Destination.ToAddresses.member.1=$TO_EMAIL"
SUBJECT="Message.Subject.Data=$EMAIL_SUBJECT"
MESSAGE="Message.Body.Text.Data=$EMAIL_MESSAGE"

curl -v -X POST -H "Date: $DATE" -H "$AUTH_HEADER" --data-urlencode "$MESSAGE" --data-urlencode "$DEST" \
    --data-urlencode "$SOURCE" --data-urlencode "$ACTION" --data-urlencode "$SUBJECT"  "$ENDPOINT"

#
# finally remove the recorded folder
#
rm -r ${UPLOAD_DIR}
