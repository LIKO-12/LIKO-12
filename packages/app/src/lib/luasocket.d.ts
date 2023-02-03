interface TCPShared {
    /**
     * (any) Closes a TCP object.
     * The internal socket used by the object is closed and the local address to which the object was bound is made available to other applications.
     * No further operations (except for further calls to the close method) are allowed on a closed socket.
     */
    close(): void;

    /**
     * (any) Returns the local address information associated to the object.
     * 
     * @returns a string with local IP address, a number with the local port,
     * and a string with the family ("inet" or "inet6").
     * In case of error, the method returns `undefined`.
     */
    getsockname(): LuaMultiReturn<[string | undefined, number | undefined, string | undefined]>;

    /**
     * (any) Returns accounting information on the socket, useful for throttling of bandwidth.
     * @returns the number of bytes received, the number of bytes sent, and the age of the socket object in seconds.
     */
    getstats(): LuaMultiReturn<[number, number, number]>;

    /**
     * (any) Returns the current block timeout followed by the current total timeout.
     */
    gettimeout(): LuaMultiReturn<[number, number]>;

    /**
     * (any) Resets accounting information on the socket, useful for throttling of bandwidth.
     * 
     * @param received new number of bytes received.
     * @param sent new number of bytes sent.
     * @param age new age in seconds.
     * @returns 1 in case of success, or `undefined` followed by an error message otherwise.
     */
    setstats(received: number, sent: number, age: number): LuaMultiReturn<[1 | undefined, string]>;

    /**
     * (any) Changes the timeout values for the object.
     * 
     * By default, all I/O operations are blocking.
     * That is, any call to the methods send, receive, and accept will block indefinitely, until the operation completes.
     * The `settimeout` method defines a limit on the amount of time the I/O methods can block.
     * When a timeout is set and the specified amount of time has elapsed, the affected methods give up and fail with an error code.
     * 
     * @param time the amount of time to wait, in seconds.
     * 
     * The `undefined` timeout value allows operations to block indefinitely.
     * Negative timeout values have the same effect.
     * @param mode There are two timeout modes and both can be used together for fine tuning:
     * - `'b'`: block timeout. Specifies the upper limit on the amount of time LuaSocket can be blocked by the operating system while waiting for completion of any single I/O operation. This is the default mode;
     * - `'t'`: total timeout. Specifies the upper limit on the amount of time LuaSocket can block a Lua script before returning from a call.
     */
    settimeout(time: number | undefined, mode?: 'b' | 't'): void;
}

interface TCPMaster {
    /**
     * (master) Binds a master object to address and port on the local host.
     * 
     * @param address Address can be an IP address or a host name.
     * If address is `'*'`, the system binds to all local interfaces using the INADDR_ANY constant or IN6ADDR_ANY_INIT, according to the family.
     * @param port Port must be an integer number in the range [0..64K).
     * If port is `0`, the system automatically chooses an ephemeral port.
     * @param backlog the number of client connections that can be queued waiting for service.
     * If the queue is full and another client attempts connection, the connection is refused.
     * 
     * @returns 1 in case of success, or `undefined` followed by an error message otherwise.
     */
    bind(address: string, port: number): LuaMultiReturn<[1 | undefined, string]>;

    /**
     * (master) Attempts to connect a master object to a remote host, transforming it into a client object.
     * Client objects support methods `send`, `receive`, `getsockname`, `getpeername`, `settimeout`, and `close`.
     * 
     * @param address Address can be an IP address or a host name.
     * @param port Port must be an integer number in the range [0..64K).
     * 
     * @returns 1 in case of success, or `undefined` followed by an error message otherwise.
     */
    connect(address: string, port: number): LuaMultiReturn<[1 | undefined, string]>;

    /**
     * (master) Specifies the socket is willing to receive connections, transforming the object into a server object.
     * 
     * Server objects support the `accept`, `getsockname`, `setoption`, `settimeout`, and `close` methods.
     * @param backlog the number of client connections that can be queued waiting for service.
     * If the queue is full and another client attempts connection, the connection is refused.
     */
    listen(backlog: number): LuaMultiReturn<[1 | undefined, string]>;
}

interface TCPClient {
    /**
     * (client) Returns information about the remote side of a connected client object.
     * 
     * @returns a string with the IP address of the peer, the port number that peer is using for the connection,
     * and a string with the family ("inet" or "inet6"). In case of error, the method returns `undefined`.
     */
    getpeername(): LuaMultiReturn<[string | undefined, number | undefined, string | undefined]>;

