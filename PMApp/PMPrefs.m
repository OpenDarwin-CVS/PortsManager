//
//  PMPrefs.h
//  PortsManager
//
/*
 Copyright (c) 2002 Apple Computer, Inc.
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

NSString *debugKey = @"OutputDebug";
NSString *quietKey = @"OutputQuiet";
NSString *verboseKey = @"OutputVerbose";

@interface DPPrefs (Private)
- (BOOL) checkDefault:(NSString*)defaultKey;
- (void) setButtonCell:(NSButtonCell*)button toDefault:(NSString*)defaultKey;
- (void) setDefault:(NSString*)defaultKey toButtonCell:(NSButtonCell*)button;
- (void) loadPrefs;
- (void) savePrefs;
@end

@implementation DPPrefs

/** Defaults */

+ (void)initialize {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *appDefaults = [NSDictionary dictionaryWithObjectsAndKeys:
        @"NO", debugKey,
        @"NO", quietKey,
        @"NO", verboseKey,
        nil];
    [defaults registerDefaults:appDefaults];
}

- (BOOL) checkDefault:(NSString*)defaultKey {
    return [[NSUserDefaults standardUserDefaults] boolForKey:defaultKey];
}

- (void) setButtonCell:(NSButtonCell*)button toDefault:(NSString*)defaultKey {
    [button setState: ([self checkDefault:defaultKey]) ? NSOnState : NSOffState]; 
}

- (void) setDefault:(NSString*)defaultKey toButtonCell:(NSButtonCell*)button {
    NSString *state = ([button state] == NSOnState) ? @"YES" : @"NO";
    [[NSUserDefaults standardUserDefaults] setObject:state forKey:defaultKey];
}

- (void)loadPrefs {
    [self setButtonCell:debug toDefault:debugKey];
    [self setButtonCell:quiet toDefault:quietKey];
    [self setButtonCell:verbose toDefault:verboseKey];
}

- (void)savePrefs {
    [self setDefault:debugKey toButtonCell:debug];
    [self setDefault:quietKey toButtonCell:quiet];
    [self setDefault:verboseKey toButtonCell:verbose];
}

/** Actions */

- (IBAction)showPrefs:(id)sender
{
    [self loadPrefs];
    [prefWindow makeKeyAndOrderFront:sender];
}

- (IBAction)applyPrefs:(id)sender
{
    [self savePrefs];
    [prefWindow performClose:sender];

}

- (IBAction)cancelPrefs:(id)sender
{
    [prefWindow performClose:sender];

}

- (IBAction)revertPrefs:(id)sender
{
    [self loadPrefs];
}

/** Tests */

- (BOOL) isDebug {
    return [self checkDefault:debugKey];
}

- (BOOL) isQuiet{
    return [self checkDefault:quietKey];
}

- (BOOL) isVerbose{
    return [self checkDefault:verboseKey];
}

@end
