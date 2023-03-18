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

#include <iostream>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <system_error>
#include "nlohmann/json.hpp"
#include "CNetwork.h"
#ifdef _WIN32
#pragma comment(lib, "Ws2_32.lib")
#pragma comment(lib, "IPHLPAPI.lib")
#include <ws2tcpip.h>
#include <iphlpapi.h>
#include <windows.h>
#include <winsock2.h>
#define WORKING_BUFFER_SIZE 15000
#define MAX_TRIES 3
#define MALLOC(x) HeapAlloc(GetProcessHeap(), 0, (x))
#define FREE(x) HeapFree(GetProcessHeap(), 0, (x))
#else
#include <arpa/inet.h>
#include <ifaddrs.h>
#include <net/if.h>
#include <netdb.h>
#include <sys/socket.h>
#include <netinet/tcp.h>
#endif

#include <hxcpp.h>

// #include "fping.h"

using json = nlohmann::json;

namespace NS_Champaign_Network
{

	// HostInfoEntry -> Json
	void to_json(json &j, const HostInfoEntry &hie)
	{
		j = json{};
		if (!hie.canonicalName.empty())
			j["canonicalName"] = hie.canonicalName;
		if (!hie.ipv4.empty())
			j["ipv4"] = hie.ipv4;
		if (!hie.ipv6.empty())
			j["ipv6"] = hie.ipv6;
	}

	// HostInfo -> Json
	void to_json(json &j, const HostInfo &hi)
	{
		j = json{{"success", hi.success}, {"errorCode", hi.errorCode}, {"hostName", hi.hostName}};
		if (!hi.entries.empty())
			j["entries"] = hi.entries;
	}

	String __getAddrInfo(String host)
	{

		HostInfo hostInfo;
		std::string hn(host);
		hostInfo.hostName = hn;

		struct addrinfo hints, *res, *result;
		int errcode;
		char addrstr[100];
		void *ptr;

		memset(&hints, 0, sizeof(hints));
		hints.ai_family = AF_UNSPEC;
		hints.ai_socktype = SOCK_STREAM;
		hints.ai_protocol = IPPROTO_TCP;
		hints.ai_flags |= AI_V4MAPPED;
		hints.ai_flags |= AI_CANONNAME;

#ifdef _WIN32
		int iResult;
		WSADATA wsaData;
		iResult = WSAStartup(MAKEWORD(2, 2), &wsaData);
		if (iResult != 0)
		{
			// printf("WSAStartup failed: %d\n", iResult);
			hostInfo.success = false;
			hostInfo.errorCode = iResult;
			json j = hostInfo;
			auto s = j.dump();
			char *finalresult = strcpy(new char[s.length() + 1], s.c_str());
			return finalresult;
		}
#endif

		errcode = getaddrinfo(host, NULL, &hints, &result);
		if (errcode != 0)
		{
			hostInfo.success = false;
			hostInfo.errorCode = errcode;
			json j = hostInfo;
			auto s = j.dump();
			char *finalresult = strcpy(new char[s.length() + 1], s.c_str());
			return finalresult;
		}

		res = result;

		while (res)
		{
			inet_ntop(res->ai_family, res->ai_addr->sa_data, addrstr, 100);

			HostInfoEntry hi;

			switch (res->ai_family)
			{
			case AF_INET:
				ptr = &((struct sockaddr_in *)res->ai_addr)->sin_addr;
				break;
			case AF_INET6:
				ptr = &((struct sockaddr_in6 *)res->ai_addr)->sin6_addr;
				break;
			}

			inet_ntop(res->ai_family, ptr, addrstr, 100);

			std::string str(addrstr);
			if (res->ai_family == AF_INET6)
			{
				hi.ipv6 = str;
			}
			else
			{
				hi.ipv4 = str;
			}
			if (res->ai_canonname != NULL)
			{
				std::string cn(res->ai_canonname);
				hi.canonicalName = cn;
			}

			hostInfo.entries.push_back(hi);
			// printf("IPv%d address: %s (%s)\n", res->ai_family == PF_INET6 ? 6 : 4, addrstr, res->ai_canonname);

			res = res->ai_next;
		}

		freeaddrinfo(result);

		hostInfo.success = true;
		hostInfo.errorCode = 0;

		json j = hostInfo;
		auto s = j.dump();
		char *finalresult = strcpy(new char[s.length() + 1], s.c_str());
		return String(finalresult);
		//return finalresult;
	}

	// NetworkInterfaceEntry -> Json
	void to_json(json &j, const NetworkInterfaceEntry &nie)
	{
		j = json{{"name", nie.name}, {"flags", nie.flags}, {"enabled", nie.enabled}, {"loopback", nie.loopback}};
		if (!nie.ipv4.empty())
			j["ipv4"] = nie.ipv4;
		if (!nie.ipv4netmask.empty())
			j["ipv4netmask"] = nie.ipv4netmask;
		if (!nie.ipv6.empty())
			j["ipv6"] = nie.ipv6;
		if (!nie.ipv6netmask.empty())
			j["ipv6netmask"] = nie.ipv6netmask;
	}

