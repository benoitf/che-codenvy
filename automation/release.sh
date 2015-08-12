set -e

updateVersion(){
	version_old=$(grep -m 1 $2 pom.xml | awk '{print $1}')
	version_new="<$2>$1</$2>"
        if [ "$version_old" != "$version_new" ]; then
          echo "Replace $version_old with $version_new in $2"
          sed -i  -e "s#$version_old#$version_new#"  pom.xml
        fi

}

releaseProject(){
  	echo "release $1"
        cd $1
	git pull
	mvn --batch-mode release:prepare release:perform -Dresume=false -Darguments=-Dgpg.passphrase=Ya3Waa2O -Dtag=$2 -DdevelopmentVersion=$3 -DreleaseVersion=$2
        cd ..
}

updateDepMgtPom(){
 cd che-depmgt
 git pull

# CHE
 updateVersion $CHE_CORE_VERSION                 "che.core.version"
 updateVersion $CHE_PLUGINS_VERSION              "che.plugins.version"
 updateVersion $CHE_TUTORIALS_VERSION            "che.tutorials.version"
 updateVersion $CHE_VERSION                      "che.sdk.version"

# HOSTED
 updateVersion $SWAGGER_UI_VERSION               "codenvy.api-docs-ui.version"
 updateVersion $CLI_VERSION                      "codenvy.cli.version"
 updateVersion $CLDIDE_VERSION                   "codenvy.cloud-ide.version"
 updateVersion $DASHBOARD_VERSION                "codenvy.dashboard.version"
 updateVersion $FACTORY_VERSION                  "codenvy.factory.version"
 updateVersion $HOSTED_INFRASTRUCTURE_VERSION    "codenvy.hosted-infrastructure.version"
 updateVersion $ODYSSEY_VERSION                  "codenvy.odyssey.version"
 updateVersion $PLATFORM_API_CLIENT_JAVA_VERSION "codenvy.platform-api-client-java.version"
 updateVersion $PLUGIN_CONTRIBUTION_VERSION      "codenvy.plugin-contribution.version"
 updateVersion $PLUGIN_GAE_VERSION               "codenvy.plugin.gae.version"
 updateVersion $PLUGIN_HOSTED_VERSION            "codenvy.plugin.hosted.version"
 updateVersion $PLUGINS_VERSION                  "codenvy.plugins.version"

 mvn versions:set -DnewVersion="$CHE_DEPMGT_VERSION-SNAPSHOT"
  if $(git status | grep -q "working directory clean")   
  then
     echo "Parent version not changed"
  else
     echo "Change parent version to  $CHE_DEPMGT_VERSION"
     mvn scm:update  scm:checkin scm:update  -Dincludes=pom.xml  -Dmessage="RELEASE:Set version $CHE_DEPMGT_VERSION" -DpushChanges=true
  fi
  git pull
  mvn clean deploy
 cd ..
}

setNextVersionInDepMgtPom(){
 cd che-depmgt
 git pull

# CHE
 updateVersion $CHE_CORE_VERSION_NEXT                 "che.core.version"
 updateVersion $CHE_PLUGINS_VERSION_NEXT              "che.plugins.version"
 updateVersion $CHE_TUTORIALS_VERSION_NEXT            "che.tutorials.version"
 updateVersion $CHE_VERSION_NEXT                      "che.sdk.version"

# HOSTED
 updateVersion $SWAGGER_UI_VERSION_NEXT               "codenvy.api-docs-ui.version"
 updateVersion $CLI_VERSION_NEXT                      "codenvy.cli.version"
 updateVersion $CLDIDE_VERSION_NEXT                   "codenvy.cloud-ide.version"
 updateVersion $DASHBOARD_VERSION_NEXT                "codenvy.dashboard.version"
 updateVersion $FACTORY_VERSION_NEXT                  "codenvy.factory.version"
 updateVersion $HOSTED_INFRASTRUCTURE_VERSION_NEXT    "codenvy.hosted-infrastructure.version"
 updateVersion $ODYSSEY_VERSION_NEXT                  "codenvy.odyssey.version"
 updateVersion $PLATFORM_API_CLIENT_JAVA_VERSION_NEXT "codenvy.platform-api-client-java.version"
 updateVersion $PLUGIN_CONTRIBUTION_VERSION_NEXT      "codenvy.plugin-contribution.version"
 updateVersion $PLUGIN_GAE_VERSION_NEXT               "codenvy.plugin.gae.version"
 updateVersion $PLUGIN_HOSTED_VERSION_NEXT            "codenvy.plugin.hosted.version"
 updateVersion $PLUGINS_VERSION_NEXT                  "codenvy.plugins.version"

 mvn scm:update  scm:checkin scm:update  -Dincludes=pom.xml  -Dmessage="RELEASE:Set next versions" -DpushChanges=true
 git pull
 mvn clean deploy
 cd ..
}



