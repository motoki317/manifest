#!/bin/bash

set -eux

apk add --no-cache curl openssl

WORKFLOW_URL="$WORKFLOW_BASE_URL/workflows/$WORKFLOW_NAMESPACE/$WORKFLOW_NAME"
if [ "$STATUS" = "Succeeded" ]; then
  MESSAGE="### :white_check_mark: Workflow $WORKFLOW_NAME succeeded in $WORKFLOW_DURATION."
  MESSAGE="$MESSAGE\n"
  MESSAGE="$MESSAGE\n$WORKFLOW_URL"
else
  MESSAGE="### :alert: Workflow $WORKFLOW_NAME failed after $WORKFLOW_DURATION. :alert:"
  MESSAGE="$MESSAGE\nFailed steps: $WORKFLOW_FAILURES"
  MESSAGE="$MESSAGE\n"
  MESSAGE="$MESSAGE\n$WORKFLOW_URL"
fi

set +x # disable logging
SIGNATURE=$(echo -n "$MESSAGE" | openssl sha1 -hmac "$SECRET")
curl -X POST -H "Content-Type: text/plain; charset=utf-8" -H "X-TRAQ-Signature: $SIGNATURE" -d "$MESSAGE" "$URL"
