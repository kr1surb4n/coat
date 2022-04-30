#!/bin/bash

watchmedo shell-command -W --command='clear;cat ~/temp/current_dir | xargs tree -L 2' temp/current_dir