updateDepMgtPomInprojectToLatestTag(){
	echo "Update parent in $1"
	cd $1
	git pull
	mvn versions:update-parent  versions:commit -DparentVersion=[$CHE_DEPMGT_VERSION]
	mvn scm:update  scm:checkin scm:update  -Dincludes=pom.xml  -Dmessage="RELEASE:Update maven parent to latest tag" -DpushChanges=true
	git pull
	#TODO do with maven
	cd ..
}

updateDepMgtPomInprojectToLatestSnapshot(){
	echo "Update parent in $1"
        cd $1
	git pull
	mvn versions:update-parent  versions:commit -DallowSnapshots=true -DparentVersion=[$CHE_DEPMGT_VERSION_NEXT]
	mvn scm:update  scm:checkin scm:update  -Dincludes=pom.xml  -Dmessage="RELEASE:Update che-depmgt to latest snapshot" -DpushChanges=true
	git pull
	#TODO do with maven
        cd ..
}

doRelease() {
    declare -a projects=( $( echo $@ ) )

    for i in ${projects[@]}
    do
    if [ ${i} != "che-depmgt" ]; then
      echo "===== Update parent pom in ${i}"
      updateDepMgtPomInprojectToLatestTag ${i}
    fi
        echo "===== Release ${i}"
        case ${i} in
            "che-depmgt" )
                 echo "===== Update versions in parent pom"
                 updateDepMgtPom
                 releaseProject ${i} $CHE_DEPMGT_VERSION $CHE_DEPMGT_VERSION_NEXT
                 echo "===== Set next versions in parent pom"
                 setNextVersionInDepMgtPom
                ;;
            "che-core" )
                 releaseProject ${i} $CHE_CORE_VERSION $CHE_CORE_VERSION_NEXT
                ;;
            "che-plugins" )
                 releaseProject ${i} $CHE_PLUGINS_VERSION $CHE_PLUGINS_VERSION_NEXT
                ;;
            "che-tutorials" )
                 releaseProject ${i} $CHE_TUTORIALS_VERSION $CHE_TUTORIALS_VERSION_NEXT
                ;;
            "che" )
                 releaseProject ${i} $CHE_VERSION $CHE_VERSION_NEXT
                ;;
            "plugins" )
                 releaseProject ${i} $PLUGINS_VERSION $PLUGINS_VERSION_NEXT
                ;;
            "plugin-hosted" )
                 releaseProject ${i} $PLUGIN_HOSTED_VERSION $PLUGIN_HOSTED_VERSION_NEXT
                ;;
            "plugin-contribution" )
                 releaseProject ${i} $PLUGIN_CONTRIBUTION_VERSION $PLUGIN_CONTRIBUTION_VERSION_NEXT
                ;;
            "plugin-gae" )
                 releaseProject ${i} $PLUGIN_GAE_VERSION $PLUGIN_GAE_VERSION_NEXT
                ;;
            "hosted-infrastructure" )
                 releaseProject ${i} $HOSTED_INFRASTRUCTURE_VERSION $HOSTED_INFRASTRUCTURE_VERSION_NEXT
                ;;
            "odyssey" )
                 releaseProject ${i} $ODYSSEY_VERSION $ODYSSEY_VERSION_NEXT
                ;;
            "factory" )
                 releaseProject ${i} $FACTORY_VERSION $FACTORY_VERSION_NEXT
                ;;
            "user-dashboard" )
                 releaseProject ${i} $DASHBOARD_VERSION $DASHBOARD_VERSION_NEXT
                ;;
            "cloud-ide" )
                 releaseProject ${i} $CLDIDE_VERSION $CLDIDE_VERSION_NEXT
                ;;
            "swagger-ui" )
                 releaseProject ${i} $SWAGGER_UI_VERSION $SWAGGER_UI_VERSION_NEXT
                ;;
            "platform-api-client-java" )
                 releaseProject ${i} $PLATFORM_API_CLIENT_JAVA_VERSION $PLATFORM_API_CLIENT_JAVA_VERSION_NEXT
                ;;
            "cli" )
                 releaseProject ${i} $CLI_VERSION $CLI_VERSION_NEXT
                ;;
       esac
    done

    # Set next dev che-depmgt version in all projects.
    for i in ${ALL_PROJECTS[@]}
    do
      if [ ${i} != "che-depmgt" ]; then
        echo "===== Update parent pom in ${i}"
        updateDepMgtPomInprojectToLatestSnapshot ${i}
      fi
    done
}

