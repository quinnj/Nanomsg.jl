module NN

cd("C:/Users/karbarcca/nanomsg")
dlopen("C:/Users/karbarcca/NNanomsg/NNanomsg/x64/nanomsg.dll")
const libnanomsg = "nanomsg.dll"

const NN_LINGER =  1
const NN_SNDBUF =  2
const NN_RCVBUF =  3
const NN_SNDTIMEO =  4
const NN_RCVTIMEO =  5
const NN_RECONNECT_IVL =  6
const NN_RECONNECT_IVL_MAX =  7
const NN_SNDPRIO =  8
const NN_RCVPRIO =  9
const NN_SNDFD =  10
const NN_RCVFD =  11
const NN_DOMAIN =  12
const NN_PROTOCOL =  13
const NN_IPV4ONLY =  14
const NN_SOCKET_NAME =  15
const NN_DONTWAIT =  1

type NNError <: Exception
    msg::String
end
Base.show(io::IO, thiserr::NNError) = print(io, "NN: ", thiserr.msg)

function jl_nn_error_str()
    errno = ccall((:nn_errno, libnanomsg), Cint, ())
    c_strerror = ccall ((:nn_strerror, libnanomsg), Ptr{Uint8}, (Cint,), errno)
    if c_strerror != C_NULL
        strerror = bytestring(c_strerror)
        return strerror
    else 
        return "Unknown error"
    end
end

## Sockets ##
const AF_SP = 1
const AF_SP_RAW = 2

type Socket
    sock::Cint
    endpoints::Array{Cint,1}

    function Socket(typ::Integer,domain::Integer=AF_SP)
        p = ccall((:nn_socket, libnanomsg), Cint,  (Cint, Cint), domain,typ)
        if p == -1
            throw(NNError(jl_nn_error_str()))
        end
        socket = new(p,Cint[])
        finalizer(socket, close)
        return socket
    end
end

function Base.close(socket::Socket)
    if socket.sock != -1
        rc = ccall((:nn_close, libnanomsg), Cint,  (Cint,), socket.sock)
        if rc == -1
            throw(NNError(jl_nn_error_str()))
        end
        socket.sock = -1
        socket.endpoints = Cint[]
        nothing
    end
end

function Base.bind(socket::Socket, endpoint::String)
    rc = ccall((:nn_bind, libnanomsg), Cint, (Cint, Ptr{Uint8}), socket.sock, endpoint)
    if rc == -1
        throw(NNError(jl_nn_error_str()))
    end
    push!(socket.endpoints,rc)
    nothing
end

function Base.connect(socket::Socket, endpoint::String)
    rc=ccall((:nn_connect, libnanomsg), Cint, (Cint, Ptr{Uint8}), socket.sock, endpoint)
    if rc == -1
        throw(NNError(jl_nn_error_str()))
    end
    push!(socket.endpoints,rc)
    nothing
end

function shutdown(socket::Socket, how::Integer)
    rc=ccall((:nn_shutdown, libnanomsg), Cint, (Cint, Cint), socket.sock, how)
    if rc == -1
        throw(NNError(jl_nn_error_str()))
    end
end

function Base.send(socket::Socket,msg::String,flags::Integer=NN_DONTWAIT)
    rc=ccall((:nn_send, libnanomsg), Cint, (Cint,Ptr{Void},Csize_t,Cint), socket.sock,msg.data,length(msg.data),flags)
    if rc == -1
        throw(NNError(jl_nn_error_str()))
    end
    return rc
end

function Base.recv(socket::Socket,flags=NN_DONTWAIT)
    buf = Array(Ptr{Cchar},1)
    rc=ccall((:nn_recv, libnanomsg), Cint, (Cint,Ptr{Cchar},Csize_t,Cint), socket.sock,pointer(buf),NN_MSG,flags)
    if rc == -1
        throw(NNError(jl_nn_error_str()))
    end
    str = bytestring(buf[1],rc)
    ccall((:nn_freemsg, libnanomsg), Cint, (Ptr{Cchar},), buf[1])
    return str
end

const NN_MSG = oftype(Csize_t,-1)
const NN_PROTO_BUS = 7
const NN_BUS = (NN_PROTO_BUS * 16 + 0)
const NN_INPROC = -1
const NN_IPC = -2
const NN_PROTO_PAIR = 1
const NN_PAIR = (NN_PROTO_PAIR * 16 + 0)
const NN_PROTO_PIPELINE = 5
const NN_PUSH = (NN_PROTO_PIPELINE * 16 + 0)
const NN_PULL = (NN_PROTO_PIPELINE * 16 + 1)
const NN_PROTO_PUBSUB = 2
const NN_PUB = (NN_PROTO_PUBSUB * 16 + 0)
const NN_SUB = (NN_PROTO_PUBSUB * 16 + 1)
const NN_SUB_SUBSCRIBE = 1
const NN_SUB_UNSUBSCRIBE = 2
const NN_PROTO_REQREP = 3
const NN_REQ = (NN_PROTO_REQREP * 16 + 0)
const NN_REP = (NN_PROTO_REQREP * 16 + 1)
const NN_REQ_RESEND_IVL = 1
const NN_PROTO_SURVEY = 6
const NN_SURVEYOR = (NN_PROTO_SURVEY * 16 + 0)
const NN_RESPONDENT = (NN_PROTO_SURVEY * 16 + 1)
const NN_SURVEYOR_DEADLINE = 1
const NN_TCP = -3
const NN_TCP_NODELAY = 1



#=
NN_EXPORT int nn_setsockopt (int s, int level, int option, const void *optval,
    size_t optvallen);
NN_EXPORT int nn_getsockopt (int s, int level, int option, void *optval,
    size_t *optvallen);
NN_EXPORT int nn_bind (int s, const char *addr);
NN_EXPORT int nn_connect (int s, const char *addr);
NN_EXPORT int nn_shutdown (int s, int how);
NN_EXPORT int nn_send (int s, const void *buf, size_t len, int flags);
NN_EXPORT int nn_recv (int s, void *buf, size_t len, int flags);
NN_EXPORT int nn_sendmsg (int s, const struct nn_msghdr *msghdr, int flags);
NN_EXPORT int nn_recvmsg (int s, struct nn_msghdr *msghdr, int flags);

ccall( (:nn_term, libnanomsg), Ptr{Void}, ())
ccall( (:nn_allocmsg, libnanomsg), Ptr{Void}, (Csize_t,Cint), )
ccall( (:nn_freemsg, libnanomsg), Cint, (Ptr{Void},) message_pointer )
=#


# https://github.com/tonysimpson/nanomsg-python
# http://tim.dysinger.net/posts/2013-09-16-getting-started-with-nanomsg.html
# Ref: http://nanomsg.org/v0.3/nanomsg.7.html

end # module