//
//  AppDelegate.m
//  Activity Menu
//
//  Created by Yannick Weiss on 21/06/15.
//  Copyright (c) 2015 Yannick Weiss. All rights reserved.
//

#import "AppDelegate.h"
#include <sys/sysctl.h>
#include <netinet/in.h>
#include <net/if.h>
#include <net/route.h>

NSUInteger const MTU = 1500;

@interface AppDelegate ()
@property (weak) IBOutlet NSTextField *inLabel;
@property (weak) IBOutlet NSTextField *outLabel;

@property (weak) IBOutlet NSWindow *window;
@end

@implementation AppDelegate {
  NSUInteger inBytes;
  NSUInteger outBytes;

}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
  // Insert code here to initialize your application
  [NSTimer scheduledTimerWithTimeInterval:1.0
                                   target:self
                                 selector:@selector(update)
                                 userInfo:nil
                                  repeats:YES];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
  // Insert code here to tear down your application
}

- (void)update {
  int mib[] = {
    CTL_NET,
    PF_ROUTE,
    0,
    0,
    NET_RT_IFLIST2,
    0
  };
  size_t len;
  if (sysctl(mib, 6, NULL, &len, NULL, 0) < 0) {
    fprintf(stderr, "sysctl: %s\n", strerror(errno));
    exit(1);
  }
  char *buf = (char *)malloc(len);
  if (sysctl(mib, 6, buf, &len, NULL, 0) < 0) {
    fprintf(stderr, "sysctl: %s\n", strerror(errno));
    exit(1);
  }
  char *lim = buf + len;
  char *next = NULL;
  u_int64_t totalibytes = 0;
  u_int64_t totalobytes = 0;
  for (next = buf; next < lim; ) {
    struct if_msghdr *ifm = (struct if_msghdr *)next;
    next += ifm->ifm_msglen;
    if (ifm->ifm_type == RTM_IFINFO2) {
      struct if_msghdr2 *if2m = (struct if_msghdr2 *)ifm;
      totalibytes += if2m->ifm_data.ifi_ibytes;
      totalobytes += if2m->ifm_data.ifi_obytes;
    }
  }
  //printf("total ibytes %qu\tobytes %qu\n", totalibytes, totalobytes);
  // http://nshipster.com/nsformatter/
  NSByteCountFormatter *formatter = [[NSByteCountFormatter alloc] init];
  formatter.allowedUnits = NSByteCountFormatterUseMB;
  
  
  NSUInteger newInBytes = totalibytes-inBytes;
  inBytes = totalibytes;
  self.inLabel.stringValue = [[formatter stringFromByteCount:newInBytes] stringByAppendingString:@"/s"];
  
  NSUInteger newOutBytes = totalobytes-outBytes;
  outBytes = totalobytes;
  self.outLabel.stringValue = [[formatter stringFromByteCount:newOutBytes] stringByAppendingString:@"/s"];
  
  
}



@end