#################################
#      VERSIONS MANAGEMENT      #
#################################
# VERSIONS TO BE RELEASED
# CHE
CHE_DEPMGT_VERSION="1.20.0"
CHE_CORE_VERSION="3.9.0"
CHE_PLUGINS_VERSION="3.9.0"
CHE_TUTORIALS_VERSION="3.9.0"
CHE_VERSION="3.9.0"
# HOSTED
PLUGINS_VERSION="3.9.0"
PLUGIN_HOSTED_VERSION="0.14.0"
PLUGIN_CONTRIBUTION_VERSION="1.3.0"
PLUGIN_GAE_VERSION="1.5.0"
HOSTED_INFRASTRUCTURE_VERSION="0.16.0"
ODYSSEY_VERSION="0.30.0"
FACTORY_VERSION="0.24.0"
DASHBOARD_VERSION="0.15.0"
CLDIDE_VERSION="3.9.0"
SWAGGER_UI_VERSION="1.5.0"
PLATFORM_API_CLIENT_JAVA_VERSION="1.9.0"
CLI_VERSION="2.9.0"
#################################
# NEXT DEV VERSIONS
# CHE
CHE_DEPMGT_VERSION_NEXT="1.21.0-SNAPSHOT"
CHE_CORE_VERSION_NEXT="3.10.0-SNAPSHOT"
CHE_PLUGINS_VERSION_NEXT="3.10.0-SNAPSHOT"
CHE_TUTORIALS_VERSION_NEXT="3.10.0-SNAPSHOT"
CHE_VERSION_NEXT="3.10.0-SNAPSHOT"
# HOSTED
PLUGINS_VERSION_NEXT="3.10.0-SNAPSHOT"
PLUGIN_HOSTED_VERSION_NEXT="0.15.0-SNAPSHOT"
PLUGIN_CONTRIBUTION_VERSION_NEXT="1.4.0-SNAPSHOT"
PLUGIN_GAE_VERSION_NEXT="1.6.0-SNAPSHOT"
HOSTED_INFRASTRUCTURE_VERSION_NEXT="0.17.0-SNAPSHOT"
ODYSSEY_VERSION_NEXT="0.31.0-SNAPSHOT"
FACTORY_VERSION_NEXT="0.25.0-SNAPSHOT"
DASHBOARD_VERSION_NEXT="0.16.0-SNAPSHOT"
CLDIDE_VERSION_NEXT="3.10.0-SNAPSHOT"
SWAGGER_UI_VERSION_NEXT="1.6.0-SNAPSHOT"
PLATFORM_API_CLIENT_JAVA_VERSION_NEXT="1.10.0-SNAPSHOT"
CLI_VERSION_NEXT="2.10.0-SNAPSHOT"

#goes to the root folder
cd ../..

CHE_PROJECTS=( che-depmgt che-core che-plugins che-tutorials che )
HOSTED_PROJECTS=( plugins plugin-hosted plugin-contribution plugin-gae hosted-infrastructure odyssey factory user-dashboard swagger-ui cloud-ide )
CLI=( platform-api-client-java cli )
ALL_PROJECTS=( ${CHE_PROJECTS[@]} ${HOSTED_PROJECTS[@]} ${CLI[@]} )

#doRelease ${ALL_PROJECTS[@]}
