
PortsManager.app 
README
2/21/03

PortsManager.app is a graphical front-end for the darwinports system written in COCOA.  It is derived from the earlier DarwinPorts.app sources but the architecture, GUI and source have changed significantly.   

You need to have installed and configured the command-line ports system before PortsManager.app will run.

PortsManager.app is not complete at this time but it should be at least as functional as DarwinPorts.app was and provides a better architectural basis for future development work.  I am checking it in now so other people can have a look at it and hopefully help finish it up.   

So what's different/better about PortsManager compared to DarwinPorts.app?

The GUI for browsing the ports collection has been completely overhauled.   You can now browse by category.   You can now have multiple independent browser windows open.  Many glitches with the outlineview presentation of the port tree have been fixed.  A detailed rich-text inspector view has been added.  The filter-widget now works more like Mail.apps and there are a number of other minor UI tweaks.   

The console log has been moved to it's own window.  There is now a pop-up which dynamically controls the level of detail presented.   

Architecturally, the app has been split into a GUI front-end (PortsManager.app) and a faceless helper process (dpagent).   Communication between the two happens using Distributed Objects.   The intent is that the helper process can run suid root if desired and avoid the security pitfalls of having an appkit app running as root.   This split architecture also allows the GUI app to remain single-threaded and still responsive and we only have to worry about multi-threading in the helper agent.   

The wrappers for the TCL interpreter have also been simplified to reduce the need to keep converting back and forth between TCL and obj-c data types.

All operations on ports are currently multi-threaded but serialized (e.g. you can start an install of a port, keep browsing the ports collection, request another port to be installed but the second port won't start installing until the first port finishes installing.)   This was done to simplify implementation and prevent conflicts from trying to install/uninstall multiple ports simultaneously which both might share a dependency.

For more info there are comments in the .m source files explaining various design decisions and pointing out places where the current implementation is incomplete or needs improvement.

