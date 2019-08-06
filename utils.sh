#!/bin/bash

has_serviceaccount() {
  oc get serviceaccount "$1" &> /dev/null;
}

announce() {
  echo "++++++++++++++++++++++++++++++++++++++"
  echo ""
  echo "$@"
  echo ""
  echo "++++++++++++++++++++++++++++++++++++++"
}

platform_image() {
  echo "$DOCKER_REGISTRY_PATH/$CONJUR_NAMESPACE_NAME/$1:$CONJUR_NAMESPACE_NAME"
}

has_namespace() {
  if oc get namespace  "$1" > /dev/null; then
    true
  else
    false
  fi
}

set_namespace() {
  if [[ $# != 1 ]]; then
    printf "Error in %s/%s - expecting 1 arg.\n" $(pwd) $0
    exit -1
  fi

  oc config set-context $(oc config current-context) --namespace="$1" > /dev/null
}

function wait_for_it() {
  local timeout=$1
  local spacer=2
  shift

  if ! [ $timeout = '-1' ]; then
    local times_to_run=$((timeout / spacer))

    echo "Waiting for '$@' up to $timeout s"
    for i in $(seq $times_to_run); do
      eval $@ > /dev/null && echo 'Success!' && break
      echo -n .
      sleep $spacer
    done

    eval $@
  else
    echo "Waiting for '$@' forever"

    while ! eval $@ > /dev/null; do
      echo -n .
      sleep $spacer
    done
    echo 'Success!'
  fi
}