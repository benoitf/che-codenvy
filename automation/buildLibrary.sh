#!/bin/bash

# If you want change functionality you can override functions of this library.
# As example call echo "start parsing options" before parsing parameters:
# Run script with such content
#
##############################################################
#    #!/bin/bash
#
#    source buildLibrary.sh
#    saveFunction parseParameters old_parseParameters
#    parseParameters() {
#        echo "start parsing options"
#        old_parseParameters "$@"
#    }
#    run "$@"
##############################################################
# To add custom parameters for script override parseCustomParameters function.
#

# call this function to run build
run() {
    # set exit on first error code from commands
    set -e
    set -o pipefail
    startNotificationsHandling

    COMMAND_LINE="$0 ""$@"

    # call main function and set to
    main "$@"

    type notify-send >/dev/null 2>&1 && notify-send -t 10000 --urgency=low -i "terminal" "Built successfully" "${COMMAND_LINE}"

    endNotificationsHandling
}

getUserHelp() {
    echo "usage: ./build.sh [-r <projectFrom> <projectTo>] [-r-hosted <projectFrom> <projectTo>] [-r-sdk <projectFrom> <projectTo>] [--r] [--r-hosted] [--r-sdk]"
    echo "                  [-l <project1> ... <projectN>] [-p <project>:<param>:...:<param>]"
    echo "                  [-e <project1> <project2>] [--r] [--r-sdk] [--r-hosted] [-continue-from project] [-continue-after project]"
    echo "                  [--notests|--t] [--o] [--fu] [-maven-additional-params|-build-param|-bparam 'additional maven parameters'] [--prl]"
    echo "                  [--no-pull|--pu] [--no-fetch] [-b branchToCheckout] [-bs branchToCheckoutIfExist] [-bh branchToCheckoutOrSkipProject] [--lc] [-lc 3]"
    echo "                  [--deployment-b|-deployment-b <branch>] [--deployment-pu|--deployment-no-pull]"
    echo "                  [--v|-v --b:--multi] [-upload <param>...<param>] [--che]"
    echo "                  [--nb|--no-build|--nobuild] [--dry] [-h|-help|--help] [--q] [--log]"
    echo ""
}

getProjectsHelp() {
    echo "-------------------Hosted projects--------------------"
    echo ${IDE_HOSTED_PROJECTS[@]}
    echo "-------------------OnPremises projects--------------------"
    echo ${IDE_ONPREM_PROJECTS[@]}
    echo "--------------------SDK projects----------------------"
    echo ${IDE_SDK_PROJECTS[@]}
    echo "--------------------All projects----------------------"
    echo ${ALL_PROJECTS[@]}
}

