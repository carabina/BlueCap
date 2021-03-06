//
//  Connector.swift
//  BlueCap
//
//  Created by Troy Stribling on 6/14/14.
//  Copyright (c) 2014 gnos.us. All rights reserved.
//

import Foundation

public class Connectorator {

    private var timeoutCount    = 0
    private var disconnectCount = 0
    
    public var timeout          : ((peripheral:Peripheral) -> Void)?
    public var disconnect       : ((peripheral:Peripheral) -> Void)?
    public var forceDisconnect  : ((peripheral:Peripheral) -> Void)?
    public var connect          : ((peripheral:Peripheral) -> Void)?
    public var failedConnect    : ((peripheral:Peripheral, error:NSError?) -> Void)?
    public var giveUp           : ((peripheral:Peripheral) -> Void)?

    public var timeoutRetries           = -1
    public var disconnectRetries        = -1
    public var connectionTimeout        = 10.0
    public var characteristicTimeout    = 10.0

    public init () {
    }
    
    public init(initializer:((connectorator:Connectorator) -> Void)?) {
        if let initializer = initializer {
            initializer(connectorator:self)
        }
    }
    
    public func onTimeout(timeout:(peripheral:Peripheral) -> Void) -> Self {
        self.timeout = timeout
        return self
    }

    public func onDisconnect(disconnect:(peripheral:Peripheral) -> Void) -> Self {
        self.disconnect = disconnect
        return self
    }

    public func onForceDisconnect(forceDisconnect:(peripheral:Peripheral) -> Void) -> Self {
        self.forceDisconnect = forceDisconnect
        return self
    }
    
    public func onConnect(connect:(peripheral:Peripheral) -> Void) -> Self {
        self.connect = connect
        return self
    }
    
    public func onFailedConnect(failedConnect:(peripheral:Peripheral, error:NSError?) -> Void) -> Self {
        self.failedConnect = failedConnect
        return self
    }
    
    public func onGiveUp(giveUp:(peripheral:Peripheral) -> Void) -> Self {
        self.giveUp = giveUp
        return self
    }
    
    // INTERNAL
    internal func didTimeout(peripheral:Peripheral) {
        Logger.debug("Connectorator#didTimeout")
        if self.timeoutRetries > 0 {
            if self.timeoutCount < self.timeoutRetries {
                self.callDidTimeout(peripheral)
                ++self.timeoutCount
            } else {
                self.callDidGiveUp(peripheral)
                self.timeoutCount = 0
            }
        } else {
            self.callDidTimeout(peripheral)
        }
    }

    internal func didDisconnect(peripheral:Peripheral) {
        Logger.debug("Connectorator#didDisconnect")
        if self.disconnectRetries > 0 {
            if self.disconnectCount < self.disconnectRetries {
                ++self.disconnectCount
                self.callDidDisconnect(peripheral)
            } else {
                self.disconnectCount = 0
                self.callDidGiveUp(peripheral)
            }
        } else {
            self.callDidDisconnect(peripheral)
        }
    }
    
    internal func didForceDisconnect(peripheral:Peripheral) {
        Logger.debug("Connectorator#didForceDisconnect")
        if let forcedDisconnect = self.forceDisconnect {
            CentralManager.asyncCallback {forcedDisconnect(peripheral:peripheral)}
        }
    }
    
    internal func didConnect(peripheral:Peripheral) {
        Logger.debug("Connectorator#didConnect")
        if let connect = self.connect {
            self.timeoutCount = 0
            CentralManager.asyncCallback {connect(peripheral:peripheral)}
        }
    }
    
    internal func didFailConnect(peripheral:Peripheral, error:NSError?) {
        Logger.debug("Connectorator#didFailConnect")
        if let failedConnect = self.failedConnect {
            CentralManager.asyncCallback {failedConnect(peripheral:peripheral, error:error)}
        }
    }
    
    internal func callDidTimeout(peripheral:Peripheral) {
        if let timeout = self.timeout {
            CentralManager.asyncCallback {timeout(peripheral:peripheral)}
        } else {
            peripheral.reconnect()
        }
    }
    
    internal func callDidDisconnect(peripheral:Peripheral) {
        if let disconnect = self.disconnect {
            CentralManager.asyncCallback {disconnect(peripheral:peripheral)}
        } else {
            peripheral.reconnect()
        }
    }
    
    internal func callDidGiveUp(peripheral:Peripheral) {
        if let giveUp = self.giveUp {
            CentralManager.asyncCallback {giveUp(peripheral:peripheral)}
        }
    }
}