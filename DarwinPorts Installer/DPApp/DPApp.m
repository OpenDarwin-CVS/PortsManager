/*
 * DPApp.m
 * DarwinPorts Installer
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

#import "DPApp.h"
#import "DPInstallWindow.h"
#import "DPConsole.h"

#import "DPInstallerProtocol.h"

NSString *DPInstallerUIEventNotification = @"DPInstallerUIEventNotification";

#import <unistd.h>
#import <Security/Authorization.h>

@implementation DPApp


/*
 * Application delegate. Manages communication with the dpinstaller process
 * via DO.
 */

- (BOOL) applicationOpenUntitledFile: (NSApplication *) sender
{
    [self newWindow: self];
    return YES;
}


- (void) newWindow: (id)sender
{
    [[DPInstallWindow sharedWindow] showWindow: self];
}


- (IBAction) showConsole: (id)sender
{
    [[DPConsole sharedConsole] showWindow: self];
}


- (void) applicationWillTerminate: (NSNotification *) notification
{
    [_installer terminate];
}


- (NSApplicationTerminateReply) applicationShouldTerminate: (NSApplication *) app
{
    NSWindowController *windowController = [DPInstallWindow sharedWindow];
    /* Check only DPInstallWindow */
    if ([windowController windowShouldClose: [windowController window]])
        return NSTerminateNow;
    else
        return NSTerminateCancel;
}


- (void) applicationDidFinishLaunching: (NSNotification *) notification
{
    _connection = [NSConnection defaultConnection];
    [_connection setRootObject: self];
    [_connection enableMultipleThreads];
    if ([_connection registerName: DPAppMessagePort] == NO)
    {
        NSLog(@"Couldn't register DPAppMessagePort connection on this host.");
        exit(0);
    }
}


- (id <DPInstallerProtocol>) installer
{
    if (_installerBusy)
        return nil;

    _installerBusy = YES;
    
    if (!_installer)
    {
        
        AuthorizationRef auth;
        NSString *installerPath = [[NSBundle mainBundle] pathForResource: @"dpinstaller" ofType: @""];
        int i;
        
        OSStatus err = AuthorizationCreate(NULL, NULL, kAuthorizationFlagInteractionAllowed, &auth);
        if (err) {
            NSRunAlertPanel(@"DarwinPorts Installer", @"Authorization Failed", nil, nil, nil);
            _installerBusy = NO;
            return nil;
        }
        err = AuthorizationExecuteWithPrivileges(auth, [installerPath fileSystemRepresentation], 0, NULL, NULL);
        if (err != errAuthorizationSuccess) {
            _installerBusy = NO;
            return nil;
        }
        AuthorizationFree(auth, 0);
        
        for (i = 0; i<10; i++)
        {
            _connection = [[NSConnection connectionWithRegisteredName: DPInstallerMessagePort host: nil] retain];
            if (_connection)
            {
                break;
            }
            [[NSRunLoop currentRunLoop] runMode: NSDefaultRunLoopMode beforeDate: [NSDate dateWithTimeIntervalSinceNow: 1]];
        }

        if (!_connection)
        {
            NSRunAlertPanel(@"DarwinPorts Installer", @"Could not connect to dpinstaller!", nil, nil, nil);
            exit(0);
        }

        _installer = [[_connection rootProxy] retain];
        [(NSDistantObject *)_installer setProtocolForProxy: @protocol(DPInstallerProtocol)];
        [_connection setRootObject: self];
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(connectionDidDie:)
                                                     name: NSConnectionDidDieNotification
                                                   object: _connection];

    }
    _installerBusy = NO;
    return _installer;
}


- (void) connectionDidDie: (id) server
{
    NSRunAlertPanel(@"DarwinPorts Installer", @"Connection to dpinstaller died!", nil, nil, nil);
    _installer = nil;
    // resetting _installer to nil will cause a new instance of the _installer to
    // be spawned by [PMApp installer] next time someone tries to access it
}


- (NSArray *) messages
{
    return _messages;
}


- (oneway void) postUIEvent: (in bycopy NSDictionary *) message;
{
    if (!_messages)
    {
        _messages = [[NSMutableArray alloc] init];
    }
    [_messages addObject: message];
    [[NSNotificationCenter defaultCenter] postNotificationName: DPInstallerUIEventNotification
                                                        object: self
                                                      userInfo: message];
}


@end