getOptionsHelp() {
    echo "Options:"
    echo "         -r"
    echo "             Set the range of projects to build. Separated by space. List of all projects will be used."
    echo "             Example:"
    echo "                      -r ide-old cloud-ide"
    echo ""
    echo "         --r"
    echo "             Build all project in the ALL range."
    echo ""
    echo "         -r-sdk"
    echo "             Set the range of projects to build. List of SDK projects will be used."
    echo "             For more information see -r parameter help"
    echo ""
    echo "         --r-sdk"
    echo "             Build all project in the SDK range."
    echo ""
    echo "         -r-hosted"
    echo "             Set the range of projects to build. List of Hosted IDE projects will be used."
    echo "             For more information see -r parameter help"
    echo ""
    echo "         --r-hosted"
    echo "             Build all project in the HOSTED range."
    echo ""
    echo "         -r-onprem"
    echo "             Set the range of projects to build. List of OnPremises IDE projects will be used."
    echo "             For more information see -r parameter help"
    echo ""
    echo "         --r-onprem"
    echo "             Build all project in the OnPremises range."
    echo ""
    echo "         -l"
    echo "             Set the list of projects to build. Separated by space."
    echo "             Per project parameters can be set with this option, e.g. plojectname:parameter:parameter2"
    echo "             See list of parameters in the help for -p parameter."
    echo "             Example:"
    echo "                      -l ide-old"
    echo "                      -l commons:--co cloud-ide"
    echo "                      -l cloud-ide:--co:--gwt"
    echo ""
    echo "         -p"
    echo "             Set additional configuration for certain project. Parameters are separated by colon."
    echo "             First argument is project name."
    echo "             Options:"
    echo "                      --co, --no-checkout"
    echo "                          Do not checkout to any branch, work with current state of directories."
    echo "                      --pu, --no-pull"
    echo "                          Do not make pull."
    echo "                      --gwt"
    echo "                          (For cloud-ide only) Do not build gwt module to speedup build."
    echo "                          Should be used only when IDE client has no changes."
    echo "                      --aio"
    echo "                          (For cloud-ide only) Build all-in-one tomcat and all upstream modules only. Allow speedup build."
    echo "                      --clean-local-repo"
    echo "                          Remove project's artifacts from local repository."
    echo "                      --no-build, --nb, --nobuild"
    echo "                          Do not build project with maven. Checkout, pull and so om will be performed."
    echo "                          To omit all actions with project use exclude option."
    echo "                      --docker"
    echo "                          Build project in docker instead of native build."
    echo "                          Only odyssey and user-dashboard projects support it for now."
    echo "                      --notests, --t"
    echo "                          Skip tests for project."
    echo "             Example:"
    echo "                      -p ide:--co"
    echo "                      -p ide:--co -p cloud-ide:--co:--gwt"
    echo "                      -p ide:--co:--clean-local-repo -p cloud-ide:--co:--aio:--gwt"
    echo ""
    echo "         -e"
    echo "             Set the list of projects to exclude from build. Separated by space."
    echo ""
    echo "         --notests, --t"
    echo "             Do not run tests."
    echo ""
    echo "         --o"
    echo "             Use maven offline option."
    echo ""
    echo "         --fu"
    echo "             Add -U to maven command on build of first project"
    echo ""
    echo "         --no-pull, --pu"
    echo "             Do not make pull."
    echo ""
    echo "         --no-fetch"
    echo "             Do not make fetch of changes from the remote"
    echo ""
    echo "         -b"
    echo "             Set checkout branch. By default cbuild doesn't checkout to a specific branch."
    echo "             Example: -b CLDIDE-1735"
    echo ""
    echo "         -bs"
    echo "             Set checkout branch. If branch doesn't exist in project cbuild doesn't do checkout."
    echo "             Example: -bs CLDIDE-1735"
    echo "         -bh"
    echo "             Set checkout branch. If branch doesn't exist in project cbuild skip project build."
    echo "             Example: -bs CLDIDE-1735"
    echo ""
    echo "         -lc"
    echo "             Checkout to latest commit N days ago. N is an argument."
    echo ""
    echo "         --lc"
    echo "             Chechout to latest commit 1 day ago."
    echo ""
    echo "         -v"
    echo "             Call vagrant.sh after succesfull build. Accept vagrant options separated by colon. Do not build option is used by default."
    echo "             If one options only is used colon can be ommitted. More about vagrant optins see in vagrant.sh help."
    echo "             Note that if cloud-ide wasn't set by set projects parameters it will be checkouted to master, pulled and built."
    echo "             Example:"
    echo "                      -v --multi:--d"
    echo "                      -v --d"
    echo ""
    echo "         --v"
    echo "             Call vagrant script without additional parameters. Default no build option is still used."
    echo "             Note that if cloud-ide wasn't set by set projects parameters it will be checkouted to master, pulled and built."
    echo ""
    echo "         --dry"
    echo "             Dry run"
    echo ""
    echo "         -maven-additional-params, -build-param, -bparam"
    echo "             REQUIRE: all maven params should be single quoted as one string"
    echo "             Add custom maven params. Should be quoted with a single quote mark."
    echo "             Example:"
    echo "                      -maven-additional-params '--settings /home/user/maven_settings.xml'"
    echo ""
    echo "         -upload"
    echo "             Call upload script after build."
    echo "             Note that if cloud-ide wasn't set by set projects parameters it will be checkouted to master, pulled and built."
    echo "             Example:"
    echo "                      -upload t2 all"
    echo ""
    echo "         -h, -help, --help"
    echo "             Show user help"
    echo ""
    echo "         --clean-local-repo"
    echo "             Remove project's artifacts from local repository."
    echo ""
    echo "         --prl"
    echo "             Execute maven with parallel option -T 1C. Parallel build in maven is experimental feature, so use it on your own risk."
    echo "             Known bugs: mycila license plugin sometimes brakes build."
    echo ""
    echo "         -continue-from"
    echo "             Continue build of projects from a specified one"
    echo ""
    echo "         -continue-after"
    echo "             Continue build of projects from a project that is next after specified one."
    echo ""
    echo "         --nb, --no-build, --nobuild"
    echo "             Do not build projects, but still execute other operations"
    echo ""
    echo "         --che"
    echo "             Run che"
    echo ""
    echo "         -deployment-b"
    echo "             Checkout to specified branch in deployment project"
    echo ""
    echo "         --deployment-b"
    echo "             Checkout to branch configured by -b or -bs options in deployment project"
    echo ""
    echo "         --deployment-pu, --deployment-no-pull"
    echo "             Do not make pull in deployment project"
    echo ""
    echo "         --q"
    echo "             Add quiet option to maven command"
    echo ""
    echo "         --log"
    echo "             Write logs to temp directory"
    echo ""
    echo "Examples:"
    echo "         ./build.sh -r commons cloud-ide # build all projects from commons to cloud-ide"
    echo "         ./build.sh --r-sdk --notests --co --no-pull # build all projects from SDK scope, skip tests, skip pull, skip checkout"
    echo "         ./build.sh -l hosted-infrastructure platform-api:--co plugin-hosted --v # build hosted-infrastructure platform-api plugin-hosted(will be auto-sorted), do not checkout in platform-api, deploy to dev.box"
    echo "         ./build.sh -r-hosted commons cloud-ide:--gwt -e user-dashboard # build projects from commons to cloud-ide in hosted scope except user-dashboard, do not build IDE3 war"
}

# Process unknown arguments for library
# return - number of arguments to shift
#
# To add new parameter with new action add processing of that parameter to
# overrided function parseCustomParameters. If argument is unknown function must return 0.
# If argument is known process it and return number of arguments to be shifted.
# Example:
# If you add parameter -do_something argument1 argument 2 overrided function must return 3
parseCustomParameters() {
    echo 0
}

