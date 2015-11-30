//
//  XWeakProxy.swift
//  XAnimatedImage
//
//  Created by Khaled Taha on 11/24/15.
//  Copyright © 2015 Khaled Taha. All rights reserved.
//

import Foundation

class XWeakProxy {
    
    weak var target:AnyObject!
    
    // MARK: - Life Cycle
    
    init(weakProxyForObject targetObject:AnyObject) {
        self.target = targetObject
    }
    
    // MARK: - Forwarding Messages
    
    @objc func forwardingTargetForSelector(selector:Selector) -> AnyObject {
        // Keep it lightweight: access the ivar directly
        return target
    }
    
}

