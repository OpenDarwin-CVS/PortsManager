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

#import "DPDistributedNotifications.h"

#import <sys/types.h>
#import <unistd.h>

static NSString *DPWelcomeTabViewIdentifier = @"welcome";
static NSString *DPInstallTabViewIdentifier = @"install";
enum {
    DPWindowWelcomeState,
    DPWindowInstallState,
    DPWindowInstallBusyState,
    DPWindowCompleteState,
    DPWindowNoState
};

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
    windowState = DPWindowNoState;
    return self;
}


- (BOOL) windowShouldClose: (id) sender
{
    if (!_installBusy && windowState == DPWindowCompleteState)
        return YES;

    if (!_installBusy && windowState != DPWindowCompleteState) {
        [[NSDistributedNotificationCenter defaultCenter] postNotificationName: DPInstallerCanceledNotification
                                                                       object: nil
                                                                     userInfo: nil
                                                           deliverImmediately: YES];
        return YES;
    }
    
    if (NSRunAlertPanel(@"DarwinPorts Installer", @"Are you sure you want to quit? Stopping the Installer now may leave your system in an unstable state.", @"Continue", @"Quit", nil) == NSAlertDefaultReturn)
        return NO;
    else {
        [[NSDistributedNotificationCenter defaultCenter] postNotificationName: DPInstallerCanceledNotification
                                                                       object: nil
                                                                     userInfo: nil
                                                           deliverImmediately: YES]; 
        return YES;
    }
}

/* configure window UI elements */

- (void) setWindowState: (int) state
{
    windowState = state;
    switch (state) {
        case DPWindowWelcomeState:
            _installBusy = NO;
            [_continueButton setEnabled: YES];
            [_backButton setEnabled: NO];
            [_continueButton setTitle: @"Continue"];
            [_continueButton setTarget: _tabView];
            [_continueButton setAction: NSSelectorFromString(@"selectNextTabViewItem:")];
            break;
            
        case DPWindowInstallState:
            _installBusy = NO;
            [_continueButton setEnabled: YES];
            [_continueButton setTitle: @"Install"];
            [_continueButton setTarget: self];
            [_continueButton setAction: NSSelectorFromString(@"install:")];

            [_progressIndicator stopAnimation: self];
            [_progressIndicator setDisplayedWhenStopped: NO];
            [_progressIndicator setDoubleValue: 0];
            
            [_textField setStringValue: @""];
            
            [_backButton setEnabled: YES];
            break;

        case DPWindowInstallBusyState:
            _installBusy = YES;
            [_progressIndicator startAnimation: self];

            [_continueButton setEnabled: NO];
            [_backButton setEnabled: NO];
            break;
            
        case DPWindowCompleteState:
            _installBusy = NO;
            [_continueButton setTitle: @"Quit"];
            [_continueButton setEnabled: YES];
            [_continueButton setTarget: NSApp];
            [_continueButton setAction: NSSelectorFromString(@"terminate:")];

            [_textField setStringValue: @"The software was successfully installed"];

            /* display progress bar when installation is finished */
            [_progressIndicator setDisplayedWhenStopped: YES];
            [_progressIndicator stopAnimation: self];
            break;
    }
}

/* tabView delegate */
- (void) tabView: (NSTabView *) tabView willSelectTabViewItem: (NSTabViewItem *) tabViewItem
{
    if ([DPInstallTabViewIdentifier isEqualToString: [tabViewItem identifier]]) {
        [self setWindowState: DPWindowInstallState];
        
    } else if ([DPWelcomeTabViewIdentifier isEqualToString: [tabViewItem identifier]]) {
        [self setWindowState: DPWindowWelcomeState];
    
    }
}


- (void) tabView: (NSTabView *) tabView didSelectTabViewItem: (NSTabViewItem *) tabViewItem
{
    /* keep image on top */
    [_imageView display];
}


/* install action */

- (IBAction) install: (id) sender {
    id <DPInstallerProtocol> installer = [(DPApp *) [NSApp delegate] installer];

    if (!installer)
        return;

    NSLog(@"Running Installation");
    [self setWindowState: DPWindowInstallBusyState];

    /*
     * XXX hard code installation directory to /usr/dports/
     */
    [installer executeInstallWithUserID: getuid()
                            withGroupID: getgid()
                      withUserDirectory: @"/usr/dports"];
}


- (void) installerUIEventNotification: (NSNotification *) aNotification
{
    NSDictionary *entry = [aNotification userInfo];
    NSString *priority = [entry objectForKey: DPEventPriorityKey];

    if ([priority isEqualToString: DPPriorityError]) {
        NSString *data = [entry objectForKey: DPEventDataKey];
        
        NSRunAlertPanel(@"Installation Failed", data, nil, nil, nil);
        [[NSDistributedNotificationCenter defaultCenter] postNotificationName: DPInstallerFailedNotification
                                                                       object: nil
                                                                     userInfo: nil
                                                           deliverImmediately: YES];
        [self setWindowState: DPWindowInstallState];
        return;
        
    } else if ([priority isEqualToString: DPPriorityExecutionState]) {
        NSString *data = [entry objectForKey: DPEventDataKey];
        [_textField setStringValue: [NSString stringWithFormat: @"%@...", data]];
        
    } else if ([priority isEqualToString: DPPriorityExecutionPercent]) {
        NSNumber *data = [entry objectForKey: DPEventDataKey];
        [_progressIndicator setDoubleValue: [data doubleValue]];
        
    } else if ([priority isEqualToString: DPPriorityDidFinish]) {
        [self setWindowState: DPWindowCompleteState];
        [[NSDistributedNotificationCenter defaultCenter] postNotificationName: DPInstallerCompleteNotification
                                                                       object: nil
                                                                     userInfo: nil
                                                           deliverImmediately: YES];
    }
}


@end