//
//  PMConsole.m
//  PortsManager
//
/*
 Copyright (c) 2003 Apple Computer, Inc.
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:
 1. Redistributions of source code must retain the above copyright
    notice, this list of conditions and the following disclaimer.
 2. Redistributions in binary form must reproduce the above copyright
    notice, this list of conditions and the following disclaimer in the
    documentation and/or other materials provided with the distribution.
 3. Neither the name of Apple Computer, Inc. nor the names of its contributors
    may be used to endorse or promote products derived from this software
    without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
 LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.

 */

#import "PMApp.h" 
#import "PMConsole.h"


@implementation PMConsole
/*
    Controls the console window.   Currently there is only one shared console window for the entire app.   If we ever allow multiple simultaneous operations we may want to have 1 console window per operation so that output doesn't get intermingled.   Alternatively we could still use one console window but give the user a widget (op-up? list?) to control which operation the console window is currently monitoring.  It would be nice to give the console window a real toolbar in the future which also included a filter textfield and perhaps some items for printing/saving the log.   
*/


+ (PMConsole *) sharedConsole
/*
    Returns the single shared controller
*/
{
    static PMConsole *sharedConsole = nil;
    if (!sharedConsole)
    {
        sharedConsole = [[self alloc] init];
    }
    return sharedConsole;
}


- (id) init
{
    if (self = [self initWithWindowNibName: @"Console"])
    {
        _priorities = [[NSMutableArray alloc] initWithObjects: @"debug", @"info", @"msg", @"warn", @"error", nil];
        [[NSNotificationCenter defaultCenter] addObserver: self
            selector: @selector(portMessageNotification:)
            name: DPPortMessageNotification
            object: nil];
    }
    return self;
}


- (void) dealloc
{
    [_priorities release];
    [super dealloc];
}


- (void) windowDidLoad
{
    [self reloadTextView];
    [super windowDidLoad];
}


- (void) reloadTextView
{
    NSTextStorage *textStorage = [_textView textStorage];
    NSEnumerator *enm = [[(PMApp *)[NSApp delegate] messages] objectEnumerator];
    NSDictionary *entry;
    [_textView setString: @""];
    while (entry = [enm nextObject])
    {
        if ([_priorities indexOfObject: [entry objectForKey: @"priority"]] >= [_detailLevelPopUpButton selectedTag])
        {
            [textStorage appendAttributedString: 
                [[[NSMutableAttributedString alloc] initWithString:
                    [NSString stringWithFormat: @"%@:%@:%@", 
                        [entry objectForKey: @"portName"],
                        [entry objectForKey: @"priority"], 
                        [entry objectForKey: @"message"]]] autorelease]];
        }
    }
}


- (void) portMessageNotification: (NSNotification *)aNotification
{
    NSDictionary *entry = [aNotification userInfo];
    NSTextStorage *textStorage = [_textView textStorage];
    if ([_priorities indexOfObject: [entry objectForKey: @"priority"]] >= [_detailLevelPopUpButton selectedTag])
    {
        [textStorage appendAttributedString: 
            [[[NSMutableAttributedString alloc] initWithString:
                [NSString stringWithFormat: @"%@:%@:%@", 
                    [entry objectForKey: @"portName"],
                    [entry objectForKey: @"priority"], 
                    [entry objectForKey: @"message"]]] autorelease]];
    }
}


- (IBAction) changeDetailLevel: (id)sender
{
    [self reloadTextView];
}


@end
