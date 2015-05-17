# AndroidWifiMusicSync
AndroidWifiMusicSync is a tool to synchronize music over wifi

# Prerequests
* On the Phone
..* SSHDroid or a similar application to connect via ssh to the phone. Here you can buy the pro version to use public key authentication to avoid entering every time the password.

* On the Workstation
--* A Music Player which can export a playlist as m3u

# How to synchronize

## 1. Test the connection
Connect your phone to your local network, VPN should also work, and connect to your phone through ssh.

## 2. Generate a playlist
Inside your music player on your workstation generate a playlist and export this to a m3u file.

## 3. Configuration
Edit config.sh

```bash
IP=192.168.4.52
USER=root
ROOT_FOLDER=/home/username/scripts/android
MNT_DIR=$ROOT_FOLDER/mount
PLAYLIST=/home/username/Downloads/test.m3u
LIB_FOLDER=/home/username/scripts/lib
TMP_FILE=/tmp/cleaned_playlist
```

`ROOT_FOLDER`: This is the folder where you stored the tool.

`MNT_DIR`: Where the phone should be mounted.

`PLAYLIST`: The file from the previous step.

`LIB_FOLDER`: The folder to the libraries from my other projects.

`TMP_FILE`: A file where the tool can store a cleaned version of the playlist. This file will be deleted after a successful run.

## 4. Synchronize
Run the script, now it's to lean back and make a break. After the files have copied to your phone it should take a little time that the music player on your phone has recognized that new files where copied.

## 5. Test
Now you should have all your favorite songs on you phone, it's time for a walk ;-)

# TODO
* [ ] Speed up the file check and cleanup on the phone. I planned to move the script to ruby and hold the needed informations in a Sqlite database to speed this up. In the current state it is a little bit horrible implement ;-) slow but it works.
* [ ] Find a way to force Apollo to rescan the music folder. Apollo is the music player i prefer on my phone. 
