#ifndef CNetwork_h
#define CNetwork_h

#include <hxcpp.h>

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

    struct HostInfoEntry
    {
        std::string canonicalName;
        std::string ipv4;
        std::string ipv6;
    };

    struct HostInfo
    {
        bool success;
        int errorCode;
        std::string hostName;
        std::vector<HostInfoEntry> entries;
    };

    struct NetworkInterfaceEntry
    {
        std::string name;
        std::string broadcastAddress;
        std::string ipv4;
        std::string ipv4netmask;
        std::string ipv6;
        std::string ipv6netmask;
        int flags;
        bool enabled;
        bool loopback;
    };

    struct NetworkInterfaces
    {
        bool success;
        int errorCode;
        std::map<std::string, NetworkInterfaceEntry> entries;
    };

    LIB_EXPORT HXCPP_EXTERN_CLASS_ATTRIBUTES String __getAddrInfo(String host);
    HXCPP_EXTERN_CLASS_ATTRIBUTES String __getNetworkInterfaces(bool ignoreLoopbackInterfaces);

}

#ifdef __cplusplus // when our lib is used from a C++ compiler, we need to wrap with extern "C"
extern "C"
{
#endif

#ifdef __cplusplus
}
#endif

#endif