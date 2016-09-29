# Sample NURAPI applications for iOS

## NURAPI Objective-C Demo
This is a demo application that shows how to use NURAPI in an Objective-C application.
To build you need the **NURAPIBluetooth** framework. Drag and drop it from Finder
into the `Frameworks` group and then add the framework to *Embedded binaries* section 
in the *General* tab of your application target.

The application builds both for the iOS simulator and real devices, but the simulator does
not have Bluetooth support. The application will start in the simulator, but the Bluetooth
subsystem will simply never be enabled.


## NURAPI Swift Demo
This is a minimal demo that shows how to use the NURAPI framework from a Swift application.
Add the framework to the project as per the Objective-C version. There is a *bridging header*
that makes the framework available to the Swift code.

Functionality wise the Swift version contains the same storyboard, but only the initial
view controller that starts the scanning and lists the found readers is implemented.