main() {
    local startTime=$(date +%s)

    source projectsList.sh

    # change dir from deployment/automation to codenvy projects dir
    cd $HOME

    CURRENT_PROJECTS=()
    EXCLUDED_PROJECTS=()
    NO_CHECKOUT_PROJECTS=()
    CLEAN_LOCAL_REPO_PROJECTS=()
    SKIP_BUILD_PROJECTS=()
    SKIP_TESTS_PROJECTS=()
    USE_DOCKER_FOR=()
    DO_NOT_MAKE_PULL_PROJECTS=()

    SKIP_PULL=false
    BRANCH=""
    PROJECTS_ARE_SET=false
    MAVEN_PARAMS=""
    MAVEN_COMMAND=""
    CHECKOUT_AGO=false
    BUILD_GWT_IN_CLOUD_IDE=true
    BUILD_ALL_IN_ONE_ONLY_IN_CLOUD_IDE=false
    RUN_VAGRANT=false
    DRY_RUN=false
    VAGRANT_PARAMS="--nobuild"
    RUN_UPLOAD=false
    RUN_CHE=false
    UPLOAD_PARAMS="--nobuild"
    USE_MAVEN_UPDATES_SNAPSHOTS_ON_FIRST_PROJECT=false
    # can be also 'soft-checkout', 'checkout', 'hard-checkout'
    CHECKOUT_STRATEGY="no-checkout"
    DO_NOT_BUILD=false
    # can be also 'checkout', 'checkout-to-projects-branch'
    DEPLOYMENT_CHECKOUT_STRATEGY='no-checkout'
    DEPLOYMENT_MAKE_PULL=true
    DEPLOYMENT_BRANCH=""
    QUIET=false
    LOG=false
    SKIP_FETCH=false

    # parse parameters specified by user
    parseParameters "$@"

    # print configuration summary
    logplain '================================================'
    logplain "==============Configuration====================="
    logplain "DRY_RUN:..............................."${DRY_RUN}
    logplain "QUIET:................................."${QUIET}
    logplain "LOG...................................."${LOG}
    # avoid indentation for aligning
    if [ ${LOG} == true ]; then
    logplain "LOG_FILE.............................../tmp/cbuild/cbuild.log"
    fi

    logplain "------------VCS---------------------------------"
    logplain "SKIP_PULL:............................."${SKIP_PULL}
    logplain "SKIP_FETCH:............................"${SKIP_FETCH}
    if [ ${SKIP_PULL} == false ]; then
    logplain "DO_NOT_MAKE_PULL_PROJECTS:............."${DO_NOT_MAKE_PULL_PROJECTS[@]}
    fi
    logplain "CHECKOUT_STRATEGY:....................."${CHECKOUT_STRATEGY}
    if [ ${CHECKOUT_STRATEGY} != "no-checkout" ]; then
    logplain "BRANCH:................................"${BRANCH}
    logplain "CHECKOUT_AGO:.........................."${CHECKOUT_AGO}
    logplain "NO_CHECKOUT_PROJECTS:.................."${NO_CHECKOUT_PROJECTS[@]}
    fi
    logplain "DEPLOYMENT_CHECKOUT_STRATEGY..........."${DEPLOYMENT_CHECKOUT_STRATEGY}
    if [ ${DEPLOYMENT_CHECKOUT_STRATEGY} == "checkout" ]; then
    logplain "DEPLOYMENT_BRANCH......................"${DEPLOYMENT_BRANCH}
    elif [ ${DEPLOYMENT_CHECKOUT_STRATEGY} == "checkout-to-projects-branch" ]; then
    logplain "DEPLOYMENT_BRANCH......................"${BRANCH}
    fi
    logplain "DEPLOYMENT_MAKE_PULL..................."${DEPLOYMENT_MAKE_PULL}

    logplain "------------BUILD-------------------------------"
    logplain "DO_NOT_BUILD:.........................."${DO_NOT_BUILD}
    if [ ${DO_NOT_BUILD} == false ]; then
    logplain "MAVEN_PARAMS:.........................."${MAVEN_PARAMS}
    logplain "USE -U WITH_1ST_PROJECT:..............."${USE_MAVEN_UPDATES_SNAPSHOTS_ON_FIRST_PROJECT}
    logplain "BUILD_GWT_IN_CLODIDE:.................."${BUILD_GWT_IN_CLOUD_IDE}
    logplain "CLEAN_LOCAL_REPO_PROJECTS:............."${CLEAN_LOCAL_REPO_PROJECTS[@]}
    logplain "SKIP_BUILD_PROJECTS:..................."${SKIP_BUILD_PROJECTS[@]}
    logplain "SKIP_TESTS_PROJECTS:..................."${SKIP_TESTS_PROJECTS[@]}
    logplain "USE_DOCKER_FOR:........................"${USE_DOCKER_FOR[@]}
    fi

    logplain "------------DEPLOY------------------------------"
    logplain "RUN_VAGRANT:..........................."${RUN_VAGRANT}
    if [ ${RUN_VAGRANT} == true ]; then
    logplain "VAGRANT_PARAMS:........................"${VAGRANT_PARAMS}
    fi
    logplain "RUN_UPLOAD:............................"${RUN_UPLOAD}
    if [ ${RUN_UPLOAD} == true ]; then
    logplain "UPLOAD_PARAMS:........................."${UPLOAD_PARAMS}
    fi
    logplain "RUN_CHE:..............................."${RUN_CHE}

    logplain "-----------Projects-----------------------------"

    firstProject=true

    for i in ${CURRENT_PROJECTS[@]}; do
        logplain ${i}
    done
    logplain '================================================'

    # start build process

    # call build for each project in the list
    for i in ${CURRENT_PROJECTS[@]}
    do
        doBuildProject ${i}
    done

    # Deploy

    # run che if it is specified
    if [ ${RUN_CHE} == true ]; then
        runChe
    fi

    if [ ${DEPLOYMENT_CHECKOUT_STRATEGY} != 'no-checkout' ]; then
        checkoutDeployment
    fi

    if [[ ${RUN_VAGRANT} == true || ${RUN_UPLOAD} == true ]]; then
        buildCloudIdeBeforeDeployIfNeeded
    fi

    # run vagrant if it specified
    if [ ${RUN_VAGRANT} == true ]; then
        runVagrant
    fi
    # run upload if it specified
    if [ ${RUN_UPLOAD} == true ]; then
        runUpload
    fi

    logplain '================================================'
    logplain '          Projects building is completed'
    local endTime=$(date +%s)
    local timeDiff=$(( ${endTime} - ${startTime} ))
    local minutesDiff=$(( ${timeDiff} / 60 ))
    local secondsDiff=$(( ${timeDiff} - ( ${minutesDiff} * 60 ) ))
    logplain '================================================'
    logplain "          Started   : $(date --date "@${startTime}" +%T)"
    logplain "          Ended     : $(date --date "@${endTime}" +%T)"
    logplain "          Time spend: ${minutesDiff}m:${secondsDiff}s"
    logplain '================================================'
}

