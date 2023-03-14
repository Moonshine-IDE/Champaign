#ifdef _WIN32
#pragma comment(lib, "Advapi32.lib")
#include <windows.h>
#else
#include <unistd.h>
#endif
#include "CProcess.h"

namespace NS_Champaign_Process {

    bool __isUserRoot() {

        #ifdef _WIN32

        bool fRet = false;
        HANDLE hToken = NULL;
        if( OpenProcessToken( GetCurrentProcess( ),TOKEN_QUERY,&hToken ) ) {
            TOKEN_ELEVATION Elevation;
            DWORD cbSize = sizeof( TOKEN_ELEVATION );
            if( GetTokenInformation( hToken, TokenElevation, &Elevation, sizeof( Elevation ), &cbSize ) ) {
                fRet = Elevation.TokenIsElevated;
            }
        }
        if( hToken ) {
            CloseHandle( hToken );
        }
        return fRet;
        
        #else

        return geteuid() == 0;

        #endif

    }

}
