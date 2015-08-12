#!/bin/bash

COMMON_PROJECTS=( che-parent che-depmgt che-core che-plugins )
HOSTED_ONLY_PROJECTS=( hosted-infrastructure plugins plugin-gae odyssey factory user-dashboard )
ALL_PROJECTS=( ${COMMON_PROJECTS[@]} che ${HOSTED_ONLY_PROJECTS[@]} cloud-ide onpremises )
IDE_SDK_PROJECTS=( ${COMMON_PROJECTS[@]} che )
IDE_HOSTED_PROJECTS=( ${COMMON_PROJECTS[@]} ${HOSTED_ONLY_PROJECTS[@]} cloud-ide )
IDE_ONPREM_PROJECTS=( ${COMMON_PROJECTS[@]} ${HOSTED_ONLY_PROJECTS[@]} onpremises )