parseParameters() {
    if [ $# == 0 ]; then
        logerror "cbuild:$LINENO Parameters list is empty."
        getUserHelp; exit 1
    fi

    for (( i=1; i<=$#; i++ ))
    do
        case ${!i} in
            --help | -h | -help)
                getUserHelp && getProjectsHelp && getOptionsHelp; exit 0
                ;;
            --notests | --t)
                MAVEN_PARAMS=${MAVEN_PARAMS}" -Dmaven.test.skip=true"
                ;;
            --o)
                MAVEN_PARAMS=${MAVEN_PARAMS}" -o"
                ;;
            --fu)
                USE_MAVEN_UPDATES_SNAPSHOTS_ON_FIRST_PROJECT=true
                ;;
            --no-pull | --pu)
                SKIP_PULL=true
                ;;
            --no-fetch)
                SKIP_FETCH=true
                ;;
            -lc | --lc)
                CHECKOUT_STRATEGY='checkout'
                if [ ${!i} == "--lc" ]; then
                    CHECKOUT_AGO=1
                else
                    i=$(expr ${i} + 1)
                    CHECKOUT_AGO=${!i}
                fi
                ;;
            -b | -bs | -bh)
                if [ ${!i} == "-b" ]; then
                    CHECKOUT_STRATEGY='checkout'
                elif [ ${!i} == "-bh" ]; then
                    CHECKOUT_STRATEGY='hard-checkout'
                else
                    CHECKOUT_STRATEGY='soft-checkout'
                fi
                i=$(expr ${i} + 1)
                BRANCH=${!i}
                ;;
            -r | --r | -r-sdk | --r-sdk | -r-hosted | --r-hosted | -r-onprem | --r-onprem )
                case ${!i} in
                    -r | --r)
                        local current_projects=(${ALL_PROJECTS[@]})
                        ;;
                    -r-sdk | --r-sdk)
                        local current_projects=(${IDE_SDK_PROJECTS[@]})
                        ;;
                    -r-hosted | --r-hosted)
                        local current_projects=(${IDE_HOSTED_PROJECTS[@]})
                        ;;
                    -r-onprem | --r-onprem)
                        local current_projects=(${IDE_ONPREM_PROJECTS[@]})
                        ;;
                esac
                if [[ ${!i} == --* ]]; then
                    setProjectsRange "all" ${current_projects[@]}
                else
                    starts=$(expr ${i} + 1)
                    ends=$(expr ${i} + 2)
                    if [ ${ends} -gt $# ]; then
                        logerror "cbuild:$LINENO Range parameter require two arguments."
                        getUserHelp
                        exit 1
                    fi
                    setProjectsRange ${!starts} ${!ends} ${current_projects[@]}
                    i=$(expr ${i} + 2)
                fi
                ;;
            -l)
                if [ ${PROJECTS_ARE_SET} == true ]; then
                    logerror "cbuild:$LINENO Parameters -r -r-sdk -r-hosted -r-onprem -l --r --r-sdk --r-hosted --r-onprem can't be used together."
                    exit 1
                fi
                for (( projectCounter=$(expr ${i} + 1); projectCounter<=$#; projectCounter++ ))
                do
                    if [[ ${!projectCounter} != -* ]]; then
                        local PROJECT_WITH_CUSTOM_CONFIGURATION=(${!projectCounter//:/ })
                        local projectName=${PROJECT_WITH_CUSTOM_CONFIGURATION[0]}
                        # check that projects list contains this project
                        [[ $(getIndexInArray ${projectName} ${ALL_PROJECTS[@]}) == -1 ]] && logerror "${projectName} is not found." && getProjectsHelp && exit 1
                        # process project configuration
                        processProjectConf ${!projectCounter}
                        # add project to current projects list
                        PROJECTS_TO_SORT+=(${projectName})

                        i=$(expr ${i} + 1)
                    else
                        break
                    fi
                done
                if [ ${#PROJECTS_TO_SORT[@]} == 0 ]; then
                    logerror "cbuild:$LINENO Parameter -l has no appropriate arguments."
                    getUserHelp && getProjectsHelp; exit 1
                fi
                # sort projects
                for candidate in ${ALL_PROJECTS[@]}
                do
                    local candIndex=$(getIndexInArray ${candidate} ${PROJECTS_TO_SORT[@]})
                    if [ ${candIndex} != "-1" ]; then
                        CURRENT_PROJECTS+=(${candidate})
                    fi
                done
                PROJECTS_ARE_SET=true
                ;;
            -p)
                i=$(expr ${i} + 1)
                processProjectConf ${!i}
                ;;
            -e)
                for (( excludeProjectCounter=$(expr ${i} + 1); excludeProjectCounter<=$#; excludeProjectCounter++ ))
                do
                    if [[ ${!excludeProjectCounter} != -* ]]; then
                        EXCLUDED_PROJECTS+=(${!excludeProjectCounter})
                        i=$(expr ${i} + 1)
                    else
                        break
                    fi
                done
                ;;
            -v | --v)
                if [ ${!i} == "-v" ]; then
                    i=$(expr ${i} + 1)
                    VAGRANT_PARAMS+=" "${!i//:/ }
                fi
                RUN_VAGRANT=true
                ;;
            --che)
                RUN_CHE=true
                ;;
            -upload)
                firstArgument=$(expr ${i} + 1)
                secondArgument=$(expr ${i} + 2)
                if [[ ${secondArgument} != -* ]]; then
                    UPLOAD_PARAMS=${!firstArgument}" "${!secondArgument}" "${UPLOAD_PARAMS}
                    i=$(expr ${i} + 2)
                else
                    UPLOAD_PARAMS=${!firstArgument}" "${UPLOAD_PARAMS}
                    i=$(expr ${i} + 1)
                fi
                RUN_UPLOAD=true
                ;;
            --dry)
                DRY_RUN=true
                ;;
            -maven-additional-params | -bparam | -build-param)
                i=$(expr ${i} + 1)
                MAVEN_PARAMS=${MAVEN_PARAMS}" ${!i}"
                ;;
            -continue-from)
                if [ ! -z ${continueFrom} ]; then
                    logerror "cbuild:$LINENO -continue-from and -continue-after options can't be used at the same time"
                    getUserHelp; exit 1
                fi

                i=$(expr ${i} + 1)
                local continueFromIndex=$(getIndexInArray ${!i} ${CURRENT_PROJECTS[@]})
                if [ ${continueFromIndex} == -1 ]; then
                    logerror "Unknown project name ${!i} is used as an argument of -continue-from option"
                    getUserHelp && getProjectsHelp; exit 1
                fi
                continueFrom=${!i}
                ;;
            -continue-after)
                if [ ! -z ${continueFrom} ]; then
                    logerror "cbuild:$LINENO -continue-from and -continue-after options can't be used at the same time"
                    getUserHelp; exit 1
                fi

                i=$(expr ${i} + 1)
                local continueAfterIndex=$(getIndexInArray ${!i} ${CURRENT_PROJECTS[@]})
                if [ ${continueAfterIndex} == -1 ]; then
                    logerror "cbuild:$LINENO Unknown project name ${!i} is used as an argument of -continue-after option"
                    getUserHelp && getProjectsHelp; exit 1
                fi
                if [ ${#CURRENT_PROJECTS[@]} -eq $((continueAfterIndex + 1)) ]; then
                    logerror "cbuild:$LINENO Option -continue-after points to the projects out of current projects set"
                    getUserHelp && getProjectsHelp; exit 1
                fi
                continueFrom=${CURRENT_PROJECTS[$((continueAfterIndex + 1))]}
                ;;
            --clean-local-repo)
                local clean_command="mvn build-helper:remove-project-artifact"
                if [ ${QUIET} == true ]; then
                    clean_command+=" -q && "
                else
                    clean_command+=" && "
                fi
                MAVEN_COMMAND=${clean_command}${MAVEN_COMMAND}
                ;;
            --prl)
                MAVEN_PARAMS=${MAVEN_PARAMS}" -T 1C"
                ;;
            --no-build | --nb | --nobuild)
                DO_NOT_BUILD=true
                ;;
            --deployment-b)
                DEPLOYMENT_CHECKOUT_STRATEGY="checkout-to-projects-branch"
                ;;
            -deployment-b)
                DEPLOYMENT_CHECKOUT_STRATEGY="checkout"
                i=$(expr ${i} + 1)
                DEPLOYMENT_BRANCH=${!i}
                ;;
            --deployment-pu | --deployment-no-pull)
                DEPLOYMENT_MAKE_PULL=false
                ;;
            --q)
                QUIET=true
                ;;
            --log)
                log_enabled=true
                ;;
            *)
                local shiftTo=$(parseCustomParameters ${@})
                if [ ${shiftTo} == 0 ]; then
                    logerror "cbuild:$LINENO Unknown parameter ${!i}."
                    getUserHelp
                    exit 1
                else
                    i=$(expr ${i} + ${shiftTo} - 1)
                fi
                ;;
        esac
    done

    if [ ! -z ${continueFrom} ]; then
        local continueFromIndex=$(getIndexInArray ${continueFrom} ${CURRENT_PROJECTS[@]})
        if [ ${continueFromIndex} == -1 ]; then
            logerror "cbuild:$LINENO Unknown project ${continueFrom} is used as an argument of -continue-from option"
            getUserHelp && getProjectsHelp; exit 1
        fi
        CURRENT_PROJECTS=(${CURRENT_PROJECTS[@]:$((${continueFromIndex}))})
    fi

    for excludeProject in ${EXCLUDED_PROJECTS[@]}
    do
        local removeIndex=$(getIndexInArray ${excludeProject} ${CURRENT_PROJECTS[@]})
        if [ ${removeIndex} == -1 ]; then
            removeIndex=$(getIndexInArray ${excludeProject} ${ALL_PROJECTS[@]})
            if [ ${removeIndex} == -1 ]; then
                logerror "Unknown project ${excludeProject} is used as an argument of -e option"
                getProjectsHelp; exit 1
            else
                logerror "Project ${excludeProject} used as an argument of -e option is out of current scope"
                continue
            fi
        fi
        CURRENT_PROJECTS=(${CURRENT_PROJECTS[@]:0:${removeIndex}} ${CURRENT_PROJECTS[@]:$((${removeIndex} + 1))})
    done

    if [ "${log_enabled}" == true ]; then
        LOG=true
        mkdir -p /tmp/cbuild
        if [ -f /tmp/cbuild/cbuild.log ]; then
            rm -rf /tmp/cbuild/cbuild.log_bk
            mv /tmp/cbuild/cbuild.log /tmp/cbuild/cbuild.log_bk
        fi
    fi
}

