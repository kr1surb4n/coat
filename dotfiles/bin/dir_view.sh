#!/bin/bash

watchmedo shell-command -W --command='clear;cat ~/temp/current_dir | xargs ls --color ' temp/current_dir
