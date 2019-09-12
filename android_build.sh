RELATIVEPATH="ixigo_android/ixigo-app-android/"
SLACK_TOKEN="xoxb-ABCDEFGHIJKNMNOPQRST"
SLACK_CHANNEL="XXYYZZZ" #android_builds channel
TEMP_OUTPUT_DIRECTORY_PATH="../ixigo_android_build_output"

cd $RELATIVEPATH

postFileToSlack(){
    filePath=$1
    fileName="${filepath:2}"

    echo sending file $fileName to slack Channel $SLACK_CHANNEL

    curl https://slack.com/api/files.upload \
    -F token="${SLACK_TOKEN}" \
    -F channels="${SLACK_CHANNEL}" \
    -F title="${fileName}" \
    -F filename="${fileName}" \
    -F file=@${filePath}
}

postBranchMesageToSlack() {
    branch=$1
    user=$2
    ip="$(echo $SSH_CLIENT | awk '{ print $1}')"
    if [ "$user" != "" ]
    then
    #User is present
    data="text=Build from branch \`$branch\` by \`$user\` from IP \`$ip\`"
    else
    #User is not present
    data="text=Build from branch \`$branch\` from IP \`$ip\`"
    fi

    curl -X POST \
    https://slack.com/api/chat.postMessage \
    -H 'Content-Type: application/x-www-form-urlencoded' \
    -H 'Host: slack.com' \
    -d "token=$SLACK_TOKEN" \
    -d "channel=$SLACK_CHANNEL" \
    --data-urlencode "$data"
}

postCustomMesageToSlack() {
    curl -X POST \
    https://slack.com/api/chat.postMessage \
    -H 'Content-Type: application/x-www-form-urlencoded' \
    -H 'Host: slack.com' \
    -d "token=$SLACK_TOKEN" \
    -d "channel=$SLACK_CHANNEL" \
    -d "link_names=true" \
    --data-urlencode "text=$1"
}

isGradleDaemonOccupied(){
        #Checking Gradle Status
        gradleStatus=$(./gradlew --status)
        retval=0
        if [[ $gradleStatus == *"BUSY"* ]]
        then
                retval=1
        else
                retval=0
        fi
        #echo "Retval $retval"
        return $retval
}


isGradleDaemonOccupied
retVal=$?
if [ "$retval" == "1" ]
then
        echo "Another user is using the gradleDaemon, do you want to automatically build once they are done (Y/N)?"
        read varname
        if [ "$varname" == "Y" -o "$varname" == "y" ]
        then
                while [ "$retval" == "1" ]
                do
                		echo "Going to sleep for 30 seconds. Will continue checking again after that."
                        sleep 30
                        isGradleDaemonOccupied
                        retVal=$?
                        echo "Still occupied..."
                done
        else
                exit 0
        fi
fi

if [ "$1" == "tr" ]
then
        module="ixigo-train-app"
        buildCmd=":ixigo-train-app:assembleRelease"
        apkPath="ixigo-train-app/build/outputs/apk/release"
elif [ "$1" == "td" ]
then
        module="ixigo-train-app"
        buildCmd=":ixigo-train-app:assembleDebug"
        apkPath="ixigo-train-app/build/outputs/apk/debug"
elif [ "$1" == "fd" ]
then
        module="ixigo-app"
        buildCmd=":ixigo-app:assembleDebug"
        apkPath="ixigo-app/build/outputs/apk/debug"
elif [ "$1" == "fr" ]
then
        module="ixigo-app"
        buildCmd=":ixigo-app:assembleRelease"
        apkPath="ixigo-app/build/outputs/apk/release"
else
        echo "Incorrent first argument please use among these: tr(Train Release), td(Train Debug), fr(Flight Release), fd(Flight Debug)"
        exit 1
fi

if [ "$2" == "" ]
then
	branch="dev"
else
    branch=$2
fi

echo "Checking out branch $branch"
git stash
git fetch
git checkout $branch
git pull

echo "executing command $buildCmd on $branch"
./gradlew ":$module:clean"
./gradlew $buildCmd

if [ -d $apkPath ]
then
        echo "Apks generated Successfully"
else
        echo "Failed to generate Apks"
        exit 1
fi
#Apks generated successfully


#Extract optional parameters from the user
user=""
message=""
while [ "$1" != "" ]
do
case $1 in
-m | --message | -M)    shift
message=$1
;;
-u | --user | -U)    shift
user=$1
;;
esac
shift
done



if [ "$3" == "-l" ]
then
        echo "Local mode: Not posting Apks to Slack channel"
else
        #Extract and post the generated apks
        currentDirectory=$(pwd)
        rm -r "$TEMP_OUTPUT_DIRECTORY_PATH"/*
        #echo "about to execute rm -rf ${TEMP_OUTPUT_DIRECTORY_PATH}/*"
        cp -v -R "$apkPath/" $TEMP_OUTPUT_DIRECTORY_PATH
        cd $TEMP_OUTPUT_DIRECTORY_PATH
        postBranchMesageToSlack $branch $user
        for file in ./*.apk
        do
                #echo "$file"
                postFileToSlack $file
        done
fi


#Sending user custom message (if any) to slack
if [ "$message" != "" ]
then
postCustomMesageToSlack "$message"
fi

echo "Done"