createMavenCommand() {
    local MAVEN_PER_PROJECT_PARAMS=""
    if [[ ${firstProject} == true && ${USE_MAVEN_UPDATES_SNAPSHOTS_ON_FIRST_PROJECT} == true ]]; then
        MAVEN_PER_PROJECT_PARAMS=${MAVEN_PER_PROJECT_PARAMS}' -U'
        firstProject=false
    fi

    local projectConfigurationIndex=$(getIndexInArray ${1} ${SKIP_TESTS_PROJECTS[@]})
    if [ ${projectConfigurationIndex} != "-1" ]; then
        MAVEN_PER_PROJECT_PARAMS=${MAVEN_PER_PROJECT_PARAMS}' -Dmaven.test.skip=true'
    fi

    if [[ ${1} == cloud-ide* ]]; then
        if [ ${BUILD_GWT_IN_CLOUD_IDE} == false ]; then
            MAVEN_PER_PROJECT_PARAMS=${MAVEN_PER_PROJECT_PARAMS}" -pl \"!cloud-ide-compiling-war-next-ide-codenvy\""
        fi
        if [ ${BUILD_ALL_IN_ONE_ONLY_IN_CLOUD_IDE} == true ]; then
            MAVEN_PER_PROJECT_PARAMS=${MAVEN_PER_PROJECT_PARAMS}" -pl \"cloud-ide-packaging-tomcat-codenvy-allinone\" --also-make"
        fi
    fi

    MAVEN_COMMAND=""
    if [ ${DO_NOT_BUILD} == false ]; then
        local projectConfigurationIndex=$(getIndexInArray ${1} ${SKIP_BUILD_PROJECTS[@]})
        if [ ${projectConfigurationIndex} != "-1" ]; then
            MAVEN_COMMAND=""
        else
            MAVEN_COMMAND="mvn clean install"
            if [ ${QUIET} == true ]; then
                MAVEN_COMMAND+=" -q"
            fi
            MAVEN_COMMAND+=" "${MAVEN_PARAMS}" "${MAVEN_PER_PROJECT_PARAMS}
        fi

        projectConfigurationIndex=$(getIndexInArray ${1} ${CLEAN_LOCAL_REPO_PROJECTS[@]})
        if [ ${projectConfigurationIndex} != "-1" ]; then
            local clean_command="mvn build-helper:remove-project-artifact"
            if [ ${QUIET} == true ]; then
                clean_command+=" -q && "
            fi
            MAVEN_COMMAND=${clean_command}${MAVEN_COMMAND}
        fi
    fi

    echo ${MAVEN_COMMAND} && return 0
}

