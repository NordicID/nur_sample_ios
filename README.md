# Sample NURAPI applications for iOS

## NURAPI Objective-C Demo
This is a demo application that shows how to use NURAPI in an Objective-C application.
To build you need the **NURAPIBluetooth** framework. Drag and drop it from Finder
into the `Frameworks` group and then add the framework to *Embedded binaries* section 
in the *General* tab of your application target.

The application builds both for the iOS simulator and real devices, but the simulator does
not have Bluetooth support. The application will start in the simulator, but the Bluetooth
subsystem will simply never be enabled.
