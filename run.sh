#!/bin/bash
declare -A all && eval all=($ALL)
declare -r setup_name=$PROJECT_NAME

declare -p all
declare -p setup_name