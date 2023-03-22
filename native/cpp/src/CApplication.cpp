#include <hx/OS.h>
#include <hxcpp.h>
#include "CApplication.h"

namespace NS_Champaign_Application
{

    bool __isBounceIconSupported() {

        #ifdef NEKO_MAC
        return false;
        #else
        return false;
        #endif

    }

    void __bounceIcon(bool isCritical) {}

}
