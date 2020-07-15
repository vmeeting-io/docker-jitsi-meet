#!/bin/bash
set -e
shopt -s nullglob


SMTP_SERVER=smtp.postech.ac.kr:25
MAIL_FROM=noreply@vmeeting.postech.ac.kr

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
# generate download link and email content
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

# create email content
EMAIL_MESSAGE="\
From: Vmeeting <${MAIL_FROM}>
To: <${RECORDER_EMAIL}>
Subject: [Vmeeting] Download recorded file for Vmeeting \"${MEETING_NAME}\"

Dear ${RECORDER_NAME},

Thank you for using Vmeeting!

The recorded file(s) for the meeting named \"${MEETING_NAME}\" is now available for downloading at:
${DOWNLOAD_LINKS}

NOTE: The recorded file(s) will be automatically DELETED from our servers after ${RECORDING_RETETION_DAYS} days.


This is out-going email only.
Copyright@2020 Pohang University of Science and Technology. ALL RIGHTS RESERVED."

echo "$EMAIL_MESSAGE" > ${REC_DIR}/email.txt

# RFC 5322 require CRLF line ending for email content
unix2dos ${REC_DIR}/email.txt

# finally sync everything to storage
rsync -r $REC_DIR root@storage:/recordings

#
# send email about download link to the recorder user
# email is sent via the storage container, which runs in manager node.
# port 25 should be opened by the ISP for the manager node
#

ssh root@storage "curl --url \"$SMTP_SERVER\" \
                --mail-from \"$MAIL_FROM\" \
                --mail-rcpt \"$RECORDER_EMAIL\" \
                --upload-file /recordings/$REC_FOLDER/email.txt"

#
# finally remove the recorded folder
#
rm -r ${UPLOAD_DIR}
