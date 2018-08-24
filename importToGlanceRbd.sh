#!/bin/bash

FSID=7694a6e3-828c-4003-9f90-78887a875db6
POOL=images
UUID=$1
FILE=$2

if [ -z $UUID ]; then
    echo "No UUID set";
    exit 1;
fi

if [ -z $FILE ]; then
    echo "No image file set!";
    exit 1;
fi

if [ ! -f $FILE ]; then
    echo "Image file does not exist!";
    exit 1;
fi

if openstack image show $UUID | grep -q "queued"; then
    echo "Image found and queued!";
else
    echo "Image not found or not queued!";
    exit 1;
fi

echo "Uploading image to RBD backend with 8M object size";
rbd --id glance import $FILE ${POOL}/${UUID} --object-size 8M
echo "Creating snapshot from image";
rbd --id glance snap create ${POOL}/${UUID}@snap
echo "Protecting snapshot";
rbd --id glance snap protect ${POOL}/${UUID}@snap

echo "Adding location to Glance";

glance location-add --url rbd://${FSID}/${POOL}/${UUID}/snap $UUID

echo "Successfully completed import!";

