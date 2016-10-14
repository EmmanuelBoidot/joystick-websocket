//
//  websocket.swift
//  JoyStickDemo
//
//  Created by eboidot on 10/13/16.
//  Copyright © 2016 Foley. All rights reserved.
//

import Foundation

@objc public class MyWebSocket : WebSocket {
    
@objc public func echoTest(){
    var messageNum = 0
    let ws = WebSocket("wss://localhost")
    NSLog("Look, Mom, I'm in a socket");
    let send : ()->() = {
        let msg = "\(++messageNum): \(NSDate().description)"
        print("send: \(msg)")
        ws.send(msg)
        NSLog("Look, Mom, I'm sending");
    }
    ws.event.open = {
        print("opened")
        send()
    }
    ws.event.close = { code, reason, clean in
        print("close")
    }
    ws.event.error = { error in
        print("error \(error)")
    }
    ws.event.message = { message in
        if let text = message as? String {
            print("recv: \(text)")
            if messageNum == 10 {
                ws.close()
            } else {
                send()
            }
        }
    }
}

}