#!/usr/bin/env bash

rake version:bump:minor

git add .
git commit -m $0
git push