doBuildProject() {
    PROJECT=${1}

    if [ ! -d ${1} ]; then
        logerror "cbuild:$LINENO ${1} directory not found! Try to clone it ..."
        clone ${1}
    fi
    loginfo "cd ${1}"
    cd ${1}

    if [ ${SKIP_FETCH} == false ]; then
        # usefull when -b is used and specified branch wasn't fetched in the repo yet. prune remove links to removed upstreams
        loginfo "git remote update --prune"
        if [ ${DRY_RUN} == false ]; then
            cbuildEval "git remote update --prune"
        fi
    fi

    local projectConfigurationIndex=$(getIndexInArray ${1} ${NO_CHECKOUT_PROJECTS[@]})
    if [[ ${CHECKOUT_STRATEGY} != "no-checkout" && ${projectConfigurationIndex} == "-1" ]]; then
        if [[ ${CHECKOUT_STRATEGY} == "hard-checkout" && $(git show-ref --quiet ${BRANCH} && echo "0" || echo "-1") == -1 ]]; then
            loginfo "Skip project build because branch ${BRANCH} is missing."
            return;
        else
            gitCheckOut
        fi
    else
        loginfo "Do not checkout. Current branch $(git rev-parse --abbrev-ref HEAD)"
    fi

    local projectConfigurationIndex=$(getIndexInArray ${1} ${DO_NOT_MAKE_PULL_PROJECTS[@]})
    if [[ ${SKIP_PULL} == false && ${projectConfigurationIndex} == "-1" ]]; then
        loginfo "git pull"
        if [ ${DRY_RUN} == false ]; then
            git pull
        fi
    fi

    local BUILD_COMMAND=$(createMavenCommand ${1})
    # Check if project should be built in the docker
    projectConfigurationIndex=$(getIndexInArray ${1} ${USE_DOCKER_FOR[@]})
    if [ ${projectConfigurationIndex} != "-1" ]; then
        local BUILD_COMMAND="docker run -i -t -e USRID=$(id -u) -e USRGR=$(id -g) -v $(pwd):/home/user/app -v ${HOME}/.m2:/home/user/.m2 vkuznyetsov/odyssey-java8-docker-build bash -c \"sudo chown user:user -R /home/user/app /home/user/.m2 && $BUILD_COMMAND || BUILD_FAILED=true; sudo chown \\\$USRID:\\\$USRGR -R /home/user/app /home/user/.m2; [[ \\\${BUILD_FAILED} != true ]]\""
    fi

    loginfo "${BUILD_COMMAND}"
    if [ ${DRY_RUN} == false ]; then
        if [ ${LOG} == true ]; then
            eval "${BUILD_COMMAND}" 2>&1 | tee -a /tmp/cbuild/cbuild.log
        else
            eval "${BUILD_COMMAND}"
        fi
    fi

    loginfo "cd .."
    cd ..

    unset PROJECT
}

