#!/bin/bash
#mandrill api curl

API_KEY=""
DOMAIN=""


FILE_NAME="$1"
EMAIL_AD="$2"
FROM_NAME="Ocserv"
SUBJECT="Ocserv-Clientcert"
MIME_TYPE="application/x-pkcs12"
#MIME_TYPE="text/plain"
#MIME_TYPE="application/x-openvpn-profile"
FILE_BASE64=`base64 ${FILE_NAME}`
USER_NAME=`echo ${EMAIL_AD}|cut -d@ -f1`
HTML="<p>${USER_NAME}您好！</p><br /><p>${FROM_NAME}为您生成了一份证书文件。</p><p><b>附件当中的${FILE_NAME}</b>文件是为您生成的身份证书，用于您在使用服务时，提供给服务器的身份凭据。</p><br /><p><i>请将上面的证书导入您的终端。</i></p><br /><br /><p><b>请不要回复此邮件，谢谢!</b><p>"
cat > ${USER_NAME}.json<<EOF
{
    "key": "${API_KEY}",
    "message": {
        "html": "${HTML}",
        "subject": "${SUBJECT}",
        "from_email": "no-reply@${DOMAIN}",
        "from_name": "${FROM_NAME}",
        "to": [
            {
                "email": "${EMAIL_AD}",
                "name": "${USER_NAME}",
                "type": "to"
            }
        ],
        "headers": {
            "Reply-To": "${EMAIL_AD}"
        },
        "merge": true,
        "attachments": [
            {
                "type": "${MIME_TYPE}",
                "name": "${FILE_NAME}",
                "content": "${FILE_BASE64}"
            }
        ]
    },
    "ip_pool": "Main Pool"
}
EOF

curl -X POST -H "Content-Type: application/json" --data @${USER_NAME}.json https://mandrillapp.com/api/1.0/messages/send.json -v

#rm -f ${USER_NAME}.json
