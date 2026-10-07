#!/usr/bin/env bash
set -Eeuo pipefail

limit_args=(-n 10)
pager_mode="auto" # auto | always | never

while [[ $# -gt 0 ]]; do
    case "$1" in
    -n)
        limit_args=(-n "${2:?Error: -n requires an argument.}")
        shift 2
        ;;
    -n*)
        limit_args=(-n "${1#-n}")
        shift
        ;;
    -a | --all)
        limit_args=()
        shift
        ;;
    -p | --paginate)
        pager_mode="always"
        shift
        ;;
    -P | --no-pager)
        pager_mode="never"
        shift
        ;;
    -h | --help)
        echo "Usage: git branch-history [-n <count>] [-a|--all] [-p|--paginate] [-P|--no-pager]"
        exit 0
        ;;
    --)
        shift
        break
        ;;
    *)
        break
        ;;
    esac
done

pager_cmd="cat"
if [[ "${pager_mode}" == "always" ]] || { [[ "${pager_mode}" == "auto" ]] && [[ -t 1 ]]; }; then
    pager_cmd="$(git var GIT_PAGER)"
fi

export LESS="${LESS:-FRX}" # FRX is: F Fit one screen; R raw control chars; X no init

git log -g -E \
    --grep-reflog='^(checkout: moving from |Branch: renamed refs/heads/)' \
    --date=iso-local \
    --format='%gd|%gs' \
    "${limit_args[@]}" \
    "$@" |
    tac |
    sed -E 's~^HEAD@\{([^}]+)\}\|(checkout: moving from .* to |Branch: renamed refs/heads/.* to refs/heads/)(.*)$~\1   \3~' |
    eval "${pager_cmd}"
