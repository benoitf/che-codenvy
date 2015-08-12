#!/bin/bash

set -e

# The script clones all repositories of an GitHub organization.
# the git clone cmd used for cloning each repository
# the parameter recursive is used to clone submodules, too.
GIT_CLONE_CMD="git clone "

REPOLIST=( che-depmgt che-core che-plugins che-tutorials che plugins plugin-hosted plugin-contribution plugin-gae hosted-infrastructure odyssey factory user-dashboard swagger-ui cdec cloud-ide onpremises platform-api-client-java cli )
BRANCH="Release"

clone () {
# loop over all repository urls and execute clone
#cd ../../
for REPO in ${REPOLIST[@]}; do
    if [ -d ${REPO} ]; then
        echo -e "\x1B[92m${REPO} already exist, performing git pull\x1B[0m"
        cd ${REPO}
        git pull
        cd ../
    else
        echo -e "\x1B[92mCloning ${REPO} repo\x1B[0m"
        ${GIT_CLONE_CMD}git@github.com:codenvy/${REPO}.git
    fi
done
}

createBranches () {
for REPO in ${REPOLIST[@]}; do
    if [ -d ${REPO} ]; then
        echo -e "\x1B[92mset up Release branch in: ${REPO}\x1B[0m"
        cd ${REPO}
        git branch ${BRANCH}
        git checkout ${BRANCH}
        VERSION=`mvn org.apache.maven.plugins:maven-help-plugin:2.1.1:evaluate -Dexpression=project.version|grep -Ev '(^\[|Download\w+:)' | cut -d '-' -f 1`
        mvn versions:set -DnewVersion=${VERSION}-RC-SNAPSHOT -DgenerateBackupPoms=false
        git add .
        git commit -m "SET RC VERSION"
        git push -u origin ${BRANCH}
        cd ../
    fi
done
}

removeBranches () {
for REPO in ${REPOLIST[@]}; do
    if [ -d ${REPO} ]; then
        echo -e "\x1B[92mremove Release branch in: ${REPO}\x1B[0m"
        cd ${REPO}
        git checkout master
        git branch -d ${BRANCH}
        git push origin :${BRANCH}
        cd ../
    fi
done
}


setParent () {
cd che-depmgt
PARENT=`mvn org.apache.maven.plugins:maven-help-plugin:2.1.1:evaluate -Dexpression=project.version|grep -Ev '(^\[|Download\w+:)' | cut -d '-' -f 1`
mvn clean install
cd ../
for REPO in ${REPOLIST[@]}; do
    if [[ -d ${REPO} && ${REPO} != "che-depmgt" ]]; then
        cd ${REPO}
        mvn versions:update-parent  -DparentVersion=[${PARENT}] -DallowSnapshots=true -DgenerateBackupPoms=false
        mvn scm:update  scm:checkin scm:update  -Dincludes=pom.xml  -Dmessage="SET RC che-depmgt" -DpushChanges=true
        cd ../
    fi
done
}


#####
$1