	// NetworkInterfaces -> Json
	void to_json(json &j, const NetworkInterfaces &ni)
	{
		j = json{{"success", ni.success}, {"errorCode", ni.errorCode}};
		if (!ni.entries.empty())
			j["entries"] = ni.entries;
	}

#ifdef _WIN32
	std::string NarrowString(const std::wstring &str, const char *localeName = "C")
	{
		std::string result;
		result.resize(str.size());

		std::locale loc(localeName);

		std::use_facet<std::ctype<wchar_t>>(loc).narrow(
			str.c_str(), str.c_str() + str.size(), '?', &*result.begin());

		return result;
	}
#endif

	String __getNetworkInterfaces(bool ignoreLoopbackInterfaces)
	{

		NetworkInterfaces networkInterfaces;
		networkInterfaces.success = false;
		networkInterfaces.errorCode = 1;

#ifdef _WIN32

		// IpAddresses ipAddrs;
		IP_ADAPTER_ADDRESSES *adapter_addresses(NULL);
		IP_ADAPTER_ADDRESSES *adapter(NULL);

		// Start with a 16 KB buffer and resize if needed -
		// multiple attempts in case interfaces change while
		// we are in the middle of querying them.
		DWORD adapter_addresses_buffer_size = 16384;
		for (int attempts = 0; attempts != 3; ++attempts)
		{
			adapter_addresses = (IP_ADAPTER_ADDRESSES *)malloc(adapter_addresses_buffer_size);
			assert(adapter_addresses);

			DWORD error = ::GetAdaptersAddresses(
				AF_UNSPEC,
				GAA_FLAG_SKIP_ANYCAST |
					GAA_FLAG_SKIP_MULTICAST |
					GAA_FLAG_SKIP_DNS_SERVER |
					GAA_FLAG_SKIP_FRIENDLY_NAME,
				NULL,
				adapter_addresses,
				&adapter_addresses_buffer_size);

			if (ERROR_SUCCESS == error)
			{
				// We're done here, people!
				break;
			}
			else if (ERROR_BUFFER_OVERFLOW == error)
			{
				// Try again with the new size
				free(adapter_addresses);
				adapter_addresses = NULL;

				continue;
			}
			else
			{
				// Unexpected error code - log and throw
				free(adapter_addresses);
				adapter_addresses = NULL;

				// @todo
				// LOG_AND_THROW_HERE();
			}
		}

		// Iterate through all of the adapters
		for (adapter = adapter_addresses; NULL != adapter; adapter = adapter->Next)
		{
			// Skip loopback adapters
			// if (IF_TYPE_SOFTWARE_LOOPBACK == adapter->IfType && ignoreLoopbackInterfaces)

			std::string interface_name = NarrowString(adapter->FriendlyName);
			NetworkInterfaceEntry entry;
			if (networkInterfaces.entries.find(interface_name) != networkInterfaces.entries.end())
				entry = networkInterfaces.entries[interface_name];
			entry.name = interface_name;
			entry.flags = adapter->Flags;
			entry.enabled = adapter->OperStatus == IfOperStatusUp;
			entry.loopback = IF_TYPE_SOFTWARE_LOOPBACK == adapter->IfType;

			// Parse all IPv4 and IPv6 addresses
			for (
				IP_ADAPTER_UNICAST_ADDRESS *address = adapter->FirstUnicastAddress;
				NULL != address;
				address = address->Next)
			{
				auto family = address->Address.lpSockaddr->sa_family;
				if (AF_INET == family)
				{
					// IPv4
					SOCKADDR_IN *ipv4 = reinterpret_cast<SOCKADDR_IN *>(address->Address.lpSockaddr);

					char str_buffer[INET_ADDRSTRLEN] = {0};
					inet_ntop(AF_INET, &(ipv4->sin_addr), str_buffer, INET_ADDRSTRLEN);
					entry.ipv4 = str_buffer;
					// ipAddrs.mIpv4.push_back(str_buffer);
				}
				else if (AF_INET6 == family)
				{
					// IPv6
					SOCKADDR_IN6 *ipv6 = reinterpret_cast<SOCKADDR_IN6 *>(address->Address.lpSockaddr);

					char str_buffer[INET6_ADDRSTRLEN] = {0};
					inet_ntop(AF_INET6, &(ipv6->sin6_addr), str_buffer, INET6_ADDRSTRLEN);

					std::string ipv6_str(str_buffer);
					entry.ipv6 = ipv6_str;

					// Detect and skip non-external addresses
					bool is_link_local(false);
					bool is_special_use(false);

					if (0 == ipv6_str.find("fe"))
					{
						char c = ipv6_str[2];
						if (c == '8' || c == '9' || c == 'a' || c == 'b')
						{
							is_link_local = true;
						}
					}
					else if (0 == ipv6_str.find("2001:0:"))
					{
						is_special_use = true;
					}

					if (!(is_link_local || is_special_use))
					{
						// ipAddrs.mIpv6.push_back(ipv6_str);
					}
				}
				else
				{
					// Skip all other types of addresses
					continue;
				}
				networkInterfaces.entries[interface_name] = entry;
			}
		}

		// Cleanup
		free(adapter_addresses);
		adapter_addresses = NULL;

#else

		struct ifaddrs *ptr_ifaddrs = nullptr;

		auto result = getifaddrs(&ptr_ifaddrs);
		if (result != 0)
		{
			// std::cout << "`getifaddrs()` failed: " << strerror(errno) << std::endl;
			networkInterfaces.errorCode = 2;
			json j = networkInterfaces;
			auto s = j.dump();
			char *finalresult = strcpy(new char[s.length() + 1], s.c_str());
			return finalresult;
		}

		for (
			struct ifaddrs *ptr_entry = ptr_ifaddrs;
			ptr_entry != nullptr;
			ptr_entry = ptr_entry->ifa_next)
		{
			std::string ipaddress_human_readable_form;
			std::string netmask_human_readable_form;

			std::string interface_name = std::string(ptr_entry->ifa_name);
			NetworkInterfaceEntry entry;
			if (networkInterfaces.entries.find(interface_name) != networkInterfaces.entries.end())
				entry = networkInterfaces.entries[interface_name];
			entry.name = interface_name;
			entry.flags = ptr_entry->ifa_flags;
			entry.enabled = ptr_entry->ifa_flags & IFF_UP;
			entry.loopback = ptr_entry->ifa_flags & IFF_LOOPBACK;

			sa_family_t address_family = ptr_entry->ifa_addr->sa_family;
			if (address_family == AF_INET)
			{
				// IPv4

				// Be aware that the `ifa_addr`, `ifa_netmask` and `ifa_data` fields might contain nullptr.
				// Dereferencing nullptr causes "Undefined behavior" problems.
				// So it is need to check these fields before dereferencing.
				if (ptr_entry->ifa_addr != nullptr)
				{
					char buffer[INET_ADDRSTRLEN] = {
						0,
					};
					inet_ntop(
						address_family,
						&((struct sockaddr_in *)(ptr_entry->ifa_addr))->sin_addr,
						buffer,
						INET_ADDRSTRLEN);

					ipaddress_human_readable_form = std::string(buffer);
				}

				if (ptr_entry->ifa_netmask != nullptr)
				{
					char buffer[INET_ADDRSTRLEN] = {
						0,
					};
					inet_ntop(
						address_family,
						&((struct sockaddr_in *)(ptr_entry->ifa_netmask))->sin_addr,
						buffer,
						INET_ADDRSTRLEN);

					netmask_human_readable_form = std::string(buffer);
				}

				entry.ipv4 = ipaddress_human_readable_form;
				entry.ipv4netmask = netmask_human_readable_form;

				// std::cout << interface_name << ": IP address = " << ipaddress_human_readable_form << ", netmask = " << netmask_human_readable_form << std::endl;
			}
			else if (address_family == AF_INET6)
			{
				// IPv6
				uint32_t scope_id = 0;
				if (ptr_entry->ifa_addr != nullptr)
				{
					char buffer[INET6_ADDRSTRLEN] = {
						0,
					};
					inet_ntop(
						address_family,
						&((struct sockaddr_in6 *)(ptr_entry->ifa_addr))->sin6_addr,
						buffer,
						INET6_ADDRSTRLEN);

					ipaddress_human_readable_form = std::string(buffer);
					scope_id = ((struct sockaddr_in6 *)(ptr_entry->ifa_addr))->sin6_scope_id;
					entry.ipv6 = ipaddress_human_readable_form;
				}

				if (ptr_entry->ifa_netmask != nullptr)
				{
					char buffer[INET6_ADDRSTRLEN] = {
						0,
					};
					inet_ntop(
						address_family,
						&((struct sockaddr_in6 *)(ptr_entry->ifa_netmask))->sin6_addr,
						buffer,
						INET6_ADDRSTRLEN);

					netmask_human_readable_form = std::string(buffer);
				}

				entry.ipv6 = ipaddress_human_readable_form;
				entry.ipv6netmask = netmask_human_readable_form;
				// std::cout << interface_name << ": IP address = " << ipaddress_human_readable_form << ", netmask = " << netmask_human_readable_form << ", Scope-ID = " << scope_id << std::endl;
			}
			else
			{
				// AF_UNIX, AF_UNSPEC, AF_PACKET etc.
				// If ignored, delete this section.
			}
			/*
			char ap[100];
			const int family_size = address_family == AF_INET ? sizeof(struct sockaddr_in) : sizeof(struct sockaddr_in6);
			getnameinfo(ptr_entry->ifa_addr,family_size, ap, sizeof(ap), 0, 0, NI_NUMERICHOST);
			printf("\t%s\n", ap);
			*/
			if (!entry.loopback || !ignoreLoopbackInterfaces)
				networkInterfaces.entries[interface_name] = entry;
		}

		freeifaddrs(ptr_ifaddrs);

#endif

		networkInterfaces.success = true;
		networkInterfaces.errorCode = 0;

		json j = networkInterfaces;
		auto s = j.dump();
		char *finalresult = strcpy(new char[s.length() + 1], s.c_str());
		return String(finalresult);
		//return finalresult;
	}

}
