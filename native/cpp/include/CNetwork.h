#ifndef CHAMPAIGN_NETWORK_H
#define CHAMPAIGN_NETWORK_H

//#include <hxcpp.h>

#ifdef _WIN32
#define LIB_EXPORT __declspec(dllexport)
#else
#define LIB_EXPORT
#endif

#include <map>
#include <stdlib.h>
#include <string>
#include <system_error>
#include <vector>

namespace NS_Champaign_Network
{

    LIB_EXPORT HXCPP_EXTERN_CLASS_ATTRIBUTES Dynamic __getAddrInfo(String host);
    LIB_EXPORT HXCPP_EXTERN_CLASS_ATTRIBUTES Dynamic __getNetworkInterfaces(bool ignoreLoopbackInterfaces);

}

#ifdef __cplusplus // when our lib is used from a C++ compiler, we need to wrap with extern "C"
extern "C"
{
#endif

#ifdef __cplusplus
}
#endif

#endif