/*
 * DPInstallWindow.m
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

#import <sys/types.h>
#import <unistd.h>

static NSString *DPWelcomeTabViewIdentifier = @"welcome";
static NSString *DPInstallTabViewIdentifier = @"install";

@implementation DPInstallWindow

/* Returns the single shared window */
+ (DPInstallWindow *) sharedWindow {
    static DPInstallWindow *sharedWindow = nil;
    if (!sharedWindow)
    {
        sharedWindow = [[self alloc] init];
    }
    return sharedWindow;
}


- (id) init {
    if (self = [self initWithWindowNibName: @"InstallerWindow"])
    {
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(installerUIEventNotification:)
                                                     name: DPInstallerUIEventNotification
                                                   object: nil];
    }
    return self;
}

- (void) tabView: (NSTabView *) tabView willSelectTabViewItem: (NSTabViewItem *) tabViewItem
{
    if ([DPInstallTabViewIdentifier isEqualToString: [tabViewItem identifier]]) {
        [_continueButton setEnabled: YES];
        [_continueButton setTitle: @"Install"];
        [_continueButton setTarget: self];
        [_continueButton setAction: NSSelectorFromString(@"install:")];
        [_backButton setEnabled: YES];
    } else if ([DPWelcomeTabViewIdentifier isEqualToString: [tabViewItem identifier]]) {
        [_continueButton setEnabled: YES];
        [_backButton setEnabled: NO];
        [_continueButton setTitle: @"Continue"];
        [_continueButton setTarget: tabView];
        [_continueButton setAction: NSSelectorFromString(@"selectNextTabViewItem:")];
    }
}

- (IBAction) install: (id) sender {
    NSArray *paths;
    NSLog(@"Running Installation");
    [_progressIndicator startAnimation: self];

    [_continueButton setEnabled: NO];
    [_backButton setEnabled: NO];
    paths = NSSearchPathForDirectoriesInDomains (NSLibraryDirectory, NSUserDomainMask, YES);
    if ([paths count] == 0) {
        NSBeginAlertSheet(@"Installation Failed", nil, nil, nil, [self window], nil, nil, nil, nil, @"Could not locate \"~/Library/Application Support\" directory");
        return;
    }
    [[(DPApp *) [NSApp delegate] installer] executeInstallWithUserID: getuid()
                                                         withGroupID: getgid()
                                                   withUserDirectory: [NSString stringWithFormat: @"%@/Application Support/DarwinPorts/", [paths objectAtIndex: 0]]];
}


- (void) installerUIEventNotification: (NSNotification *) aNotification
{
    NSDictionary *entry = [aNotification userInfo];
    NSString *priority = [entry objectForKey: DPEventPriorityKey];

    if ([priority isEqualToString: DPPriorityError]) {
        NSString *data = [entry objectForKey: DPEventDataKey];
        NSBeginAlertSheet(@"Installation Failed", nil, nil, nil, [self window], nil, nil, nil, nil, data);
        [_progressIndicator stopAnimation: self];
        return;
    } else if ([priority isEqualToString: DPPriorityExecutionState]) {
        NSString *data = [entry objectForKey: DPEventDataKey];
        [_textField setStringValue: [NSString stringWithFormat: @"%@...", data]];
    } else if ([priority isEqualToString: DPPriorityExecutionPercent]) {
        NSNumber *data = [entry objectForKey: DPEventDataKey];
        [_progressIndicator setDoubleValue: [data doubleValue]];
    } else if ([priority isEqualToString: DPPriorityDidFinish]) {
        [_continueButton setTitle: @"Quit"];
        [_continueButton setEnabled: YES];
        [_continueButton setTarget: NSApp];
        [_continueButton setAction: NSSelectorFromString(@"terminate:")];
        [_textField setStringValue: @"Installed"];
        [_progressIndicator stopAnimation: self];
    }
}


@end
