#!/usr/bin/env sh

exec kubectl scale statefulset mcgtnh-priv --replicas=0
