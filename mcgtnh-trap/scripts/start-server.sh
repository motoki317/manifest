#!/usr/bin/env sh

exec kubectl scale statefulset mcgtnh-trap --replicas=1
