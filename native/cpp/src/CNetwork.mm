#include <arpa/inet.h>
#include <ifaddrs.h>
#include <iostream>
#include <net/if.h>
#include <netdb.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <system_error>
#include "include/nlohmann/json.hpp"
#include "CNetwork.h"

using json = nlohmann::json;

namespace NS_CNetwork
{

	// HostInfoEntry -> Json
	void to_json(json &j, const HostInfoEntry &hie)
	{
		j = json{{"canonicalName", hie.canonicalName}};
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

	char *__getAddrInfo(const char *host)
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
			std::string cn(res->ai_canonname);
			if (res->ai_family == AF_INET6)
			{
				hi.ipv6 = str;
			}
			else
			{
				hi.ipv4 = str;
			}

			hi.canonicalName = cn;
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
		return finalresult;
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

	std::string NarrowString(const std::wstring &str, const char *localeName = "C")
	{
		std::string result;
		result.resize(str.size());

		std::locale loc(localeName);

		std::use_facet<std::ctype<wchar_t>>(loc).narrow(
			str.c_str(), str.c_str() + str.size(), '?', &*result.begin());

		return result;
	}

	char *__getNetworkInterfaces(bool ignoreLoopbackInterfaces)
	{

		NetworkInterfaces networkInterfaces;
		networkInterfaces.success = false;
		networkInterfaces.errorCode = 1;

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
			if ( !entry.loopback || !ignoreLoopbackInterfaces ) networkInterfaces.entries[interface_name] = entry;
		}

		freeifaddrs(ptr_ifaddrs);

		networkInterfaces.success = true;
		networkInterfaces.errorCode = 0;

		json j = networkInterfaces;
		auto s = j.dump();
		char *finalresult = strcpy(new char[s.length() + 1], s.c_str());
		return finalresult;
	}

}