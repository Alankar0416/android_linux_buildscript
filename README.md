Bash script to build and share apks over to Slack 
====================

This is a bash script to delegate building Android APKs and sharing them with stakeholders to a machine because you have better things to do in life !!

## Initial setup

1. Take up any discarded system(Linux or Mac, come on, do you still use Windows ?) and connect it to your network with a **static IP** assigned to it. Get your SysAd on it if you feel lazy.
2. Install your project along with git to any place on that system.
3. **[Optional]** Create a new user on that system and give necessary permissions to execute files on your project. You can use any existing user also.
4. Add the script anyplace in the system(I suggest you keep the script in the root directory to easily access when you ssh into the system)
5. Change the `RELATIVEPATH` variable at the first line of the script according to where your Android project is wrt the script.
```bash
RELATIVEPATH="ixigo_android/ixigo-app-android/"
```

6. Change the build type conditions and variables to suit your need. `ar` - Release or `ad` - Debug if you have a single app project. `module` is the app in a multimodule project remove it if you have a single app. `buildcmd` is the argument following `./gradlew`, change it as per your project, flavors, and requirement. Lastly, `apkpath` is the path from which to extract generated apks.

```bash
if [ "$1" == "tr" ]
then
        module="ixigo-train-app"
        buildCmd=":ixigo-train-app:assembleRelease"
        apkPath="ixigo-train-app/build/outputs/apk/release"
elif [ "$1" == "td" ]
then
```

## Usage:

1. Login to build server `ssh username@IP_ADDRESS_OF_BUILD_SERVER`
2. input password `password: zxcv`
3. Sample command to build 

```ssh
./build_android.sh *apk_type* *branch* -m "@CTO @CEO Please check out this build" -u "Alankar"
```

**branch** - Branch you want to build. Ex *release_ixigo_app_4.0.8* or *origin/release_ixigo_app_4.0.8*.

**apk_type** = tr - Train Release, td - Train Debug, fr - Flight Release, fd - Flight Debug. Use as per your own project here.

[Optional] *`-l` as the third argument to disable posting to slack.*

[Optional] *`-M` or `-m` or `--message` Custom message to be sent after the apks are published.*

[Optional] *`-u` or `-U` or `--user` User triggering the build.* Good practice to know who sent the post-build message. Feel free to enforce this if Authors are skipping it 😉

4. In case the build system is busy you get a message like: `Another user is using the gradleDaemon, do you want to automatically build once they are done (Y/N)?`. Enter `y` or `Y` and your build will be queued once the build system is free (please do not close the terminal ).

5. Upon completion builds will be immediately posted over to this channel with File name as apk name (if `-l` is not provided).


## Contributing
Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

## PS

I am not an expert in bash. I just learned bash in order to write this script so there may be optimizations which I have missed. If that is the case feel free to add a comment or send an MR. 🙏 

I think it's best to be used in a small to medium scale enterprise where while developing apps there are many things that developers need to take care of because they are a part of the Android Team. 💻 Sharing timely builds to an internal QA team. Sharing build with Project managers and Design team for review. Sharing builds with your CEOs and CTOs (they better not have bugs). Sharing with third parties…. and the list goes on. 

If you think this helped you in any way do let me know. Optimizing and adding more features to this in a never-ending process.
