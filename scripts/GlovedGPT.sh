#!/bin/sh

cd /home/gloves/projects/gpt-bot/
venv/bin/watchmedo auto-restart --directory=./ --pattern="*.py" --recursive -- venv/bin/python -m src.main > logs.txt 2>&1