    /**
     * (client) Reads data from a client object, according to the specified read pattern.
     * Patterns follow the Lua file I/O format,
     * and the difference in performance between all patterns is negligible.
     * 
     * @param pattern can be any of the following:
     * - `'*a'`: reads from the socket until the connection is closed. No end-of-line translation is performed.
     * - `'*l'`: reads a line of text from the socket. The line is terminated by a LF character (ASCII 10), optionally preceded by a CR character (ASCII 13). The CR and LF characters are not included in the returned line. In fact, all CR characters are ignored by the pattern. This is the default pattern;
     * - number: causes the method to read a specified number of bytes from the socket.
     * @param prefix is an optional string to be concatenated to the beginning of any received data before return.
     * @returns If successful, the method returns the received pattern.
     * In case of error, the method returns `undefined` followed by an error message, followed by a (possibly empty) string containing the partial that was received.
     * The error message can be the string 'closed' in case the connection was closed before the transmission was completed or the string 'timeout' in case there was a timeout during the operation.
     */
    receive(pattern?: '*a' | '*l' | number, prefix?: string): LuaMultiReturn<[string | undefined, string, string]>

    /**
     * (client) Sends data through client object.
     * 
     * @param data the string to be sent.
     * @param i works exactly like the standard `string.sub` Lua function to allow the selection of a substring to be sent.
     * @param j works exactly like the standard `string.sub` Lua function to allow the selection of a substring to be sent.
     * @returns If successful, the method returns the index of the last byte within [i, j] that has been sent.
     * Notice that, if i is 1 or absent, this is effectively the total number of bytes sent.
     * 
     * In case of error, the method returns `undefined`, followed by an error message, followed by the index of the last byte within [i, j] that has been sent.
     * You might want to try again from the byte following that.
     * The error message can be 'closed' in case the connection was closed before the transmission was completed or the string 'timeout' in case there was a timeout during the operation.
     */
    send(data: string, i?: number, j?: number): LuaMultiReturn<[number | undefined, string]>;

    /**
     * (client) Shuts down part of a full-duplex connection.
     * @param mode which way of the connection should be shut down and can take the value:
     * - `"both"`: disallow further sends and receives on the object. This is the default mode;
     * - `"send"`: disallow further sends on the object;
     * - `"receive"`: disallow further receives on the object.
     */
    shutdown(mode: 'both' | 'send' | 'receive'): 1;
}

interface TCPServer {
    /**
     * (server) Waits for a remote connection on the server object and returns a client object representing that connection.
     * 
     * @returns If a connection is successfully initiated, a client object is returned.
     * If a timeout condition is met, the method returns nil followed by the error string 'timeout'.
     * Other errors are reported by nil followed by a message describing the error.
     */
    accept(): LuaMultiReturn<[TCPSocket | undefined, string]>;
}

interface TCPServerClient {
    /**
     * Gets options for the TCP object.
     * See `setoption` for description of the option names and values.
     * 
     * @returns The method returns the option value in case of success,
     * or `undefined` followed by an error message otherwise.
     */
    getoption(option: 'keepalive' | 'linger' | 'reuseaddr' | 'tcp-nodelay'): LuaMultiReturn<[number | boolean | undefined, string]>;

    /**
     * Sets options for the TCP object.
     * Options are only needed by low-level or time-critical applications.
     * You should only modify an option if you are sure you need it.
     * 
     * @param option a string with the option name, and value depends on the option being set:
     * 
     * - `'keepalive'`: Setting this option to true enables the periodic transmission of messages on a connected socket. Should the connected party fail to respond to these messages, the connection is considered broken and processes using the socket are notified;
     * - `'linger'`: Controls the action taken when unsent data are queued on a socket and a close is performed. The value is a table with a boolean entry 'on' and a numeric entry for the time interval 'timeout' in seconds. If the 'on' field is set to true, the system will block the process on the close attempt until it is able to transmit the data or until 'timeout' has passed. If 'on' is false and a close is issued, the system will process the close in a manner that allows the process to continue as quickly as possible. I do not advise you to set this to anything other than zero;
     * - `'reuseaddr'`: Setting this option indicates that the rules used in validating addresses supplied in a call to bind should allow reuse of local addresses;
     * - `'tcp-nodelay'`: Setting this option to true disables the Nagle's algorithm for the connection;
     * - `'tcp-keepidle'`: value in seconds for TCP_KEEPIDLE Linux only!!
     * - `'tcp-keepcnt'`: value for TCP_KEEPCNT Linux only!!
     * - `'tcp-keepintvl'`: value for TCP_KEEPINTVL Linux only!!
     * - `'tcp-defer-accept'`: value for TCP_DEFER_ACCEPT Linux only!!
     * - `'tcp-fastopen'`: value for TCP_FASTOPEN Linux only!!
     * - `'tcp-fastopen-connect'`: value for TCP_FASTOPEN_CONNECT Linux only!!
     * - `'ipv6-v6only'`: Setting this option to true restricts an inet6 socket to sending and receiving only IPv6 packets.
     * 
     * @returns 1 in case of success, or `undefined` followed by an error message otherwise.
     */
    setoption(option: 'keepalive' | 'reuseaddr' | 'tcp-nodelay' | 'ipv6-v6only', value: boolean): LuaMultiReturn<[1 | undefined, string]>;
    setoption(option: 'linger', value: { on: true, timeout: number } | { on: false }): LuaMultiReturn<[1 | undefined, string]>;
    setoption(option: 'tcp-keepidle', value: number): LuaMultiReturn<[1 | undefined, string]>;
    setoption(option: 'tcp-keepcnt' | 'tcp-keepintvl' | 'tcp-defer-accept' | 'tcp-fastopen' | 'tcp-fastopen-connect', value: number | boolean): LuaMultiReturn<[1 | undefined, string]>;
    setoption(option: 'keepalive' | 'linger' | 'reuseaddr' | 'tcp-nodelay' | 'tcp-keepidle' | 'tcp-keepcnt' | 'tcp-keepintvl' | 'tcp-defer-accept' | 'tcp-fastopen' | 'tcp-fastopen-connect' | 'ipv6-v6only', value: number | boolean | object): LuaMultiReturn<[1 | undefined, string]>;
}

