//
//  PMApp.h
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
#import "PMBrowser.h"

#import "DPAgentProtocol.h"

NSString *DPPortMessageNotification = @"DPPortMessageNotification";
NSString *DPPortProgressNotification = @"DPPortProgressNotification";

#include <sys/types.h>
#include <sys/stat.h>
#include <unistd.h>

@implementation PMApp
/*
    Application delegate.   Manages communication with the dpagent process 
    via DO and maintains caches of various information retrieved from the agent.
*/


- (void) applicationWillFinishLaunching: (id)sender
{

    // set-up factory defaults from a plist
	[[NSUserDefaults standardUserDefaults] registerDefaults: 
		[NSMutableDictionary dictionaryWithContentsOfFile: 
			[[NSBundle mainBundle] pathForResource: @"Defaults" ofType: @"plist"]]];

}


- (BOOL) applicationOpenUntitledFile: (NSApplication *)sender
{
	[self newWindow: self];
    return YES;
}


- (void) applicationWillTerminate: (NSNotification *) notification
{
    [_agent terminate];
}


- (void) newWindow: (id)sender
{
    [[[PMBrowser alloc] init] showWindow: self];    
}


- (id <DPAgentProtocol>) agent
{

    if (!_agent)
    {
    
        struct stat sb;
        NSString *agentPath = [[NSBundle mainBundle] pathForResource: @"dpagent" ofType: @""];
        int i;
        
        // the agent should be installed setuid root so that it has the necessary
        // permissions to install/uninstall anywhere in the system.
        // here we check to be sure our agent is setuid root and log a warning if its not
        stat([agentPath fileSystemRepresentation], &sb);
        if ( (sb.st_uid != 0) || !(sb.st_mode & S_ISUID) )
        {
            NSLog(@"dpagent must be installed suid root for full functionality - please fix permissions!");
        }
        
        [NSTask launchedTaskWithLaunchPath: agentPath arguments: [NSArray array]];
        
        _connection = [NSConnection defaultConnection];
        [_connection setRootObject: self];
        [_connection enableMultipleThreads];
        if ([_connection registerName: @"PMApp"] == NO) 
        {
            NSLog(@"Couldn't register PMApp connection on this host.");
            exit(0);
        }

        for (i = 0; i<10; i++)
        {
            _connection = [[NSConnection connectionWithRegisteredName: @"DPAgent" host: nil] retain];
            if (_connection)
            {
                break;
            }
            sleep(1);
        }
        
        if (!_connection)
        {
            NSRunAlertPanel(@"PortsManager", @"Could not connect to dpagent!", nil, nil, nil);
            exit(0);
        }
        
        _agent = [[_connection rootProxy] retain];
        [(NSDistantObject *)_agent setProtocolForProxy: @protocol(DPAgentProtocol)];
        [_connection setRootObject: self];
        [[NSNotificationCenter defaultCenter] addObserver: self
            selector: @selector(connectionDidDie:)
            name: NSConnectionDidDieNotification
            object: _connection];

    }
    return _agent;
}


- (void) connectionDidDie:(id)server
{
    NSRunAlertPanel(@"PortsManager", @"Connection to dpagent died!", nil, nil, nil);
    _agent = nil;
    // resetting _agent to nil will cause a new instance of the _agent to
    // be spawned by [PMApp agent] next time someone tries to access it
}


- (NSDictionary *) ports
/*
    Return a dictionary of ports from the agent.   We only actually go out and fetch
    it the first time this method is called - after that we return a cached copy
    for performance reasons.   We should add another method to force a refetch
    when needed which will also need to post a notification to let the various
    windows displaying info from the dict refresh    
*/
{
    if (!_ports)
    {
        NSPropertyListFormat format;
        NSString *error;
        NSData *portsData = [[(PMApp *)[NSApp delegate] agent] portsData];
        _ports = [[NSPropertyListSerialization propertyListFromData: portsData
            mutabilityOption: NSPropertyListMutableContainersAndLeaves
             format: &format 
             errorDescription: &error] retain];
    }
    return _ports;
}


- (NSDictionary *) portForName: (NSString *)name
/*
    Returns a dictionary describing the port with the given name
*/
{
    return [_ports objectForKey: name];
}    


