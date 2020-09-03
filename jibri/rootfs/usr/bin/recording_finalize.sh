#!/bin/bash
set -e
shopt -s nullglob

if [[ -z $NOREPLY_MAIL ]]; then
    echo 'FATAL ERROR: NOREPLY_MAIL must be set'
    exit 1
fi

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
# decode percent (%) encoded url so that non-ascii meeting name is decoded correctly
URL=$(input=${URL//+/ }; printf "${URL//%/\\x}")
[[ "$URL" == "null" ]] && URL=""
MEETING_NAME="${URL##*/}"
FDATE=$(date '+%Y-%m-%d-%H-%M-%S')

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
    # Non ascii file name is not working correctly. either here or in url
    # detection in email. E.g., if meeting name start with english word and then
    # korean word, then gmail link detection will drop the korean part.
    # To prevent this and similar error, change file name to ascii char only
    file_name=$(basename "$f")
    file_extension=${file_name##*.}
    new_file_name="recorded_${FDATE}.${file_extension}"
    mv $f ${REC_DIR}/${new_file_name}
    LINK="${PUBLIC_URL}${RECORDING_DOWNLOAD_BASE}/${REC_FOLDER}/${new_file_name}"
    # one line for each link
    DOWNLOAD_LINKS="${DOWNLOAD_LINK}
${LINK}"
done

# create email content
EMAIL_MESSAGE="\
Dear ${RECORDER_NAME},

Thank you for using Vmeeting!

The recorded file(s) for the meeting named \"${MEETING_NAME}\" is now available for downloading at:
${DOWNLOAD_LINKS}

NOTE: The recorded file(s) will be automatically DELETED from our servers after ${RECORDING_RETETION_DAYS} days.


This is out-going email only.
Copyright@2020 Pohang University of Science and Technology. ALL RIGHTS RESERVED."

if [[ $USE_AMAZON_SES -eq 1 || x$USE_AMAZON_SES == xtrue ]]; then
    if [[ -z $AWS_ACCESS_KEY_ID ]]; then
        echo 'FATAL ERROR: AWS_ACCESS_KEY_ID must be set'
        exit 1
    fi
    if [[ -z $AWS_SECRET_ACCESS_KEY ]]; then
        echo 'FATAL ERROR: AWS_SECRET_ACCESS_KEY must be set'
        exit 1
    fi

    # sync everything to storage
    rsync -r $REC_DIR root@storage:/recordings

    DATE="$(date -R)"
    SIGNATURE="$(echo -n "$DATE" | openssl dgst -sha256 -hmac "${AWS_SECRET_ACCESS_KEY}" -binary | base64 -w 0)"
    AUTH_HEADER="X-Amzn-Authorization: AWS3-HTTPS AWSAccessKeyId=${AWS_ACCESS_KEY_ID}, Algorithm=HmacSHA256, Signature=$SIGNATURE"
    EMAIL_SUBJECT="[Vmeeting] Download recorded file for Vmeeting \"${MEETING_NAME}\""
    ENDPOINT="https://email.us-west-2.amazonaws.com/"

    ACTION="Action=SendEmail"
    SOURCE="Source=${NOREPLY_MAIL}"
    DEST="Destination.ToAddresses.member.1=${RECORDER_EMAIL}"
    SUBJECT="Message.Subject.Data=${EMAIL_SUBJECT}"
    MESSAGE="Message.Body.Text.Data=${EMAIL_MESSAGE}"

    curl -v -X POST -H "Date: $DATE" -H "$AUTH_HEADER" --data-urlencode "$MESSAGE" --data-urlencode "$DEST" \
        --data-urlencode "$SOURCE" --data-urlencode "$ACTION" --data-urlencode "$SUBJECT"  "$ENDPOINT"

else
    # send using postech smtp server
    if [[ -z $SMTP_SERVER ]]; then
        echo 'FATAL ERROR: SMTP_SERVER must be set'
        exit 1
    fi
    # FIXME: NOT indent the string is needed here.
    EMAIL_HEADER="\
From: Vmeeting <${NOREPLY_MAIL}>
To: <${RECORDER_EMAIL}>
Subject: [Vmeeting] Download recorded file for Vmeeting \"${MEETING_NAME}\"
"
    echo "$EMAIL_HEADER" > ${REC_DIR}/email.txt
    echo "$EMAIL_MESSAGE" >> ${REC_DIR}/email.txt

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
                    --mail-from \"$NOREPLY_MAIL\" \
                    --mail-rcpt \"$RECORDER_EMAIL\" \
                    --upload-file /recordings/$REC_FOLDER/email.txt"
fi

#
# finally remove the recorded folder
#
rm -r ${UPLOAD_DIR}
