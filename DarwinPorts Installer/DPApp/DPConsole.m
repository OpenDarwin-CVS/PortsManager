/*
 * DPConsole.m
 * DarwinPorts Installer
 *
 * Copyright (c) 2002-2003, Apple Computer, Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 * 3. Neither the name of Apple Computer, Inc. ("Apple") nor the names of
 *    its contributors may be used to endorse or promote products derived
 *    from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE AND ITS CONTRIBUTORS "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL APPLE OR ITS CONTRIBUTORS BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#import "DPApp.h"
#import "DPConsole.h"
#import "DPInstallerProtocol.h"


@implementation DPConsole
/*
 * Controls the console window.
 */


+ (DPConsole *) sharedConsole
    /*
     Returns the single shared controller
     */
{
    static DPConsole *sharedConsole = nil;
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
        [[NSNotificationCenter defaultCenter] addObserver: self
                                                 selector: @selector(installerUIEventNotification:)
                                                     name: DPInstallerUIEventNotification
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
    NSEnumerator *enm = [[(DPApp *)[NSApp delegate] messages] objectEnumerator];
    NSDictionary *entry;
    [_textView setString: @""];
    _textViewEndRange.location = 0;

    while (entry = [enm nextObject])
    {
        if ([[entry objectForKey: DPEventPriorityKey] isEqualToString: DPPriorityInfo]) {
            NSMutableAttributedString *string = [[NSMutableAttributedString alloc]
initWithString: [entry objectForKey: DPEventDataKey]];

            _textViewEndRange.location += [string length];
            [textStorage appendAttributedString: string];
            [_textView scrollRangeToVisible: _textViewEndRange];
        }
    }
}

- (void) installerUIEventNotification: (NSNotification *)aNotification
{
    NSDictionary *entry = [aNotification userInfo];
    NSTextStorage *textStorage = [_textView textStorage];
    NSString *priority = [entry objectForKey: DPEventPriorityKey];
    NSString *data = [entry objectForKey: DPEventDataKey];
    
    if ([priority isEqualToString: DPPriorityInfo]) {
        NSMutableAttributedString *string = [[NSMutableAttributedString alloc]
initWithString: data];

        _textViewEndRange.location += [string length];
        [textStorage appendAttributedString: string];
        [_textView scrollRangeToVisible: _textViewEndRange];
    }
}


@end