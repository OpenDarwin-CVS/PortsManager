/*
 *  DPInstaller.m
 *  DarwinPorts Installer
 *
 * Copyright (c) 2003 Apple Computer, Inc.
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. Neither the name of Apple Computer, Inc. nor the names of its contributors
 *    may be used to endorse or promote products derived from this software
 *    without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 */

#import "DPInstaller.h"

NSString *DPGNUTarPath = @"/usr/bin/gnutar";
NSString *DPGNUMakePath = @"/usr/bin/gnumake";
NSString *DPDPortsSourceDir = @"dports_base";
NSString *DPDPortsBaseURL = @"http://www.opendarwin.org/downloads/dports_base-latest.tar.gz";
NSString *DPDPortsDportsURL = @"http://www.opendarwin.org/downloads/dports_dports-latest.tar.gz";

#import "DPInstallerProtocol.h"
#import "DPTaskExtensions.h"

#import <unistd.h>
#import <fcntl.h>
#import <sys/types.h>
#import <sys/stat.h>

@implementation DPInstaller

/** Init and clean-up **/

- (id) init
{

    if (self = [super init])
    {
        // configure our d.o. connection
        _connection = [NSConnection defaultConnection];
        [_connection setRootObject: self];
        [_connection setDelegate: self];
        if ([_connection registerName: DPInstallerMessagePort] == NO)
        {
            NSLog(@"Couldn't register server on this host.");
            exit(0);
        }

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector: @selector(connectionDidDie:)
                                                     name: NSConnectionDidDieNotification
                                                   object: _connection];
        // connect to dpappliation d.o. connection
        NSConnection *dpapplicationConnection = [NSConnection connectionWithRegisteredName: DPAppMessagePort host: nil];

        if (!dpapplicationConnection)
        {
            NSLog(@"Could not connect to dpapplication");
            exit(0);
        }
        
        _dpapplication = [[dpapplicationConnection rootProxy] retain];
        [(NSDistantObject *) _dpapplication setProtocolForProxy: @protocol(DPDelegateProtocol)];
        [_connection setRootObject: self];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector: @selector(connectionDidDie:)
                                                     name: NSConnectionDidDieNotification
                                                   object: dpapplicationConnection];
    }
    return self;
}

/** D.O. connection management **/

- (BOOL) connection: (NSConnection *)parentConnection shouldMakeNewConnection:(NSConnection *)newConnection
{
    /*
     * Ensure that connectionDidDie: is called if newConnection
     * dies without terminate being called
     */
    [[NSNotificationCenter defaultCenter] addObserver:self
                                                selector: @selector(connectionDidDie:)
                                                 name: NSConnectionDidDieNotification
                                               object: newConnection];
    return YES;
}

- (void) connectionDidDie: (id)connection
{
    exit(0);
}

- (oneway void) terminate
{
    [self performSelector: @selector(connectionDidDie:) withObject: self afterDelay: 0.0];
}

/** Communication **/

- (void) postUIEvent: (id) data withPriority: (NSString *) priority
{
    NSDictionary *message = [NSDictionary dictionaryWithObjectsAndKeys: data, DPEventDataKey, priority, DPEventPriorityKey, nil];
    [_dpapplication postUIEvent: message];
}


- (BOOL) executeTaskWithLaunchPath: (NSString *) launchPath
                         arguments: (NSArray *) arguments
                      startMessage: (NSString *) startMessage
                    failureMessage: (NSString *) failureMessage
                     workDirectory: (NSString *) workDirectory
                  percentComplete: (NSNumber *) percentComplete
{
    NSTask *task;

    if (startMessage)
        [self postUIEvent: startMessage withPriority: DPPriorityExecutionState];

    task = [NSTask taskWithLaunchPath: launchPath arguments: arguments];
    [task setStandardOutput: [NSPipe pipe]];
    [task setStandardError: [task standardOutput]];
    if (workDirectory)
        [task setCurrentDirectoryPath: workDirectory];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(taskDataAvailable:)
                                                 name: NSFileHandleReadCompletionNotification
                                               object: [[task standardOutput] fileHandleForReading]];
    [[[task standardOutput] fileHandleForReading] readInBackgroundAndNotify];

    [task launch];
    [task waitUntilExit];
    if ([task terminationStatus] != 0) {
        if (failureMessage)
            [self postUIEvent: failureMessage withPriority: DPPriorityError];
        return NO;
    }
    if (percentComplete)
        [self postUIEvent: percentComplete withPriority: DPPriorityExecutionPercent];
    return YES;
}

