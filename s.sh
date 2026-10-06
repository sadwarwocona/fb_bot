#!/bin/bash
bot=""
tkn=""
grp=""
if [[ -z "$bot" ]] ||
   [[ -z "$tkn" ]] ||
   [[ -z "$grp" ]]; then
  echo "please set proper bot username, bot token, admin's group"
  exit 1
fi

if ! command -v curl >/dev/null ||
   ! command -v jq >/dev/null; then
  echo "curl and jq are required"
  exit 1
fi

mkdir -p $bot
cd $bot
touch datasheet
touch for_reply
touch ban
url=https://api.telegram.org/bot$tkn
off=0
while true
do
  upd=`curl -s "$url/getUpdates?offset=$off&timeout=300"`
  off=`echo $upd | jq 'last(.result[] | .update_id)'` && let off++
  ids=`echo $upd | jq -r '.result[] | .update_id'`
  while read -r uid
  do
    fr1=`echo $upd | jq -r ".result[] | select(.update_id == $uid).message | .reply_to_message.from.username"`
    fr2=`echo $upd | jq -r ".result[] | select(.update_id == $uid).message | .reply_to_message.forward_from.id"`
    mid=`echo $upd | jq -r ".result[] | select(.update_id == $uid).message | .message_id"`
    cid=`echo $upd | jq -r ".result[] | select(.update_id == $uid).message | .chat.id"`
    txt=`echo $upd | jq -r ".result[] | select(.update_id == $uid).message | .text"`

    if [[ "$fr1" == "$bot" ]] && [[ "$cid" == "$grp" ]] && [[ "$fr2" == "null" ]]; then
      fr2=`grep -w "message_id=$(echo $upd | jq -r ".result[] | select(.update_id == $uid).message | .reply_to_message.message_id")" datasheet | cut -d" " -f1`
    fi

    if [[ "$fr1" == "$bot" ]] && [[ "$cid" == "$grp" ]]; then
      rpl=`grep "to=$(echo $upd | jq -r ".result[] | select(.update_id == $uid).message | .reply_to_message.message_id")" for_reply | cut -d" " -f1`
      curl -s -d chat_id="$fr2" -d from_chat_id="$grp" -d message_id="$mid" -d reply_to_message_id="$rpl" $url/copyMessage
    fi

    if [[ "$cid" != "$grp" ]] && [[ "$txt" != "/start" ]] && ! grep -qx "$cid" ban; then
      fwd=`curl -s -d chat_id="$grp" -d from_chat_id="$cid" -d message_id="$mid" $url/forwardmessage`
      echo $mid to=$(echo $fwd | jq '.result.message_id') >> for_reply
      if [[ $(echo $fwd | jq '.result.forward_sender_name') != "null" ]]; then
        echo $cid message_id=$(echo $fwd | jq '.result.message_id') $(date +'%F %T %Z') >> datasheet
      fi
    fi

    if [[ "$cid" != "$grp" ]] && [[ "$txt" == "/start" ]] && ! grep -qx "$cid" ban; then
      curl -s -G "$url/sendMessage" --data-urlencode "chat_id=$cid" --data-urlencode "text=Hi, I am a support bot. Send your question."
    fi

  done <<< "$ids"
done
