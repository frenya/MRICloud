# MRICloud
Demonstration of using MagicalRecord with iCloud

MagicalRecord is a wonderful library simplifying the use of Core Data. 
I was however struggling with setting it up properly with iCloud.
Perhaps this demo helps someone avoid that :)

Please note
- the project was created using XCode 6.1
- the project is using iCloud Drive (available in iOS 8 and OSX Yosemite)

## Setup

Clone the repository including submodules and open `MRICloud.xcodeproj`.

    git clone https://github.com/frenya/MRICloud.git MRICloud
    cd MRICloud
    git submodule update --init --recursive

**Don't forget to update your Bundle ID and code signing identity!**

The easiest way to do that seems to be going to Project's Capabilites setting. Turn iCloud off and on again. 
Make sure both the **iCloud Documents** and the **iCloud.$(CFBundleIdentifier)** options are checked.
You will be prompted to select your signing identity during the process.

## Acknowledgements

I drew a lot of inspiration from the following
- https://github.com/versluis/Core-Data-iCloud
- [Handling Core Data Store Change Notifications] (http://ossh.com.au/design-and-technology/software-development/sample-library-style-ios-core-data-app-with-icloud-integration/sample-apps-explanations/handling-core-data-store-change-notifications/)

## Developer notes (observations)
- from time to time, the iCloud daemon seems to have an issue. 
  If you’re experiencing strange errors (e.g. failed to receive 
  initial sync notification call back in 90 seconds), try restarting 
  the device before going into desperate mode
- the iCloud sync occurs approx. every 10 second - i.e. 
  it can take up to around 20 second for any change to propagate
- the Simulator pushes changes to iCloud but does not periodically pull
  them unless you manually trigger the iCloud sync (Shift+Cmd+I)
- during the first init, when the persistant store changes, 
  your NSFetchedResultsControllers won't pick it up and your UI 
  will not be updated automatically. You have to observe the store
  change notification, drop the FRC and reload (see MasterViewController).
