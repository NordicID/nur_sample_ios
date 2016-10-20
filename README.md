# Sample NURAPI applications for iOS

## NurAPI Bluetooth framework

The framework provides an interface that works as a bridge between the NurAPI and the iOS Bluetooth stack.
It is mainly responsible for providing a mechanism for NurAPI to communicate with the ``CoreBluetooth`` framework 
in iOS as well as relaying events from NurAPI to the application. It also provides a simpler API to scan for 
and connect to RFID devices. 

The ``NurAPIBluetooth`` framework is accessible from both Objective-C and Swift.


## Using the framework from Objective-C

Drag the framework into an application. Add the framework to *Embedded binaries* section in the *General* tab of your app target.
Now you can import the ``<NurAPIBluetooth/Bluetooth.h>`` header:

```objectivec
#import <NurAPIBluetooth/Bluetooth.h>`
```

All functionality is accessed through a singleton method, for example:

```objectivec
[[Bluetooth sharedinstance] startScanning];
```

All results from the ``Bluetooth`` class are delivered to registered **delegates**. An application that uses the class
should have some component implement the ``BluetoothDelegate`` and register it as a delegate, for example:


```objectivec
// a class that implements the BluetoothDelegate protocol
@interface SelectReaderViewController : UIViewController <BluetoothDelegate>
...
@end

@implementation SelectReaderViewController
...

- (void)viewDidLoad {
    [super viewDidLoad];

    // register as a delegate
    [[Bluetooth sharedInstance] registerDelegate:self];
    ...
}

@end

```

See the ``BluetoothDelegate`` for all the methods that can be implemented.

When a connection to a reader is formed all communication with the device is performed through the low level
NurAPI functions. These require a handle which can be accessed from the ``nurapiHandle``property like this:

```objectivec
// start an inventory stream
int error = NurApiStartInventoryStream( [Bluetooth sharedInstance].nurapiHandle, rounds, q, session );
if ( error != NUR_NO_ERROR ) {
    // failed to start stream
}
```

Please refer to that header for more detailed instructions on how to access the available functionality. 


## Using the framework from Swift

Drag the framework into an application. 
Add the framework to *Embedded binaries* section in the *General* tab of your app target.
In order to use the framework in Swift code the project needs a *bridging header*. The
contents of the bridging header is simply:

```objectivec
#import <NurAPIBluetooth/Bluetooth.h>`
```

Now the framework can be imported in Swift with:

```swift
import NurAPIBluetooth
```
 
Once the bridging header is in place the framework can be used just as in the Objective-C


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


## NURApiBluetooth framework
The **NURAPIBluetooth** framework contains shared libraries for both device and simulator architectures. This
allows the same framework to be used for both simulator testing as well as deploying on devices. When an application
is submitted to the App Store the simulator libraries can not be included and must be stripped away from the
build.

See:

http://ikennd.ac/blog/2015/02/stripping-unwanted-architectures-from-dynamic-libraries-in-xcode/