runVagrant() {
    loginfo "cd cloud-ide"
    cd cloud-ide

    loginfo "./vagrant.sh ${VAGRANT_PARAMS}"
    if [ ${DRY_RUN} == false ]; then
        ./vagrant.sh ${VAGRANT_PARAMS}
    fi

    loginfo "cd .."
    cd ..
}

runUpload() {
    loginfo "cd cloud-ide"
    cd cloud-ide

    loginfo "./upload.sh ${UPLOAD_PARAMS}"
    if [ ${DRY_RUN} == false ]; then
        ./upload.sh ${UPLOAD_PARAMS}
    fi

    loginfo "cd .."
    cd ..
}

runChe() {
    loginfo "cd che"
    cd che

    loginfo "./che.sh jpda run"
    if [ ${DRY_RUN} == false ]; then
        ./che.sh jpda run
    fi


    loginfo "cd .."
    cd ..
}

checkoutDeployment() {
    loginfo "cd deployment"
    cd deployment

    loginfo "git remote update --prune"
    git remote update --prune

    if [ ${DEPLOYMENT_CHECKOUT_STRATEGY} == "checkout-to-projects-branch" ]; then
        local branch=${BRANCH}
    else
        local branch=${DEPLOYMENT_BRANCH}
    fi

    if [ ${DRY_RUN} == false ]; then
        loginfo "git checkout ${branch}"
        git checkout ${branch}
    fi

    if [ ${DEPLOYMENT_MAKE_PULL} == true ]; then
        loginfo "git pull"
        if [ ${DRY_RUN} == false ]; then
            git pull
        fi
    fi

    loginfo "cd .."
    cd ..
}

# Build cloud-ide project if it is not in the list of projects to build.
# It is allowed to use it before calling deploy functions only.
# This function does not checkout to master, do pull and do build with base maven parameters.
buildCloudIdeBeforeDeployIfNeeded() {
    local cloudideIndex=$(getIndexInArray cloud-ide ${CURRENT_PROJECTS[@]})
    # if cloud-ide wasn't set explicitly and list of projects is not empty
    # "cbuild --v" - projects list is empty. Can be used to deploy without any build
    if [[ ${cloudideIndex} == "-1" && ${#CURRENT_PROJECTS[@]} -ne 0 ]]; then
        loginfo "cloud-ide is not in the projects set and should be built implicitly to use deployment scripts"
        loginfo "cd cloud-ide"
        cd cloud-ide
        loginfo "git pull -p"
        if [ ${DRY_RUN} == false ]; then
            git pull -p
        fi

        local buildCmd="mvn clean install"
        if [ ${QUIET} == true ]; then
            buildCmd+=" -q"
        fi

        loginfo "${buildCmd}"
        if [ ${DRY_RUN} == false ]; then
            eval "${buildCmd}"
        fi
        loginfo "cd .."
        cd ..
    fi
}

setProjectsRange() {
    if [ ${PROJECTS_ARE_SET} == true ]; then
        logerror "cbuild:$LINENO Parameters -r -r-sdk -r-hosted -r-onprem -l --r --r-sdk --r-hosted --r-onprem can't be used together."
        exit 1
    fi
    local buildFrom=${1}
    shift
    if [ ${buildFrom} == "all" ]; then
        local buildFromIndex=0
        local PROJECTS_LIST=( $( echo $@ ) )
        local buildUntilIndex=$(expr ${#PROJECTS_LIST[@]} - 1)
    else
        local buildUntil=${1}
        shift
        local PROJECTS_LIST=( $( echo $@ ) )
        local buildFromIndex=$(getIndexInArray ${buildFrom} ${PROJECTS_LIST[@]})
        [[ ${buildFromIndex} == -1 ]] && logerror "cbuild:$LINENO Project ${buildFrom} is not found for that projects set." && exit 1
        local buildUntilIndex=$(getIndexInArray ${buildUntil} ${PROJECTS_LIST[@]})
        [[ ${buildUntilIndex} == -1 ]] && logerror "cbuild:$LINENO Project ${buildUntil} is not found for that projects set." && exit 1
    fi

    CURRENT_PROJECTS=( ${PROJECTS_LIST[@]:${buildFromIndex}:$(expr ${buildUntilIndex} - ${buildFromIndex} + 1)} )
    PROJECTS_ARE_SET=true
}

processProjectConf() {
    local projectCustomConfiguration=(${1//:/ })
    local projectName=${projectCustomConfiguration[0]}
    for confEntry in ${projectCustomConfiguration[@]:1}
    do
        case ${confEntry} in
            --co | --no-checkout)
                NO_CHECKOUT_PROJECTS+=(${projectName})
                ;;
            --clean-local-repo)
                CLEAN_LOCAL_REPO_PROJECTS+=(${projectName})
                ;;
            --pu | --no-pull)
                DO_NOT_MAKE_PULL_PROJECTS+=(${projectName})
                ;;
            --aio | --gwt)
                if [[ ${projectName} != cloud-ide* ]]; then
                    logerror "cbuild:$LINENO ${confEntry} option can be used with cloud-ide project only"
                    exit 1
                fi

                local mvn_version=`mvn -v | grep "Apache Maven" | sed 's/Apache Maven //g' | sed 's/ .*//g'`
                if [[ "${mvn_version}" < "3.2.1" ]]; then
                    logerror "cbuild:$LINENO '--gwt' is supported for maven 3.2.1 or later"
                    exit 1
                else
                    if [ ${confEntry} == "--aio" ]; then
                        BUILD_ALL_IN_ONE_ONLY_IN_CLOUD_IDE=true
                    else
                        BUILD_GWT_IN_CLOUD_IDE=false
                    fi
                fi
                ;;
            --no-build | --nb | --nobuild)
                SKIP_BUILD_PROJECTS+=(${projectName})
                ;;
            --notests | --t)
                SKIP_TESTS_PROJECTS+=(${projectName})
                ;;
            --docker)
                if [[ ${projectName} != "odyssey" && ${projectName} != "user-dashboard" ]]; then
                    logerror "cbuild:$LINENO Docker build is supported for odyssey and user-dashboard projects only"
                    exit 1
                fi
                USE_DOCKER_FOR+=(${projectName})
                ;;
            *)
                logerror "cbuild:$LINENO Unknown parameter ${confEntry} of project configuration is used"
                getUserHelp; exit 1
                ;;
        esac
    done
}

