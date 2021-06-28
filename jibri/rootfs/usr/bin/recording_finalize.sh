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
    if [[ -z $AWS_ACCESS_KEY_ID ]]; then
        echo 'FATAL ERROR: AWS_ACCESS_KEY_ID must be set'
        exit 1
    fi
    if [[ -z $AWS_SECRET_ACCESS_KEY ]]; then
        echo 'FATAL ERROR: AWS_SECRET_ACCESS_KEY must be set'
        exit 1
    fi
    if [[ -z $S3_BUCKET ]]; then
        echo 'FATAL ERROR: S3_BUCKET must be set'
        exit 1
    fi
    if [[ -z $S3_UPLOAD_NOTIFY_URL ]]; then
        echo 'FATAL ERROR: S3_UPLOAD_NOTIFY_URL must be set'
        exit 1
    fi

    date=`date +%Y%m%d`
    dateFormatted=`date -R`

    S3_FILE_PATH=`echo $REC_FILE_NAME | cut -d'/' -f5-`
    echo 'S3_FILE_PATH=' $S3_FILE_PATH

    relativePath="/${S3_BUCKET}${S3_BUCKET_PATH}/${S3_FILE_PATH}"

    rsync -r $REC_DIR root@storage:/recordings

    ENDPOINT="http://vmapi:5000/upload-s3"
    AUTH_HEADER="Authorization: Bearer ${VMEETING_DB_PASS}"
    curl -v -X POST -H "Date: $DATE" -H "$AUTH_HEADER" \
        -H "Content-Type: application/json" \
        -d "{\"uploadVideo\": \"${relativePath}\", \"roomUrl\": \"${URL}\"}" \
        "$ENDPOINT"

else

# create email content
EMAIL_MESSAGE="\
${RECORDER_NAME}님께,

Vmeeting을 이용해주셔서 감사합니다.

\"${MEETING_NAME}\" 회의에 대한 녹화 파일은 아래 위치에서 다운로드 받을 수 있습니다:
${DOWNLOAD_LINKS}

주의: 녹화된 파일은 7일 후 서버에서 자동으로 삭제됩니다.


이 메일은 발신 전용입니다.
Copyright@2021 (주)케이에듀텍. ALL RIGHTS RESERVED.


Dear ${RECORDER_NAME},

Thank you for using Vmeeting!

The recorded file(s) for the meeting named \"${MEETING_NAME}\" is now available for downloading at:
${DOWNLOAD_LINKS}

NOTE: The recorded file(s) will be automatically DELETED from our servers after ${RECORDING_RETETION_DAYS} days.


This is out-going email only.
Copyright@2020 KeduTech, Inc. ALL RIGHTS RESERVED."

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

    # delegate to vmapi
    EMAIL_SUBJECT="[Vmeeting] Download recorded file for Vmeeting \"${MEETING_NAME}\""
    ENDPOINT="http://vmapi:5000/send-email"

    FROM="from=${NOREPLY_MAIL}"
    DEST="to=${RECORDER_EMAIL}"
    SUBJECT="subject=${EMAIL_SUBJECT}"
    MESSAGE="text=${EMAIL_MESSAGE}"

    AUTH_HEADER="Authorization: Bearer ${VMEETING_DB_PASS}"
    curl -v -X POST -H "Date: $DATE" -H "$AUTH_HEADER" \
        --data-urlencode "$MESSAGE" \
        --data-urlencode "$DEST" \
        --data-urlencode "$FROM" \
        --data-urlencode "$SUBJECT" \
        "$ENDPOINT"

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

fi

#
# finally remove the recorded folder
#
rm -r ${UPLOAD_DIR}
