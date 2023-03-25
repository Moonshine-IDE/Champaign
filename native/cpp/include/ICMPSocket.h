#ifndef ICMPSocket_h
#define ICMPSocket_h

#include <hxcpp.h>

// Socket
HXCPP_EXTERN_CLASS_ATTRIBUTES void _icmp_socket_init();
HXCPP_EXTERN_CLASS_ATTRIBUTES Dynamic _icmp_socket_new(bool udp, bool ipv6 = false);
HXCPP_EXTERN_CLASS_ATTRIBUTES void _icmp_socket_bind(Dynamic o, int host, int port);
HXCPP_EXTERN_CLASS_ATTRIBUTES void _icmp_socket_bind_ipv6(Dynamic o, Array<unsigned char> host, int port);
HXCPP_EXTERN_CLASS_ATTRIBUTES void _icmp_socket_close(Dynamic handle);
HXCPP_EXTERN_CLASS_ATTRIBUTES void _icmp_socket_send_char(Dynamic o, int c);
HXCPP_EXTERN_CLASS_ATTRIBUTES int _icmp_socket_send(Dynamic o, Array<unsigned char> buf, int p, int l);
HXCPP_EXTERN_CLASS_ATTRIBUTES int _icmp_socket_recv(Dynamic o, Array<unsigned char> buf, int p, int l);
HXCPP_EXTERN_CLASS_ATTRIBUTES int _icmp_socket_recv_char(Dynamic o);
HXCPP_EXTERN_CLASS_ATTRIBUTES void _icmp_socket_write(Dynamic o, Array<unsigned char> buf);
HXCPP_EXTERN_CLASS_ATTRIBUTES Array<unsigned char> _icmp_socket_read(Dynamic o);
HXCPP_EXTERN_CLASS_ATTRIBUTES int _icmp_host_resolve(String host);
HXCPP_EXTERN_CLASS_ATTRIBUTES Array<unsigned char> _icmp_host_resolve_ipv6(String host, bool dummy = true);
HXCPP_EXTERN_CLASS_ATTRIBUTES String _icmp_host_to_string(int ip);
HXCPP_EXTERN_CLASS_ATTRIBUTES String _icmp_host_to_string_ipv6(Array<unsigned char> ip);
HXCPP_EXTERN_CLASS_ATTRIBUTES String _icmp_host_reverse(int host);
HXCPP_EXTERN_CLASS_ATTRIBUTES String _icmp_host_reverse_ipv6(Array<unsigned char> host);
HXCPP_EXTERN_CLASS_ATTRIBUTES String _icmp_host_local();
HXCPP_EXTERN_CLASS_ATTRIBUTES void _icmp_socket_connect(Dynamic o, int host, int port);
HXCPP_EXTERN_CLASS_ATTRIBUTES void _icmp_socket_connect_ipv6(Dynamic o, Array<unsigned char> host, int port);
HXCPP_EXTERN_CLASS_ATTRIBUTES void _icmp_socket_listen(Dynamic o, int n);
HXCPP_EXTERN_CLASS_ATTRIBUTES Array<Dynamic> _icmp_socket_select(Array<Dynamic> rs, Array<Dynamic> ws, Array<Dynamic> es, Dynamic timeout);
HXCPP_EXTERN_CLASS_ATTRIBUTES void _icmp_socket_fast_select(Array<Dynamic> rs, Array<Dynamic> ws, Array<Dynamic> es, Dynamic timeout);
HXCPP_EXTERN_CLASS_ATTRIBUTES Dynamic _icmp_socket_accept(Dynamic o);
HXCPP_EXTERN_CLASS_ATTRIBUTES Array<int> _icmp_socket_peer(Dynamic o);
HXCPP_EXTERN_CLASS_ATTRIBUTES Array<int> _icmp_socket_host(Dynamic o);
HXCPP_EXTERN_CLASS_ATTRIBUTES void _icmp_socket_set_timeout(Dynamic o, Dynamic t);
HXCPP_EXTERN_CLASS_ATTRIBUTES void _icmp_socket_shutdown(Dynamic o, bool r, bool w);
HXCPP_EXTERN_CLASS_ATTRIBUTES void _icmp_socket_set_blocking(Dynamic o, bool b);
HXCPP_EXTERN_CLASS_ATTRIBUTES void _icmp_socket_set_fast_send(Dynamic o, bool b);
HXCPP_EXTERN_CLASS_ATTRIBUTES void _icmp_socket_set_broadcast(Dynamic o, bool b);
HXCPP_EXTERN_CLASS_ATTRIBUTES Dynamic _icmp_socket_poll_alloc(int nsocks);
HXCPP_EXTERN_CLASS_ATTRIBUTES Array<Dynamic> _icmp_socket_poll_prepare(Dynamic pdata, Array<Dynamic> rsocks, Array<Dynamic> wsocks);
HXCPP_EXTERN_CLASS_ATTRIBUTES void _icmp_socket_poll_events(Dynamic pdata, double timeout);
HXCPP_EXTERN_CLASS_ATTRIBUTES Array<Dynamic> _icmp_socket_poll(Array<Dynamic> socks, Dynamic pdata, double timeout);
HXCPP_EXTERN_CLASS_ATTRIBUTES int _icmp_socket_send_to(Dynamic o, Array<unsigned char> buf, int p, int l, Dynamic inAddr, int icmp_seq_nr, int icmp_id_nr);
HXCPP_EXTERN_CLASS_ATTRIBUTES int _icmp_socket_recv_from(Dynamic o, Array<unsigned char> buf, int p, int l, Dynamic outAddr);
HXCPP_EXTERN_CLASS_ATTRIBUTES int _icmp_socket_recv2(Dynamic o, Array<unsigned char> buf);

HXCPP_EXTERN_CLASS_ATTRIBUTES int _create_simple_socket();
HXCPP_EXTERN_CLASS_ATTRIBUTES int _simple_socket_send( int sock, Array<unsigned char> buf, Dynamic inAddr, int seq_nr, int id_nr );

#endif