gitCheckOut() {
    if [ ${CHECKOUT_AGO} != false ]; then
        local commit=$(git log -1 --until="${CHECKOUT_AGO} day ago" --oneline | sed 's/ .*//g')
        loginfo "Checkout to last yestarday's commit: git checkout ${commit}"
        if [ ${DRY_RUN} == false ]; then
            git checkout ${commit}
        fi
    else
        if [[ $(git show-ref --quiet ${BRANCH} && echo "0" || echo "-1") == 0 || ${CHECKOUT_STRATEGY} != "soft-checkout" ]]; then
            loginfo "git checkout ${BRANCH}"
            if [ ${DRY_RUN} == false ]; then
                git checkout ${BRANCH}
            fi
        else
            loginfo "Branch ${BRANCH} is not found. Do not checkout. Current branch $(git rev-parse --abbrev-ref HEAD)"
        fi
    fi
}

clone() {
    local project_https_url=$(curl  --silent 'https://api.github.com/orgs/codenvy/repos?type=public&per_page=100' -q | grep "\"clone_url\"" | awk -F': "' '{print $2}' | sed -e 's/",//g' | grep "/${1}\.git")
    if [ -z ${project_https_url} ]; then
        git clone "git@github.com:codenvy/${1}.git"
    else
        git clone ${project_https_url}
    fi
}

# query value...value
getIndexInArray() {
    local str=$1; shift
    local array=( $( echo $@ ) )
    for (( i=0; i<${#array[*]}; i++ )); do
        [ ${array[$i]} == ${str} ] && echo ${i} && return 0
    done
    echo "-1" && return 0
}

startNotificationsHandling() {
   # catch stopping over exit command
   trap 'onAbort' EXIT
}

# send notification if build fails
onAbort() {
    if (($? != 0)); then
        type notify-send >/dev/null 2>&1 && notify-send -t 1000 --urgency=normal -i "error" "Build failed" "${COMMAND_LINE} \n ${ERROR_MESSAGE}"
        printContinueHint
        exit 1
    fi
    exit 0
}

printContinueHint() {
    if [ ! -z ${PROJECT} ]; then
        loginfo "After correcting the problems, you can resume the build by adding -continue-from ${PROJECT} or continue but skip failed operation by adding -continue-after ${PROJECT}"
        if [[ "${COMMAND_LINE}" == /usr/bin/cbuild* ]]; then
            local cmd_line="${COMMAND_LINE:9}"
        else
            local cmd_line="${COMMAND_LINE}"
        fi

        cmd_line=$(echo "${cmd_line}" | sed "s/ -continue-from [^ ]\+//g" | sed "s/ -continue-after [^ ]\+//g")

        loginfo "${cmd_line}"" -continue-after ${PROJECT}"
        loginfo "${cmd_line}"" -continue-from ${PROJECT}"
    fi
}

endNotificationsHandling() {
    # unset catch stopping over exit command
    trap : EXIT
}

saveFunction() {
    local ORIG_FUNC=$(declare -f $1)
    local NEWNAME_FUNC="$2${ORIG_FUNC#$1}"
    eval "$NEWNAME_FUNC"
}

logerror() {
    ERROR_MESSAGE="$@"
    makeRed "$@"
    if [ ${LOG} == true ]; then
        echo "$@" >> /tmp/cbuild/cbuild.log
    fi
}

loginfo() {
    makeGreen "$@"
    if [ ${LOG} == true ]; then
        echo "$@" >> /tmp/cbuild/cbuild.log
    fi
}

logplain() {
    echo "$@"
    if [ ${LOG} == true ]; then
        echo "$@" >> /tmp/cbuild/cbuild.log
    fi
}

makeGreen() {
    echo $(tput setaf 2)"$@"$(tput sgr 0)
}

makeRed() {
    echo $(tput setaf 1)"$@"$(tput sgr 0)
}

cbuildEval() {
    if [ "${LOG}" == true ]; then
        eval "$@" 2>&1 | tee -a /tmp/cbuild/cbuild.log
    else
        eval "$@"
    fi
}