- (NSArray *) categories
/*
    Returns the list of all known categories in the port system.   The first entry in the array will always be a fake category used to represent the entire ports collection (all categories)
*/
{
    if (!_categories)
    {
        NSEnumerator *portEnm = [[self ports] objectEnumerator];
        NSDictionary *port;
        _categories = [[NSMutableArray alloc] init];
        while (port = [portEnm nextObject])
        {
            NSEnumerator *categoryEnm = [[port objectForKey: DPCategoriesKey] objectEnumerator];
            NSString *category;
            while (category = [categoryEnm nextObject])
            {
                if (![_categories containsObject: category])
                {
                    [_categories addObject: category];
                }
            }
        }
        
        [_categories sortUsingSelector: @selector(caseInsensitiveCompare:)];
        [_categories insertObject: @"*** ALL ***" atIndex: 0];
    }
    return _categories;
}


- (NSArray *) messages
{
    return _messages;
}


- (NSDictionary *) currentOperation
{
    return _currentOperation;
}


- (NSArray *) operations
{
    return _operations;
}


- (void) executeTarget: (NSString *)target forPortName: (NSString *)portName
{
    NSDictionary *op = [[NSMutableDictionary alloc] initWithObjectsAndKeys:
        portName, @"portName",
        target, @"target",
        nil];
        
    if (!_operations)
    {
        _operations = [[NSMutableArray alloc] init];
    }
    
    // we keep track of the operations we have fired off with the thought
    // that in the future we should have some UI for displaying them and
    // cancelling them - perhaps similar to the Safari downloads manager
    [_operations addObject: op];
    [_agent executeTarget: target forPortName: portName];
}


- (oneway void) displayMessage: (in bycopy NSString *)message withPriority: (in bycopy NSString *)priority forPortName: (in bycopy NSString *)portName
{
    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
        priority, @"priority",
        message, @"message",
        portName, @"portName",
        [NSDate date], @"date",
        nil];
    if (!_messages)
    {
        _messages = [[NSMutableArray alloc] init];
    }
    [_messages addObject: userInfo];
    [[NSNotificationCenter defaultCenter] postNotificationName: DPPortMessageNotification 
        object: [self portForName: portName]
        userInfo: userInfo];
//    NSLog(@"%@:%@ %@", portName, priority, message);
}


- (BOOL) shouldPerformTarget: (in bycopy NSString *)target forPortName: (in bycopy NSString *)portName
{
    return YES;
}


- (NSMutableDictionary *) _operationMatchingTarget: (NSString *)target andPortName: (NSString *)portName
{
    NSEnumerator *opEnm = [_operations objectEnumerator];
    NSMutableDictionary *op;
    while (op = [opEnm nextObject])
    {
        if ([[op objectForKey: @"portName"] isEqualToString: portName] &&
            [[op objectForKey: @"target"] isEqualToString: target])
        {
            break;
        }
    }
    return op;
}


- (oneway void) willPerformTarget: (in bycopy NSString *)target forPortName: (in bycopy NSString *)portName 
/*
    We get this callback when an operation we have requested is about to start executing
*/
{
    [_currentOperation release];
    _currentOperation = [[self _operationMatchingTarget: target andPortName: portName] retain];
    
    [_currentOperation setObject: [NSNumber numberWithFloat: 0.0] forKey: @"percentComplete"];

    [[NSNotificationCenter defaultCenter] postNotificationName: DPPortProgressNotification
        object: [self portForName: portName]
        userInfo: _currentOperation];    
}


- (oneway void) didPerformTarget: (in bycopy NSString *)target forPortName: (in bycopy NSString *)portName withResult: (in bycopy NSString *)result
/*
    We get this callback when an operation we have requested has finished executing
*/
{
    [_currentOperation release];
    _currentOperation = [[self _operationMatchingTarget: target andPortName: portName] retain];
    
    [_currentOperation setObject: [NSNumber numberWithFloat: 100.0] forKey: @"percentComplete"];

    [[NSNotificationCenter defaultCenter] postNotificationName: DPPortProgressNotification
        object: [self portForName: portName]
        userInfo: _currentOperation];    
}


@end
