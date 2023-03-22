//#include <hx/OS.h>
//#include <hxcpp.h>
#include "CApplication.h"
#import <Foundation/Foundation.h>
#include <AppKit/AppKit.h>

namespace NS_Champaign_Application
{

    bool __isBounceIconSupported() {

        #ifdef __MACH__
        NSArray<NSWindow *> *windows;
        windows = [NSApp windows];
        return [windows count] > 0;
        #else
        return false;
        #endif

    }

    void __bounceIcon(bool isCritical) {
        if (isCritical)
            [NSApp requestUserAttention:NSCriticalRequest];
        else
            [NSApp requestUserAttention:NSInformationalRequest];
    }

}

// NSApplication applicationIconImage
// NSProcessInfo https://developer.apple.com/documentation/foundation/nsprocessinfo
