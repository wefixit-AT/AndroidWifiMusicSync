# AndroidWifiMusicSync
AndroidWifiMusicSync is a tool to synchronize music over wifi.

# Prerequests
1. On the Workstation
  * Ruby
  * A Music Player which can export a playlist as m3u.
2. Sync to a phone
  * SSHDroid or a similar application to connect via ssh to the phone. Here you can buy the pro version to use public key authentication to avoid entering every time the password.
3. Sync to a usb device
  * No special software needed, the device must be mounted.

# How to synchronize

## 1. Test the connection

* Phone: Connect your phone to your local network, VPN should also work, and connect to your phone through ssh.

* USB-Device: Mount the device.

## 2. Generate a playlist
Inside your music player on your workstation generate a playlist and export this to a m3u file.

## 3. Configuration
Create a config for every device. Take a look at syncPhoneSample.rb and syncUsbSample.rb.

## 4. Synchronize
Run the tool.

```
ruby syncPhone.rb
```

## 5. Test
Now you should have all your favorite songs on you phone, it's time for a walk ;-)
