#import <Foundation/Foundation.h>
#import "DPAgent.h"

#include <sys/types.h>
#include <unistd.h>

int main(int argc, const char *argv[])
{

    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    DPAgent *agent;

    setuid(0);
    
    agent = [[DPAgent alloc] init];

    [[NSRunLoop currentRunLoop] run];

    [pool release];
    return 0;
        
}

