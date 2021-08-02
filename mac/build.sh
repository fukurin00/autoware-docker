#!/bin/bash

set -e

# Default settings
CUDA="off"
IMAGE_NAME="autoware/autoware"
TAG_PREFIX="local"
ROS_DISTRO="melodic"
BASE_ONLY="false"
VERSION=""


echo "Using options:"

if [ ! -z "$VERSION" ]; then
  echo -e "\tVersion: $VERSION"

  if [ "$VERSION" != "master" ]; then
    TAG_PREFIX=$VERSION
  fi
fi

echo -e "\tROS distro: $ROS_DISTRO"
echo -e "\tImage name: $IMAGE_NAME"
echo -e "\tTag prefix: $TAG_PREFIX"
echo -e "\tCuda support: $CUDA"
echo -e "\tBase only: $BASE_ONLY"

BASE=$IMAGE_NAME:$TAG_PREFIX-$ROS_DISTRO-base

# Update base image of Dockerfile.base so we don't use an outdated one
docker pull ros:$ROS_DISTRO

# Copy dependencies file into build context
cp ../dependencies .

docker build \
    --rm \
    --network=host \
    --tag $BASE \
    --build-arg ROS_DISTRO=$ROS_DISTRO \
    --file Dockerfile.base .

# Remove dependencies file from build context
rm dependencies

CUDA_SUFFIX=""
if [ $CUDA == "on" ]; then
    CUDA_SUFFIX="-cuda"
    docker build \
        --rm \
        --network=host \
        --tag $BASE$CUDA_SUFFIX \
        --build-arg FROM_ARG=$BASE \
        --file Dockerfile.cuda.$ROS_DISTRO .
fi

if [ "$BASE_ONLY" == "true" ]; then
    echo "Finished building the base image(s) only."
    exit 0
fi

DOCKERFILE="Dockerfile"

if [ -z "$VERSION" ]; then
  VERSION="master"
else
  if [[ $VERSION == 1.11.* ]]; then
    DOCKERFILE="$DOCKERFILE.legacy.colcon"
  elif [[ $VERSION == 1.10.* ]] ||
       [[ $VERSION == 1.9.*  ]] ||
       [[ $VERSION == 1.8.*  ]] ||
       [[ $VERSION == 1.7.*  ]] ||
       [[ $VERSION == 1.6.*  ]]; then
    DOCKERFILE="$DOCKERFILE.legacy.catkin"
  fi
fi

docker build \
    --rm \
    --network=host \
    --tag $IMAGE_NAME:$TAG_PREFIX-$ROS_DISTRO$CUDA_SUFFIX \
    --build-arg FROM_ARG=$BASE$CUDA_SUFFIX \
    --build-arg ROS_DISTRO=$ROS_DISTRO \
    --build-arg VERSION=$VERSION \
    --file $DOCKERFILE .


docker build\
    --rm \
    --network=host \
    --tag autoware/autoware:local-melodic \
    --build-arg FROM_ARG=autoware/autoware:local-melodic-base \
    --build-arg ROS_DISTRO=melodic \
    --build-arg VERSION="" .
