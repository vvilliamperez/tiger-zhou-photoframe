# tiger-zhou-photoframe
Notes and Utilities for Tiger Zhou 10.1 in Digital Photoframe


# ADB Access on Shenzen Fujia Digital Photo Frame

## Getting ADB Access

1. Connect to WiFi using the custom user interface.  
2. Use the following command to connect via ADB:
   ```sh
   adb connect <IP_ADDRESS>
   ```
   
### Finding the IP Address (If Not Visible in Your Network)
If you can't see the IP address on your network, you can grab it in the photoframe UI:

1. Go to **Settings > About > Build Number**  
2. Tap **Build Number** multiple times until the custom UI throws you into the normal Android Settings app.
3. Navigate to **WiFi > … (Menu) > Advanced**  
4. Note the IP address listed.

**Note:** I haven't found a way to enable ADB over USB.

---

## Background

For Christmas, I received a digital photo frame from a family member. After some time, I tried setting it up, but the companion app had issues with iOS album permissions. The app required access to my **entire photo library**, rather than allowing selective sharing.  

After some frustration, I realized the device runs **Android** and decided to gain ADB access.

I couldn't find the exact model on Amazon, but it appears to manufactured by a **Tiger-Zhou UG** while the app from the [Google Play listing for vPhoto](https://play.google.com/store/apps/details?id=com.waophoto.smartphoto&hl=en_US&pli=1), is made by **Shenzhen Fujia Technology Co., Ltd.**

---

## Next Steps

I'm planning to add an **SMB or other file server** to drop photos onto the frame over the network, instead of using their app or an SD card.

