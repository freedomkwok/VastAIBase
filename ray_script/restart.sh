#!/bin/bash
ps -ef | grep "gmail" | grep -v grep | awk '{print $2}' | xargs -r kill -9