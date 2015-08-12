set -e
HOST='https://codenvy-stg.com'

pingWar() {
	curl_result=$(curl -s ${HOST}/${1}/metrics/ping) 
	echo -e "ping to  ${HOST}/${1} \t\t- [${curl_result}]" 
        #awk '{ printf "%-20s %-40s\n", $1, $2}'
	

}


pingWar site
pingWar api
pingWar factory
pingWar ide


