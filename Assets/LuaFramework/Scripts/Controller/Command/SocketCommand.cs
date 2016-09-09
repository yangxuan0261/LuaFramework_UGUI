using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using LuaFramework;

public class SocketCommand : ControllerCommand {

    public override void Execute(IMessage message) {
        object data = message.Body;
        if (data == null) return;
        KeyValuePair<int, ByteBuffer> buffer = (KeyValuePair<int, ByteBuffer>)data;
        switch (buffer.Key) {  //key:消息号
            default: Util.CallMethod("Network", "OnSocket", buffer.Key, buffer.Value); break;
        }
	}
}
