#!/bin/bash
#mandrill api curl
FILE_NAME=""
EMAIL_AD=""
API_KEY=""


FILE_BASE64=`base64 ${FILE_NAME}`
USER_NAME=`echo ${EMAIL_AD}|cut -d@ -f1`
HTML="<p>您好！</p><br /><p>您所收到的邮件是ocserv为您生成的证书文件的通知。</p><p><b>${FILE_NAME}</b>文件是为您生成的身份证书，用于您在使用ocserv服务时，提供给服务器的身份凭据。</p><br /><p><i>请将上面的证书导入您的终端。</i></p><br /><br /><p><b>请不要回复此邮件，谢谢!</b><p>"
cat > my.json<<EOF
{
    "key": "${API_KEY}",
    "message": {
        "html": "${HTML}",
        "subject": "Ocserv-Clientcert",
        "from_name": "Ocserv",
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
                "type": "application/x-pkcs12",
                "name": "${FILE_NAME}",
                "content": "${FILE_BASE64}"
            }
        ]
    },
    "ip_pool": "Main Pool"
}
EOF

curl -X POST -H "Content-Type: application/json" --data @my.json https://mandrillapp.com/api/1.0/messages/send.json -v
