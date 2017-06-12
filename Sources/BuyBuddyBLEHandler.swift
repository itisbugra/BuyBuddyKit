//
//  BuyBuddyBleHandler.swift
//  BuyBuddyKit
//
//  Created by Emir Çiftçioğlu on 11/05/2017.
//
//

import Foundation
import CoreBluetooth
import UIKit


let BLEServiceChangedStatusNotification = "kBLEServiceChangedStatusNotification"
let BLEServiceConnectionNotification = "didConnectToDevice"



public protocol BluetoothConnectionDelegate{
    func connectionComplete(hitagId:String,validateId:Int)
    func devicePasswordSent(dataSent:Bool,hitagId:String,responseCode:Int)
    func connectionTimeOut(hitagId:String)
    func disconnectionComplete(hitagId:String)
}

class BuyBuddyBLEHandler: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate, BuyBuddyBLEPeripheralDelegate{
    
    var singleBuy      : Bool = false
    var connectionMode : ConnectionMode = ConnectionMode.uart
    var delegate       : BuyBuddyBLEPeripheralDelegate!
    var uartConnect    : BuyBuddyBLEPeripheral?
    var viewDelegate   : BluetoothConnectionDelegate?
    var centralManager : CBCentralManager!
    var currentDevice  : CBPeripheral!
    var connected      : Bool = false
    var timeOutCheck:Bool = false
    private let connectionTimeOutIntvl:TimeInterval = 5
    private var connectionTimer:Timer?
    private var initTimer:Timer?

    var hitagsPasswords  : [String : String] = [:]
    var hitagsTried      : [String : Int] = [:]
    var currentHitag     : String!
    var devicesToOpen    : [String] = []
    var openedDevices    : [String] = []
    var deviceWithError  : [String] = []
    var initHitagId      :  String?
    var validationCode   : Int = 0
    
    override init() {
        super.init()
        
    }
    
    func sendPassword(password: String) -> Bool{
        if connected {
            self.uartConnect?.writeHexString(password)
            return true
        }
        return false
    }
    
    func disconnectFromHitag() -> Bool{
        if connected {
            if currentDevice != nil {
                self.centralManager.cancelPeripheralConnection(self.currentDevice)
                return true
            }
        }
        return false
    }
    
