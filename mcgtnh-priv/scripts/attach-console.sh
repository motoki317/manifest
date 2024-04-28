#!/usr/bin/env sh

echo "Attaching to server console ..."
echo "To detach, type the escape sequence Ctrl+P followed by Ctrl+Q."
echo "For more, see https://kubernetes.io/docs/reference/kubectl/docker-cli-to-kubectl/#docker-attach."

exec kubectl attach mcgtnh-priv-0 -it
