#!/bin/bash -ex

ASSETS_PATH="/assets"

function main
{
    abort_if_eirini_rootfs_version_not_set

    verify_rootfs_version_exists

    create_version_file_if_non_existent

    VERSION_VALUE=$(cat ${ASSETS_PATH}/eirini_rootfs_version_file)
    if [ ! -s ${ASSETS_PATH}/eirini_rootfs_version_file ]; then
        echo "eirini_rootfs_version not set - will download specified version ($EIRINI_ROOTFS_VERSION) of rootfs from GIT"
        grep_and_persist_version
        download_rootfs_tar
    else
        is_specified_rootfs_version_present
        echo "RootFS is outdated - Downloading..."
        delete_eirini_rootfs_tar_if_present
        grep_and_persist_version
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

function create_version_file_if_non_existent
{
    if [ ! -f ${ASSETS_PATH}/eirini_rootfs_version_file ]; then
        touch ${ASSETS_PATH}/eirini_rootfs_version_file
    fi
}

function grep_and_persist_version
{
    echo $EIRINI_ROOTFS_VERSION > ${ASSETS_PATH}/eirini_rootfs_version_file
}

function download_rootfs_tar
{
    curl -X GET -L $(curl https://api.github.com/repos/cloudfoundry-incubator/eirinifs/releases/tags/${EIRINI_ROOTFS_VERSION} | jq '.assets[].browser_download_url' | tr -d '\"') --output ${ASSETS_PATH}/eirinifs.tar
}

function is_specified_rootfs_version_present
{
    LOCAL_version=$(cat ${ASSETS_PATH}/eirini_rootfs_version_file)
    REMOTE_version=${EIRINI_ROOTFS_VERSION}
    if [ "$LOCAL_version" == "$REMOTE_version" ]
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