#!/bin/bash

set -e

# Default settings
CUDA="off"
IMAGE_NAME="autoware/autoware"
TAG_PREFIX="latest"
ROS_DISTRO="melodic"
BASE_ONLY="false"
PRE_RELEASE="off"
AUTOWARE_HOST_DIR=""
USER_ID="$(id -u)"


# Convert a relative directory path to absolute
function abspath() {
    local path=$1
    if [ ! -d $path ]; then
	exit 1
    fi
    pushd $path > /dev/null
    echo $(pwd)
    popd > /dev/null
}

echo "Using options:"
echo -e "\tROS distro: $ROS_DISTRO"
echo -e "\tImage name: $IMAGE_NAME"
echo -e "\tTag prefix: $TAG_PREFIX"
echo -e "\tCuda support: $CUDA"
if [ "$BASE_ONLY" == "true" ]; then
  echo -e "\tAutoware Home: $AUTOWARE_HOST_DIR"
fi
echo -e "\tPre-release version: $PRE_RELEASE"
echo -e "\tUID: <$USER_ID>"

SUFFIX=""
RUNTIME=""

XSOCK=/tmp/.X11-unix
XAUTH=$HOME/.Xauthority

SHARED_DOCKER_DIR=/home/autoware/shared_dir
SHARED_HOST_DIR=$HOME/shared_dir

AUTOWARE_DOCKER_DIR=/home/autoware/Autoware

VOLUMES="--volume=$XSOCK:$XSOCK:rw
         --volume=$XAUTH:$XAUTH:rw
         --volume=$SHARED_HOST_DIR:$SHARED_DOCKER_DIR:rw"

if [ "$BASE_ONLY" == "true" ]; then
    SUFFIX=$SUFFIX"-base"
    VOLUMES="$VOLUMES --volume=$AUTOWARE_HOST_DIR:$AUTOWARE_DOCKER_DIR "
fi


if [ $PRE_RELEASE == "on" ]; then
    SUFFIX=$SUFFIX"-rc"
fi

# Create the shared directory in advance to ensure it is owned by the host user
mkdir -p $SHARED_HOST_DIR

IMAGE=$IMAGE_NAME:$TAG_PREFIX-$ROS_DISTRO$SUFFIX
echo "Launching $IMAGE"

docker run \
    -it --rm \
    $VOLUMES \
    --env="XAUTHORITY=${XAUTH}" \
    --env="DISPLAY=${DISPLAY}" \
    --env="USER_ID=$USER_ID" \
    --privileged \
    --net=host \
    $RUNTIME \
    $IMAGE
