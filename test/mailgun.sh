#!/bin/bash


FILE_NAME=""
EMAIL_AD=""
API_KEY=""
DOMAIN=""
USER="Ocserv"
SUBJECT="Ocserv-Clientcert"
HTML="<html><p>您好！</p><br /><p>您所收到的邮件是ocserv为您生成的证书文件的通知。</p><p><b>${FILE_NAME}</b>文件是为您生成的身份证书，用于您在使用ocserv服务时，提供给服务器的身份凭据。</p><br /><p><i>请将上面的证书导入您的终端。</i></p><br /><br /><p><b>请不要回复此邮件，谢谢!</b><p></html>"
ATTACHMENT="${FILE_NAME}"


CMD="curl -s --user 'api:${API_KEY}'"
CMD="${CMD} https://api.mailgun.net/v2/${DOMAIN}/messages"
CMD="${CMD} -F from='${USER}'"
CMD="${CMD} -F to='${EMAIL_AD}'"
CMD="${CMD} -F subject='${SUBJECT}'"
CMD="${CMD} --form-string html='${HTML}'"
CMD="${CMD} -F attachment=@${ATTACHMENT}"

#echo $CMD
eval $CMD
