#!/usr/bin/env bash
#
# Super naive script but hey it works!
#
# Exits with code 2 if the host is not found.

function doc() {
    echo "Return the GPG signingkey for the current host or passed hostname."
    echo
    echo "Usage: $0 [HOSTNAME]"
    echo "  -h, --help      Show this help"
    echo
    echo "Parameters:"
    echo "  HOSTNAME: The host name to query. If not given, will use the current"
    echo "            host '${HOSTNAME}'"
    exit 1
}

THIS_HOSTNAME=${HOSTNAME}
while [[ "$#" -gt 0 ]]; do
    case $1 in
    -h | --help)
        doc
        ;;
    *)
        THIS_HOSTNAME=$1
        echo "Will return signingkey for ${THIS_HOSTNAME}" >&2
        shift
        ;;
    esac
    shift
done

case ${THIS_HOSTNAME} in
odin*)
    # Note the trailing "!". See https://stackoverflow.com/a/50986820/1354930
    # It's only needed for odin because all other hosts only have a single
    # subkey. Odin has all subkeys.
    echo "1C22730EC26ED6FB!"
    ;;
dthor1.roam.*)
    echo "811D308AA7C10FA2"
    ;;
dthor2.c.*)
    echo "10A8CB5928819595"
    ;;
dthor-pyledev.c.*)
    echo "5358825FD5B58AAB"
    ;;
yggdrasil*)
    echo "65E2E3EA0BF59145"
    ;;
midgard*)
    echo "5CAA2B3B1017CED7"
    ;;
*)
    echo "Unknown host '${THIS_HOSTNAME}'." >&2
    exit 2
    ;;
esac
