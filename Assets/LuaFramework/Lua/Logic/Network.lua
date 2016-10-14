
require "Common/define"
require "Common/protocal"
require "Common/functions"
Event = require 'events'

require "3rd/pblua/login_pb"
require "3rd/pbc/protobuf"

local sproto = require "3rd/sproto/sproto"
local core = require "sproto.core"
local print_r = require "3rd/sproto/print_r"

Network = {};
local this = Network;

local transform;
local gameObject;
local islogging = false;

---------------------------------------
local login_proto = require "proto.login_proto"
local host = sproto.new (login_proto.s2c):host "package"
local request = host:attach (sproto.new (login_proto.c2s))

local function send_message (msg)
    logWarn(string.format("--- msg:%s, len:%d", msg, string.len(msg)))
    -- local packmsg = string.pack (">s2", msg)
    -- print ("^^^C>>S send_message, len:"..#packmsg..", type:"..type(packmsg))
    -- network.send(packmsg)

    local buffer = ByteBuffer.New();
    -- buffer:WriteShort(Protocal.Message);
    -- buffer:WriteByte(ProtocalType.SPROTO);
    buffer:WriteBuffer(msg);
    networkMgr:SendMessage(buffer);
end

local session = {}
local session_id = 0
local function send_request (name, args)
    logWarn(string.format("--- 【C>>S】, send_request:%s", name))
    session_id = session_id + 1
    local str = request (name, args, session_id)
    send_message (str)
    session[session_id] = { name = name, args = args }
end

local function handle_response (id, args)
    local s = assert (session[id])
    session[id] = nil
    print ("--- 【S>>C】, response from server:", s.name)

    if true then
        return
    end

    local s = assert (session[id])
    session[id] = nil
    local f = RESPONSE[s.name]

    print ("--- 【S>>C】, response from server:", s.name)
    -- dump (args)

    if f then
        f (s.args, args)
    else
        print("--- handle_response, not found func:"..s.name)
    end
end

local function handle_message (t, ...)
    if t == "REQUEST" then
        -- handle_request (...)
    else
        handle_response (...)
    end
end
---------------------------------------

function Network.Start() 
    logWarn("Network.Start!!");
    Event.AddListener(Protocal.Connect, this.OnConnect); 
    Event.AddListener(Protocal.Message, this.OnMessage); 
    Event.AddListener(Protocal.Exception, this.OnException); 
    Event.AddListener(Protocal.Disconnect, this.OnDisconnect); 

end

--Socket消息--
function Network.OnSocket(key, data)
    Event.Brocast(tostring(key), data);
end

--当连接建立时--
function Network.OnConnect() 
    logWarn("--- \n Game Server connected!!");

    --- test
    local ret = { challenge = "hello", password = "world"}
    send_request ("auth", ret)
end

--异常断线--
function Network.OnException() 
    islogging = false; 
    NetManager:SendConnect();
   	logError("OnException------->>>>");
end

--连接中断，或者被踢掉--
function Network.OnDisconnect() 
    islogging = false; 
    logError("OnDisconnect------->>>>");
end

--登录返回--
function Network.OnMessage(buffer) 
	if TestProtoType == ProtocalType.BINARY then
		this.TestLoginBinary(buffer);
	end
	if TestProtoType == ProtocalType.PB_LUA then
		this.TestLoginPblua(buffer);
	end
	if TestProtoType == ProtocalType.PBC then
		this.TestLoginPbc(buffer);
	end
	if TestProtoType == ProtocalType.SPROTO then
		this.TestLoginSproto(buffer);
	end
	----------------------------------------------------
    local ctrl = CtrlManager.GetCtrl(CtrlNames.Message);
    if ctrl ~= nil then
        ctrl:Awake();
    end
    logWarn('OnMessage-------->>>');
end

--二进制登录--
function Network.TestLoginBinary(buffer)
	local protocal = buffer:ReadByte();
	local str = buffer:ReadString();
	log('TestLoginBinary: protocal:>'..protocal..' str:>'..str);
end

--PBLUA登录--
function Network.TestLoginPblua(buffer)
	local protocal = buffer:ReadByte();
	local data = buffer:ReadBuffer();

    local msg = login_pb.LoginResponse();
    msg:ParseFromString(data);
	log('TestLoginPblua: protocal:>'..protocal..' msg:>'..msg.id);
end

--PBC登录--
function Network.TestLoginPbc(buffer)
	local protocal = buffer:ReadByte();
	local data = buffer:ReadBuffer();

    local path = Util.DataPath.."lua/3rd/pbc/addressbook.pb";

    local addr = io.open(path, "rb")
    local buffer = addr:read "*a"
    addr:close()
    protobuf.register(buffer)
    local decode = protobuf.decode("tutorial.Person" , data)

    print(decode.name)
    print(decode.id)
    for _,v in ipairs(decode.phone) do
        print("\t"..v.number, v.type)
    end
	log('TestLoginPbc: protocal:>'..protocal);
end

--SPROTO登录--
function Network.TestLoginSproto(buffer)
    local protocal = buffer:ReadByte();
    local code = buffer:ReadBuffer();

    handle_message(host:dispatch (code))

    if true then
        return
    end



    local sp = sproto.parse [[
    .Person {
        name 0 : string
        id 1 : integer
        email 2 : string

        .PhoneNumber {
            number 0 : string
            type 1 : integer
        }

        phone 3 : *PhoneNumber
    }

    .AddressBook {
        person 0 : *Person(id)
        others 1 : *Person
    }
    ]]
    local addr = sp:decode("AddressBook", code)
    print_r(addr)
	log('TestLoginSproto: protocal:>'..protocal);
end

--卸载网络监听--
function Network.Unload()
    Event.RemoveListener(Protocal.Connect);
    Event.RemoveListener(Protocal.Message);
    Event.RemoveListener(Protocal.Exception);
    Event.RemoveListener(Protocal.Disconnect);
    logWarn('Unload Network...');
end