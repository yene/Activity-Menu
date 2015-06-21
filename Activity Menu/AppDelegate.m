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

NSUInteger const MENU_WIDTH = 50;

@interface AppDelegate ()
@property (weak) IBOutlet NSTextField *inLabel;
@property (weak) IBOutlet NSTextField *outLabel;

@property (weak) IBOutlet NSWindow *window;
@end

@implementation AppDelegate {
  NSUInteger inBytes;
  NSUInteger outBytes;
  NSStatusItem *statusItem;
  NSTextField *inTextField;
  NSTextField *outTextField;
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

- (void)awakeFromNib {
  statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
  //statusItem.button.title = @"hi";
  CGFloat menuBarHeight = [[[NSApplication sharedApplication] mainMenu] menuBarHeight];
  NSRect frame = NSMakeRect(0, 0, MENU_WIDTH, menuBarHeight);
  NSView *view = [[NSView alloc] initWithFrame:frame];
  
  inTextField = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 11, MENU_WIDTH, 10)];
  [inTextField setBezeled:NO];
  [inTextField setDrawsBackground:NO];
  [inTextField setEditable:NO];
  [inTextField setSelectable:NO];
  [inTextField setFont:[NSFont systemFontOfSize:10]];
  [inTextField setAlignment:NSRightTextAlignment];
  [view addSubview:inTextField];
  
  outTextField = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 2, MENU_WIDTH, 10)];
  [outTextField setBezeled:NO];
  [outTextField setDrawsBackground:NO];
  [outTextField setEditable:NO];
  [outTextField setSelectable:NO];
  [outTextField setFont:[NSFont systemFontOfSize:10]];
  [outTextField setAlignment:NSRightTextAlignment];
  [view addSubview:outTextField];
  
  statusItem.view = view;
  /*
  CALayer *viewLayer = [CALayer layer];
  [viewLayer setBackgroundColor:CGColorCreateGenericRGB(0.0, 0.0, 0.0, 0.4)]; //RGB plus Alpha Channel
  [view setWantsLayer:YES]; // view's backing store is using a Core Animation Layer
  [view setLayer:viewLayer];
  */
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
  inTextField.stringValue = [[formatter stringFromByteCount:newInBytes] stringByAppendingString:@"/s"];
  
  NSUInteger newOutBytes = totalobytes-outBytes;
  outBytes = totalobytes;
  outTextField.stringValue = [[formatter stringFromByteCount:newOutBytes] stringByAppendingString:@"/s"];
  
}



@end
