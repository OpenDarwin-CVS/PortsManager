//
//  DPAgent.h
//  DarwinPorts
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

/* mach port names */
#define DPAgentMessagePort @"org.opendarwin.darwinports.installer.DPAgent"
#define PMAppMessagePort @"org.opendarwin.darwinports.install.PMApp"

/* port keys */
#define DPNameKey @"name"
#define DPVersionKey @"version"
#define DPPortURLKey @"porturl"
#define DPCategoriesKey @"categories"
#define DPDependsKey @"depends_"
#define DPMaintainersKey @"maintainers"
#define DPPlatformsKey @"platforms"
#define DPPortDirKey @"portdir"
#define DPDescriptionKey @"description"
#define DPLongDescriptionKey @"long_description"

/* targets */
#define DPBuildTarget @"build"
#define DPCleanTarget @"clean"
#define DPChecksumTarget @"checksum"
#define DPFetchTarget @"fetch"
#define DPInstallTarget @"install"
#define DPPackageTarget @"package"

@protocol DPAgentProtocol

- (BOOL) agentInit;
- (bycopy NSData *) portsData;
- (oneway void) executeTarget: (in bycopy NSString *)target forPortName: (in bycopy NSString *)portName;
- (oneway void) terminate;

@end


@protocol DPDelegateProtocol

- (oneway void) displayMessage: (in bycopy NSDictionary *)message forPortName: (in bycopy NSString *)portName;
- (BOOL) shouldPerformTarget: (in bycopy NSString *)target forPortName: (in bycopy NSString *)portName;
- (oneway void) willPerformTarget: (in bycopy NSString *)target forPortName: (in bycopy NSString *)portName;
- (oneway void) didPerformTarget: (in bycopy NSString *)target forPortName: (in bycopy NSString *)portName withResult: (in bycopy NSString *)result;

@end