// TODO: `:dirty` (internal).
// TODO: `:getfd` (internal).
// TODO: `:setfd` (internal).

type TCPSocket = TCPMaster & TCPClient & TCPServer & TCPShared & TCPServerClient;

/**
 * @noResolution
 */
declare module 'socket' {
    /**
     * The current LuaSocket version.
     */
    export const _VERSION: string;

    /**
     * The maximum number of sockets that the `select` function can handle.
     */
    export const _SETSIZE: number;

    /**
     * This constant is set to `true` if the library was compiled with debug support.
     */
    export const _DEBUG: boolean;

    /**
     * Default datagram size used by calls to `receive` and `receivefrom`. (Unless changed in compile time, the value is 8192).
     */
    export const _DATAGRAMSIZE: number;

    /**
     * This function is a shortcut that creates and returns a TCP server object bound to a local address and port, ready to accept client connections.
     * Optionally, user can also specify the backlog argument to the listen method (defaults to 32).
     * 
     * **Note:** The server object returned will have the option `"reuseaddr"` set to true.
     * 
     * @param address Address can be an IP address or a host name.
     * If address is `'*'`, the system binds to all local interfaces using the INADDR_ANY constant or IN6ADDR_ANY_INIT, according to the family.
     * @param port Port must be an integer number in the range [0..64K).
     * If port is `0`, the system automatically chooses an ephemeral port.
     * @param backlog the number of client connections that can be queued waiting for service.
     * If the queue is full and another client attempts connection, the connection is refused.
     */
    export function bind(this: void, address: string, port: number, backlog?: number): LuaMultiReturn<[TCPSocket | undefined, string]>;

    /**
     * Creates and returns an TCP master object.
     * A master object can be transformed into a server object with the method `listen` (after a call to bind) or into a client object with the method `connect`.
     * The only other method supported by a master object is the `close` method.
     * 
     * **Note:** The choice between IPv4 and IPv6 happens during a call to `bind` or `connect`, depending on the address family obtained from the resolver.
     * 
     * **Note:** Before the choice between IPv4 and IPv6 happens, the internal socket object is invalid and therefore `setoption` will fail.
     * 
     * @returns In case of success, a new master object is returned.
     * In case of error, `undefined` is returned, followed by an error message.
     */
    export function tcp(this: void): LuaMultiReturn<[TCPSocket | undefined, string]>;

    /**
     * Creates and returns an IPv4 TCP master object.
     * A master object can be transformed into a server object with the method `listen` (after a call to bind) or into a client object with the method `connect`.
     * The only other method supported by a master object is the `close` method.
     * 
     * @returns In case of success, a new master object is returned.
     * In case of error, `undefined` is returned, followed by an error message.
     */
    export function tcp4(this: void): LuaMultiReturn<[TCPSocket | undefined, string]>;

    /**
     * Creates and returns an IPv6 TCP master object.
     * A master object can be transformed into a server object with the method `listen` (after a call to bind) or into a client object with the method `connect`.
     * The only other method supported by a master object is the `close` method.
     * 
     * **Note:** The TCP object returned will have the option "ipv6-v6only" set to true.
     * 
     * @returns In case of success, a new master object is returned.
     * In case of error, `undefined` is returned, followed by an error message.
     */
    export function tcp6(this: void): LuaMultiReturn<[TCPSocket | undefined, string]>;

    /**
     * Returns the UNIX time in seconds.
     * You should subtract the values returned by this function to get meaningful values.
     */
    export function gettime(this: void): number;

    /**
     * Freezes the program execution during a given amount of time.
     * 
     * @param time the number of seconds to sleep for. If negative, the function returns immediately.
     */
    export function sleep(this: void, time: number): void;

    // TODO: the rest of socket methods.
}