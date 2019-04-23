#!/bin/bash -ex

LATEST_ROOTFS="-1"
ASSETS_PATH="/assets"

function main
{
    abort_if_eirini_rootfs_version_not_set

    verify_rootfs_version_exists

    create_etag_file_if_non_existent

    ETAG_VALUE=$(cat ${ASSETS_PATH}/eirini_rootfs_etag)
    if [ ! -s ${ASSETS_PATH}/eirini_rootfs_etag ]; then
        echo "eirini_rootfs_etag not set - will download specified version (<rootfasversion_value_goes_here>) of rootfs from GIT"
        grep_and_persist_etag
        download_rootfs_tar
    else
        is_specified_rootfs_version_present
        echo "RootFS is outdated - Downloading..."
        delete_eirini_rootfs_tar_if_present
        grep_and_persist_etag
        download_rootfs_tar
        return 0
    fi
}

function abort_if_eirini_rootfs_version_not_set
{
    if [[ -z "${EIRINI_ROOTFS_VERSION}" ]]; then
        return 1
        #todo: think about providing a meaningful message like "not set - needs to be set - aborting"
    fi
}

function create_etag_file_if_non_existent
{
    if [ ! -f ${ASSETS_PATH}/eirini_rootfs_etag ]; then
        touch ${ASSETS_PATH}/eirini_rootfs_etag
    fi
}

function grep_and_persist_etag
{
    curl https://api.github.com/repos/cloudfoundry-incubator/eirinifs/releases/tags/${EIRINI_ROOTFS_VERSION} -L -i | grep ETag: | cut -d \"  -f 2 > ${ASSETS_PATH}/eirini_rootfs_etag
}

function download_rootfs_tar
{
    curl -X GET -L $(curl https://api.github.com/repos/cloudfoundry-incubator/eirinifs/releases/tags/${EIRINI_ROOTFS_VERSION} | jq '.assets[].browser_download_url' | tr -d '\"') --output ${ASSETS_PATH}/eirinifs.tar
}

function is_specified_rootfs_version_present
{
    LOCAL_ETAG=$(cat ${ASSETS_PATH}/eirini_rootfs_etag)
    REMOTE_ETAG=$(curl https://api.github.com/repos/cloudfoundry-incubator/eirinifs/releases/tags/${EIRINI_ROOTFS_VERSION} -L -i | grep ETag: | cut -d \"  -f 2 )
    if [ "$LOCAL_ETAG" == "$REMOTE_ETAG" ]
     then
        echo "Already have the downloaded version ${EIRINI_ROOTFS_VERSION} "
        exit 0
    else
        echo "Specified version is not there, need to download"
    fi
}

function verify_rootfs_version_exists 
{
    STATUS_CODE=$(curl -I -L https://api.github.com/repos/cloudfoundry-incubator/eirinifs/releases/tags/${EIRINI_ROOTFS_VERSION} --write-out  %{http_code} --silent --output /dev/null)
    if [ "$STATUS_CODE" == "200" ]
    then
        echo "The specified rootfs version (${EIRINI_ROOTFS_VERSION}) exists --continue"
    elif [ "$STATUS_CODE" == "404" ]
     then
        echo "The specified rootfs version (${EIRINI_ROOTFS_VERSION}) does not exist - please speficy an existing version"
        exit 1
    else
        echo "Unexpected server response code : {STATUS_CODE} - aborting"
        exit 1
    fi
}

function delete_eirini_rootfs_tar_if_present
{
    if [ -f ${ASSETS_PATH}/eirinifs.tar ]; then
        echo "Found outdated RootFS - deleting it"
        rm -rf ${ASSETS_PATH}/eirinifs.tar
    fi
}
main