    init(hitagId: String,viewController:BluetoothConnectionDelegate) {
        super.init()
        viewDelegate = viewController
        devicesToOpen.append(hitagId)
        initHitagId = hitagId
        //hitagsTried[hitagId] = 0
        centralManager = CBCentralManager(delegate: self, queue: nil)
        initTimer = Timer.scheduledTimer(timeInterval: connectionTimeOutIntvl, target: self, selector:#selector(BuyBuddyBLEHandler.connectionTimedOut) , userInfo: nil, repeats: false)
    }
    
    func decideIfNextProduct(){
        if(devicesToOpen.count != 0){
        
            let options : [String : AnyObject] = NSDictionary(object: NSNumber(value: true as Bool), forKey: CBCentralManagerScanOptionAllowDuplicatesKey as NSCopying) as! [String : AnyObject]
            centralManager.scanForPeripherals(withServices: nil, options: options)
        }
    }
    
    func connectionFinalized() {
        
        connected = true
        initTimer?.invalidate()
        connectionTimer = Timer.scheduledTimer(timeInterval: connectionTimeOutIntvl, target: self, selector:#selector(BuyBuddyBLEHandler.connectionTimedOut) , userInfo: nil, repeats: false)
    }
    
    func connectionTimedOut() {
        connectionTimer?.invalidate()
        if(connected){
        self.centralManager.cancelPeripheralConnection(currentDevice)
        centralManager.stopScan()
        viewDelegate?.connectionTimeOut(hitagId: initHitagId!)
        }else{
            if(initHitagId != nil){
        centralManager.stopScan()
        viewDelegate?.connectionTimeOut(hitagId: initHitagId!)
                //viewDelegate?.devicePasswordSent(dataSent: false, hitagId: initHitagId!, responseCode: -2000)
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        viewDelegate?.disconnectionComplete(hitagId: currentHitag)
    }
    /*func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        connected=false
        if(timeOutCheck){
            let tried = hitagsTried[currentHitag]
            if (tried != nil && tried! < 3){
                timeOutCheck = false
                self.connectDevice(currentDevice)
            }
        }
    }*/
    func uartDidEncounterError(_ error: NSString) {
        
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        
        
        if #available(iOS 10.0, *) {
            if central.state ==  CBManagerState.poweredOn {
                
                let options : [String : AnyObject] = NSDictionary(object: NSNumber(value: true as Bool), forKey: CBCentralManagerScanOptionAllowDuplicatesKey as NSCopying) as! [String : AnyObject]
                central.scanForPeripherals(withServices: nil, options: options)
                
            }
            else {
                print("Bluetooth switched off or not initialized")
            }
        } else {
            if central.state.rawValue == CBCentralManagerState.poweredOn.rawValue {
                
                let options : [String : AnyObject] = NSDictionary(object: NSNumber(value: true as Bool), forKey: CBCentralManagerScanOptionAllowDuplicatesKey as NSCopying) as! [String : AnyObject]
                central.scanForPeripherals(withServices: nil, options: options)
            }
            else {
                print("Bluetooth switched off or not initialized")
            }
        }
    }
    

    func didReceiveData(_ newData: Data) {
        
        switch newData {
        case HitagResponse.Starting:
            connectionTimer?.invalidate()
            connectionTimer = Timer.scheduledTimer(timeInterval: connectionTimeOutIntvl, target: self, selector:#selector(BuyBuddyBLEHandler.connectionTimedOut) , userInfo: nil, repeats: false)

            print("HitagResponse : Starting");
            
        case HitagResponse.ValidationSuccess:
            print("HitagResponse : ValidationSuccess")
            
        case HitagResponse.Error:
            print("HitagResponse : Error");
            centralManager.stopScan()
            viewDelegate?.devicePasswordSent(dataSent: false, hitagId: currentHitag, responseCode: 0)
            
            
        case HitagResponse.Success:
            print("HitagResponse : Success");
            connectionTimer?.invalidate()
            centralManager.stopScan()
            viewDelegate?.devicePasswordSent(dataSent: true, hitagId: currentHitag, responseCode: 1)
            
        case HitagResponse.Unknown:
            print("HitagResponse : Unknown")
            centralManager.stopScan()
            viewDelegate?.devicePasswordSent(dataSent: false, hitagId: currentHitag, responseCode: -1000)
            
        default:
            centralManager.stopScan()
            viewDelegate?.devicePasswordSent(dataSent: false, hitagId: currentHitag, responseCode: -1000)
            return
        }
    }

    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        if let list = advertisementData["kCBAdvDataServiceUUIDs"] as? [AnyObject],
            (list.contains { ($0 as? CBUUID)!.uuidString.contains("0000BEEF-6275-7962-7564-6479666565") } && advertisementData["kCBAdvDataManufacturerData"] != nil) {
            
            let manufactererData = advertisementData["kCBAdvDataManufacturerData"] as? Data
            let hitagDataByte = [UInt8](manufactererData!)
            var hitagIdArray: [UInt8] = [UInt8]()
            
            if hitagDataByte.count < 10{
                return
            }
             
            for index in 2..<12 {
                hitagIdArray.append(hitagDataByte[index])
            }
            
            var validationArray: [UInt8] = []
            validationArray.append(hitagDataByte[12])
            validationArray.append(hitagDataByte[13])
            
            
      
            if let hitagDataString = NSString(data: Data(hitagIdArray), encoding: String.Encoding.utf8.rawValue){
                if devicesToOpen.contains(hitagDataString as String) {
                    currentHitag = hitagDataString as String
                    centralManager.stopScan()
                    if let value = UInt16(Utilities.byteArrayToHexString(validationArray), radix: 16) {
                        validationCode = Int(value)
                    }else{
                        validationCode = 0
                    }
                    connectDevice(peripheral)
                }
            }
        }
    }
    
    func connectDevice(_ peripheral: CBPeripheral){
        
        if centralManager.isScanning {
            self.centralManager.stopScan()
        }
        self.currentDevice = peripheral
        self.currentDevice.delegate = self
        self.centralManager.connect(peripheral, options: nil)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        //let increment: Int = hitagsTried[currentHitag]! + 1
        //hitagsTried.updateValue(increment, forKey: currentHitag)
        viewDelegate?.connectionComplete(hitagId: currentHitag, validateId: validationCode)
        uartConnect = BuyBuddyBLEPeripheral(peripheral: self.currentDevice, delegate: self)
        uartConnect?.didConnect(connectionMode)
    }
}