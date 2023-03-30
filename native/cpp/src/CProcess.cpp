/*
 *  Copyright (C) 2016-present Prominic.NET, Inc.
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the Server Side Public License, version 1,
 *  as published by MongoDB, Inc.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 *  Server Side Public License for more details.
 *
 *  You should have received a copy of the Server Side Public License
 *  along with this program. If not, see
 *
 *  http://www.mongodb.com/licensing/server-side-public-license
 *
 *  As a special exception, the copyright holders give permission to link the
 *  code of portions of this program with the OpenSSL library under certain
 *  conditions as described in each individual source file and distribute
 *  linked combinations including the program with the OpenSSL library. You
 *  must comply with the Server Side Public License in all respects for
 *  all of the code used other than as permitted herein. If you modify file(s)
 *  with this exception, you may extend this exception to your version of the
 *  file(s), but you are not obligated to do so. If you do not wish to do so,
 *  delete this exception statement from your version. If you delete this
 *  exception statement from all source files in the program, then also delete
 *  it in the license file.
 */

#ifdef _WIN32
#pragma comment(lib, "Advapi32.lib")
#include <windows.h>
#else
#include <unistd.h>
#include <sys/resource.h>
#endif
#include "CProcess.h"
#include <stdio.h>

namespace NS_Champaign_Process
{

    bool __isUserRoot()
    {

#ifdef _WIN32

        bool fRet = false;
        HANDLE hToken = NULL;
        if (OpenProcessToken(GetCurrentProcess(), TOKEN_QUERY, &hToken))
        {
            TOKEN_ELEVATION Elevation;
            DWORD cbSize = sizeof(TOKEN_ELEVATION);
            if (GetTokenInformation(hToken, TokenElevation, &Elevation, sizeof(Elevation), &cbSize))
            {
                fRet = Elevation.TokenIsElevated;
            }
        }
        if (hToken)
        {
            CloseHandle(hToken);
        }
        return fRet;

#else

        return geteuid() == 0;

#endif
    }

    int __getFileResourceLimit()
    {
        #ifdef _WIN32
        return -1;
        #else
        struct rlimit limit;
        int result = getrlimit(RLIMIT_NOFILE, &limit);
        if ( result != 0 ) return -1;
        return limit.rlim_cur;
        #endif
    }

    bool __setFileResourceLimit( int lmt )
    {
        #ifdef _WIN32
        return 1;
        #else
        struct rlimit limit;
        limit.rlim_cur = lmt;
        limit.rlim_max = lmt;
        int result = setrlimit(RLIMIT_NOFILE, &limit);
        return result == 0;
        #endif
    }

}
