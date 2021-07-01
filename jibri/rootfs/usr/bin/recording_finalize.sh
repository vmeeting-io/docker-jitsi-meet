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
    LINK="${PUBLIC_URL}${RECORDING_DOWNLOAD_BASE}/${REC_FOLDER}/${new_file_name}"
    # one line for each link
    DOWNLOAD_LINKS="${DOWNLOAD_LINKS}
${LINK}"
done

if [[ "$USE_AMAZON_S3" -ne "" ]]; then
    if [[ -z $S3_ACCESS_KEY_ID ]]; then
        echo 'ERROR: S3_ACCESS_KEY_ID must be set'
        exit 1
    fi
    if [[ -z $S3_SECRET_ACCESS_KEY ]]; then
        echo 'ERROR: S3_SECRET_ACCESS_KEY must be set'
        exit 1
    fi
    if [[ -z $S3_BUCKET ]]; then
        echo 'ERROR: S3_BUCKET must be set'
        exit 1
    fi
    if [[ -z $S3_UPLOAD_NOTIFY_URL ]]; then
        echo 'ERROR: S3_UPLOAD_NOTIFY_URL must be set'
        exit 1
    fi

    date=`date +%Y%m%d`
    dateFormatted=`date -R`

    S3_FILE_PATH=`echo $REC_FILE_NAME | cut -d'/' -f5-`
    echo 'S3_FILE_PATH=' $S3_FILE_PATH

    relativePath="/${S3_BUCKET}${S3_BUCKET_PATH}/${S3_FILE_PATH}"
    contentType="application/octet-stream"
    stringToSign="PUT\n\n${contentType}\n${dateFormatted}\n${relativePath}"
    signature=`echo -en ${stringToSign} | openssl sha1 -hmac ${S3_SECRET_ACCESS_KEY} -binary | base64`

    curl -X PUT -T "${REC_FILE_NAME}" \
        -H "Host: ${S3_BUCKET}.s3.amazonaws.com" \
        -H "Date: ${dateFormatted}" \
        -H "Content-Type: ${contentType}" \
        -H "Authorization: AWS ${S3_ACCESS_KEY_ID}:${signature}" \
        http://${S3_BUCKET}.s3.amazonaws.com${S3_BUCKET_PATH}/${S3_FILE_PATH}

    curl -X POST \
        -H "Content-Type: application/json" \
        -d "{\"uploadVideo\": \"${relativePath}\", \"roomUrl\": \"${URL}\"}" \
        ${S3_UPLOAD_NOTIFY_URL}

else

# create email content
EMAIL_MESSAGE="\
Vmeeting을 이용해주셔서 감사합니다.

\"${MEETING_NAME}\" 회의에 대한 녹화 파일은 아래 위치에서 다운로드 받을 수 있습니다:
${DOWNLOAD_LINKS}

주의: 녹화된 파일은 7일 후 서버에서 자동으로 삭제됩니다.


이 메일은 발신 전용입니다.
Copyright@2021 (주)케이에듀텍. ALL RIGHTS RESERVED.


Thank you for using Vmeeting!

The recorded file(s) for the meeting named \"${MEETING_NAME}\" is now available for downloading at:
${DOWNLOAD_LINKS}

NOTE: The recorded file(s) will be automatically DELETED from our servers after ${RECORDING_RETETION_DAYS} days.


This is out-going email only.
Copyright@2020 KeduTech, Inc. ALL RIGHTS RESERVED."

if [[ $USE_AMAZON_SES -eq 1 || x$USE_AMAZON_SES == xtrue ]]; then
    if [[ -z $AWS_ACCESS_KEY_ID ]]; then
        echo 'ERROR: AWS_ACCESS_KEY_ID must be set'
        exit 1
    fi
    if [[ -z $AWS_SECRET_ACCESS_KEY ]]; then
        echo 'ERROR: AWS_SECRET_ACCESS_KEY must be set'
        exit 1
    fi

    # sync everything to storage
    rsync -r $REC_DIR root@storage:/recordings

    # delegate to vmapi
    EMAIL_SUBJECT="[Vmeeting] Download recorded file for Vmeeting \"${MEETING_NAME}\""
    ENDPOINT="http://vmapi:5000/send-recording-email"
    # ENDPOINT="http://vmapi:5000/send-email"

    FROM="from=${NOREPLY_MAIL}"
    DEST="to=${RECORDER_EMAIL}"
    SUBJECT="subject=${EMAIL_SUBJECT}"
    MESSAGE="text=${EMAIL_MESSAGE}"
    MEETING_ID="meetingId=${MEETING_ID_FROM_JSON}"
    ROOM_NAME="roomName=${MEETING_NAME}"
    RECORD_LINK="recordLink=${DOWNLOAD_LINKS}"

    AUTH_HEADER="Authorization: Bearer ${VMEETING_DB_PASS}"
    curl -v -X POST -H "Date: $DATE" -H "$AUTH_HEADER" \
        --data-urlencode "$MESSAGE" \
        --data-urlencode "$DEST" \
        --data-urlencode "$FROM" \
        --data-urlencode "$SUBJECT" \
        --data-urlencode "$MEETING_ID" \
        --data-urlencode "$ROOM_NAME" \
        --data-urlencode "$RECORD_LINK" \
        "$ENDPOINT"

else
    # send using postech smtp server
    if [[ -z $SMTP_SERVER ]]; then
        echo 'ERROR: SMTP_SERVER must be set'
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

fi

#
# finally remove the recorded folder
#
rm -r ${UPLOAD_DIR}
