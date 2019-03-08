#!/bin/bash -ex

LATEST_ROOTFS="-1"
ASSETS_PATH="/assets"

function main
{
    create_etag_file_if_non_existent
    ETAG_VALUE=$(cat ${ASSETS_PATH}/eirini_rootfs_etag_latest)
    if [ ! -s ${ASSETS_PATH}/eirini_rootfs_etag_latest ]; then
        echo "eirini_rootfs_etag_latest not set - will download latest rootfs from GIT"
        grep_and_persist_etag
        download_rootfs_tar
    else
        is_latest_rootfs
        if [ "$LATEST_ROOTFS" == "1" ]; then
            echo "RootFS is up to date - no action required"
            return 0
        elif [ "$LATEST_ROOTFS" == "0" ]; then
            echo "RootFS is outdated - Downloading..."
            if [ -f ${ASSETS_PATH}/eirinifs.tar ]; then
                echo "Found outdated RootFS - deleting it"
                rm -rf ${ASSETS_PATH}/eirinifs.tar
            fi
            grep_and_persist_etag
            download_rootfs_tar
            return 0
        else
            echo "There was an error calling the GITHUB API"
            return 1
        fi
    fi
}

function create_etag_file_if_non_existent
{
    if [ ! -f ${ASSETS_PATH}/eirini_rootfs_etag_latest ]; then
        touch ${ASSETS_PATH}/eirini_rootfs_etag_latest
    fi
}

function grep_and_persist_etag
{
    curl https://api.github.com/repos/cloudfoundry-incubator/eirinifs/releases/latest -L -i | grep ETag: | cut -d \"  -f 2 > ${ASSETS_PATH}/eirini_rootfs_etag_latest
}

function download_rootfs_tar
{
    curl -X GET -L $(curl https://api.github.com/repos/cloudfoundry-incubator/eirinifs/releases/latest | jq '.assets[].browser_download_url' | tr -d '\"') --output ${ASSETS_PATH}/eirinifs.tar
}

function is_latest_rootfs
{
    LATEST=$(cat ${ASSETS_PATH}/eirini_rootfs_etag_latest)
    HTTP_STATUS_CODE=$(curl -I -L https://api.github.com/repos/cloudfoundry-incubator/eirinifs/releases/latest --header "If-None-Match: ${LATEST}" | grep "Status")
    if [ "$HTTP_STATUS_CODE"=="Status: 200 OK" ]
     then
        LATEST_ROOTFS=1
    elif [ "$HTTP_STATUS_CODE"=="Status: 304 OK" ]
     then
        LATEST_ROOTFS=0
    else
        LATEST_ROOTFS=ERROR
    fi
}

main