/** Install Operations **/

- (oneway void) executeInstallWithUserID: (int) uid withGroupID: (int) gid withUserDirectory: (NSString *) userDirectory
{
    double totalOps = 8; /* XXX hard coded */
    double currentOp = 0;

    NSLog(@"Running Installation");

    /* Only operate as root when neccesary */
    setegid(gid);
    seteuid(uid);

    /*
     * Create work directory
     */
    char *workDirCString = strdup("/tmp/org.opendarwin.darwinports.install.XXXXXXX");

    if ((workDirCString = mkdtemp(workDirCString)) == NULL) {
        /* Unable to create temporary working directory */
        [self postUIEvent: @"Unable to create temporary folder" withPriority: DPPriorityError];
        return;
    }

    _workDirectory = [NSString stringWithCString: workDirCString];
    _workSourceDirectory = [NSString stringWithFormat: @"%@/%@", _workDirectory, DPDPortsSourceDir];
    free(workDirCString);

    /*
     * Download software to work directory
     */
    [self postUIEvent: @"Downloading" withPriority: DPPriorityExecutionState];
    currentOp++;
    
    NSURL *dportsURL = [NSURL URLWithString: DPDPortsBaseURL];
    NSData *urlContents = [dportsURL resourceDataUsingCache: YES];
    NSString *outputFile;
    
    outputFile = [NSString stringWithFormat: @"%@/download.tar.gz", _workDirectory];
    
    if (![urlContents writeToFile: outputFile atomically: YES])
    {
        /*  Download failed */
        [self postUIEvent: @"Unable to download DarwinPorts distribution" withPriority: DPPriorityError];
        NSLog(@"Download failed");
        return;
    }
    [self postUIEvent: [NSNumber numberWithDouble: (currentOp / totalOps) * 100] withPriority: DPPriorityExecutionPercent];

    currentOp++;
    dportsURL = [NSURL URLWithString: DPDPortsDportsURL];
    urlContents = [dportsURL resourceDataUsingCache: YES];
    NSString *dportsOutputFile = [NSString stringWithFormat: @"%@/download-dports.tar.gz", _workDirectory];

    if (![urlContents writeToFile: dportsOutputFile atomically: YES])
    {
        /*  Download failed */
        [self postUIEvent: @"Unable to download DarwinPorts distribution" withPriority: DPPriorityError];
        NSLog(@"Download failed");
        return;
    }
    [self postUIEvent: [NSNumber numberWithDouble: (currentOp / totalOps) * 100] withPriority: DPPriorityExecutionPercent];

    /*
     * Extract using GNU tar
     */
    currentOp++;
    if (![self executeTaskWithLaunchPath: DPGNUTarPath
                               arguments: [NSArray arrayWithObjects: @"-xzvf", outputFile, nil]
                            startMessage: @"Extracting"
                          failureMessage: @"Unable to extract DarwinPorts distribution"
                           workDirectory: _workDirectory
                        percentComplete: [NSNumber numberWithDouble: (currentOp / totalOps) * 100]])
        return;

    /*
     * Run configure script
     */
    currentOp++;
    if (![self executeTaskWithLaunchPath: [NSString stringWithFormat: @"%@/%@", _workSourceDirectory, @"configure"]
                               arguments: [NSArray array]
                            startMessage: @"Configuring Sources"
                          failureMessage: @"Unable to configure DarwinPorts distribution"
                           workDirectory: _workSourceDirectory
                        percentComplete: [NSNumber numberWithDouble: (currentOp / totalOps) * 100]])
        return;

    /*
     * Start build using make
     */
    currentOp++;
    if (![self executeTaskWithLaunchPath: DPGNUMakePath
                               arguments: [NSArray array]
                            startMessage: @"Building"
                          failureMessage: @"Unable to build DarwinPorts distribution"
                           workDirectory: _workSourceDirectory
                        percentComplete: [NSNumber numberWithDouble: (currentOp / totalOps) * 100]])
        return;

    /*
     * Install software
     */
    
    setegid(getgid());
    seteuid(getuid());

    currentOp++;
    if (![self executeTaskWithLaunchPath: DPGNUMakePath
                               arguments: [NSArray arrayWithObjects: @"install", nil]
                            startMessage: @"Installing"
                          failureMessage: @"Unable to install DarwinPorts distribution"
                           workDirectory: _workSourceDirectory
                        percentComplete: [NSNumber numberWithDouble: (currentOp / totalOps) * 100]])
        return;

    /*
     * Configure Sources.conf
     */

    [self postUIEvent: @"Configuring Installation" withPriority: DPPriorityExecutionState];
    currentOp++;
    
    NSString *sourceURL = [NSString stringWithFormat: @"file://%@/dports\n", userDirectory];
    int configfd = open("/etc/ports/sources.conf", (O_WRONLY | O_APPEND), NULL);
    NSFileHandle *configFile = [[NSFileHandle alloc] initWithFileDescriptor: configfd];
    
    [configFile writeData:[sourceURL dataUsingEncoding:NSASCIIStringEncoding]];
    [configFile closeFile];
    [configFile release];
    
    [self postUIEvent: [NSNumber numberWithDouble: (currentOp / totalOps) * 100] withPriority: DPPriorityExecutionPercent];

    setegid(gid);
    seteuid(uid);

    /*
     * Install portfiles
     */

    [self postUIEvent: @"Installing Darwin Portfiles" withPriority: DPPriorityExecutionState];
    currentOp++;
    
    struct stat sb;
    if (stat([userDirectory fileSystemRepresentation], &sb) == 0) {
        if (!(sb.st_mode & S_IFDIR))
        {
            [self postUIEvent: [NSString stringWithFormat: @"Unable to install portfiles, %@ is not a folder", userDirectory] withPriority: DPPriorityError];
            return;
        }
    } else {
        if(mkdir([userDirectory fileSystemRepresentation], S_IRWXU|S_IRGRP|S_IXGRP|S_IROTH|S_IXOTH) != 0) {
            [self postUIEvent: [NSString stringWithFormat: @"Unable to create folder %@", userDirectory] withPriority: DPPriorityError];
            return;
        }
    }

    if (![self executeTaskWithLaunchPath: DPGNUTarPath
                               arguments: [NSArray arrayWithObjects: @"-xzvf", dportsOutputFile, nil]
                            startMessage: nil
                          failureMessage: @"Unable to install Darwin Portfiles"
                           workDirectory: userDirectory
                        percentComplete: [NSNumber numberWithDouble: (currentOp / totalOps) * 100]])
        return;

    [self postUIEvent: @"Completed" withPriority: DPPriorityDidFinish];
}

- (void) taskDataAvailable: (NSNotification *) aNotification {
    NSData *data = [[aNotification userInfo] objectForKey:NSFileHandleNotificationDataItem];
    if ([data length])
    {
        [self postUIEvent: [[[NSString alloc] initWithData: data
                                                  encoding: NSUTF8StringEncoding] autorelease]
             withPriority: DPPriorityInfo];

        [[aNotification object] readInBackgroundAndNotify];
    } else {
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:NSFileHandleReadCompletionNotification
                                                      object: [aNotification object]];
    }
}

@end