#!/bin/bash

if [ "$#" -ne 1 ]; then
        echo 'input foo or bar only'>/dev/stderr
        exit 1
fi

case $1 in
    "foo")
        echo "bar";;
    "bar")
        echo "foo";;
    *)
        echo 'input foo or bar only'>/dev/stderr && exit 1;;
esac
