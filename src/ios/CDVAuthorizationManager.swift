//
//  File.swift
//  HelloCordova
//
//  Created by Vitaly Meytin on 10/21/15.
//
//

import Foundation
import IMFCore

enum PersistencePolicy: String {
    case PersistencePolicyAlways = "ALWAYS"
    case PersistencePolicyNever = "NEVER"
}

@objc(CDVAuthorizationManager) class CDVAuthorizationManager : CDVPlugin {
    
    func obtainAuthorizationHeader(command: CDVInvokedUrlCommand) {
        let authManager = IMFAuthorizationManager.sharedInstance();
        
        self.commandDelegate!.runInBackground({
        
            authManager.obtainAuthorizationHeaderWithCompletionHandler { (response: IMFResponse!, error: NSError!) -> Void in
                var responseString: String?
                
                do {
                    if (error != nil) {
                        // process the error
                        try responseString = self.packResponse(response, error: error)
                        let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAsString: responseString)
                        self.commandDelegate!.sendPluginResult(pluginResult, callbackId:command.callbackId)
                    } else {
                        // process success
                        try responseString = self.packResponse(response)
                        let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAsString: responseString)
                        self.commandDelegate!.sendPluginResult(pluginResult, callbackId:command.callbackId)
                    }
                } catch {
                    let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAsString: CustomErrorMessages.errorParsingJSONResponse)
                    self.commandDelegate!.sendPluginResult(pluginResult, callbackId:command.callbackId)
                }
            }
            
        });
        
    }
    
    func isAuthorizationRequired(command: CDVInvokedUrlCommand) {
        
        self.commandDelegate!.runInBackground({
            
            do {
                let authManager = IMFAuthorizationManager.sharedInstance()
                let params = try self.unpackIsAuthorizationRequiredParams(command);
                
                let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAsBool:authManager.isAuthorizationRequired(params.statusCode, authorizationHeaderValue: params.authorizationHeaderValue))
                
                self.commandDelegate!.sendPluginResult(pluginResult, callbackId:command.callbackId)
            } catch {
                let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAsString: "Invalid parameters passed to isAuthorizationRequired method")
                self.commandDelegate!.sendPluginResult(pluginResult, callbackId:command.callbackId)
            }
        })
    }
    
    func clearAuthorizationData(command: CDVInvokedUrlCommand) {
        self.commandDelegate!.runInBackground({
            let authManager = IMFAuthorizationManager.sharedInstance()
            authManager.clearAuthorizationData()
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK)
            self.commandDelegate!.sendPluginResult(pluginResult, callbackId:command.callbackId)
        })
    }
    
    func getCachedAuthorizationHeader(command: CDVInvokedUrlCommand) {
        self.commandDelegate!.runInBackground({
            let authManager = IMFAuthorizationManager.sharedInstance()
            
            if let authHeader: String = authManager.cachedAuthorizationHeader {
                let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAsString:authHeader)
                self.commandDelegate!.sendPluginResult(pluginResult, callbackId:command.callbackId)
            } else {
                let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAsString: CustomErrorMessages.noCachedAuthorizationHeader)
                self.commandDelegate!.sendPluginResult(pluginResult, callbackId:command.callbackId)
            }
        })
    }
    
    func getUserIdentity(command: CDVInvokedUrlCommand) {
        self.commandDelegate!.runInBackground({
            let authManager = IMFAuthorizationManager.sharedInstance()
            var pluginResult: CDVPluginResult? = nil
    
            do {
                let userIdentity: String = try self.stringifyResponse(authManager.userIdentity)
                pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAsString:userIdentity)
            } catch {
                pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAsString:CustomErrorMessages.errorObtainUserIdentity)
            }
            
            self.commandDelegate!.sendPluginResult(pluginResult, callbackId:command.callbackId)
        })
    }
    
    func getAppIdentity(command: CDVInvokedUrlCommand) {
        self.commandDelegate!.runInBackground({
            let authManager = IMFAuthorizationManager.sharedInstance()
            var pluginResult: CDVPluginResult? = nil
            
            do {
                let appIdentity: String = try self.stringifyResponse(authManager.appIdentity)
                pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAsString:appIdentity)
            } catch {
                pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAsString:CustomErrorMessages.errorObtainAppIdentity)
            }
            
            self.commandDelegate!.sendPluginResult(pluginResult, callbackId:command.callbackId)
        })
    }
    
    func getDeviceIdentity(command: CDVInvokedUrlCommand) {
        self.commandDelegate!.runInBackground({
            let authManager = IMFAuthorizationManager.sharedInstance()
            var pluginResult: CDVPluginResult? = nil
            
            do {
                let deviceIdentity: String = try self.stringifyResponse(authManager.deviceIdentity)
                pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAsString:deviceIdentity)
            } catch {
                pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAsString:CustomErrorMessages.errorObtainDeviceIdentity)
            }
            
            self.commandDelegate!.sendPluginResult(pluginResult, callbackId:command.callbackId)
        })
    }
    
    func getAuthorizationPersistencePolicy(command: CDVInvokedUrlCommand) {
        self.commandDelegate!.runInBackground({
            let authManager = IMFAuthorizationManager.sharedInstance()
            let policy: IMFAuthorizationPerisistencePolicy = authManager.getAuthorizationPersistensePolicy()
            var pluginResult: CDVPluginResult? = nil
            
            switch policy {
            case IMFAuthorizationPerisistencePolicy.Always:
                pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAsString:PersistencePolicy.PersistencePolicyAlways.rawValue)
            case IMFAuthorizationPerisistencePolicy.Never:
                pluginResult = CDVPluginResult(status: CDVCommandStatus_OK, messageAsString:PersistencePolicy.PersistencePolicyNever.rawValue)
            default:
                pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAsString:CustomErrorMessages.invalidPolicyType)
            }
            
            self.commandDelegate!.sendPluginResult(pluginResult, callbackId:command.callbackId)
        })
    }
    
    func setAuthorizationPersistencePolicy(command: CDVInvokedUrlCommand) {
        self.commandDelegate!.runInBackground({
            let authManager = IMFAuthorizationManager.sharedInstance()
            guard let policy: String = command.arguments[0] as? String else {
                let pluginResult = CDVPluginResult(status: CDVCommandStatus_ERROR, messageAsString:CustomErrorMessages.invalidPolicySpecified)
                self.commandDelegate!.sendPluginResult(pluginResult, callbackId:command.callbackId)
                return
            }
            
            switch policy {
            case PersistencePolicy.PersistencePolicyAlways.rawValue:
                authManager.setAuthorizationPersistencePolicy(IMFAuthorizationPerisistencePolicy.Always)
            case PersistencePolicy.PersistencePolicyNever.rawValue:
                authManager.setAuthorizationPersistencePolicy(IMFAuthorizationPerisistencePolicy.Never)
            default:
                authManager.setAuthorizationPersistencePolicy(IMFAuthorizationPerisistencePolicy.Never)
            }
            
            let pluginResult = CDVPluginResult(status: CDVCommandStatus_OK)
            self.commandDelegate!.sendPluginResult(pluginResult, callbackId:command.callbackId)
        })
    }
    
    func unpackIsAuthorizationRequiredParams(command: CDVInvokedUrlCommand) throws -> (statusCode: Int32, authorizationHeaderValue: String) {
        if (command.arguments.count < 2) {
            throw CustomErrors.InvalidParameterCount(expected: 2, actual: command.arguments.count)
        }
        
        guard let param0 = command.argumentAtIndex(0) as? NSNumber else {
            throw CustomErrors.InvalidParameterType(expected: "NSNumber", actual: command.argumentAtIndex(1))
        }
        
        guard let param1: NSString = command.argumentAtIndex(1) as? NSString else {
            throw CustomErrors.InvalidParameterType(expected: "String", actual: command.argumentAtIndex(1))
        }
        
        return (statusCode: param0.intValue, authorizationHeaderValue: param1 as String)
    }
    
    func packResponse(response: IMFResponse!,error:NSError?=nil) throws -> String {
        let jsonResponse:NSMutableDictionary = [:]
        var responseString: NSString = ""
        
        if error != nil {
            jsonResponse.setObject(Int((error!.code)), forKey: "errorCode")
            jsonResponse.setObject((error!.localizedDescription), forKey: "errorDescription")
            jsonResponse.setObject((error!.userInfo), forKey: "userInfo")
        }
        else {
            jsonResponse.setObject(Int((0)), forKey: "errorCode")
            jsonResponse.setObject("", forKey: "errorDescription")
        }
        
        if (response == nil)
        {
            jsonResponse.setObject("", forKey: "responseText")
            jsonResponse.setObject([], forKey:"headers")
            jsonResponse.setObject(Int(0), forKey:"status")
        }
        else {
            let responseText: String = (response.responseText != nil)    ? response.responseText : ""
            jsonResponse.setObject(responseText, forKey: "responseText")
            
            if response.responseHeaders != nil {
                jsonResponse.setObject(response.responseHeaders, forKey:"headers")
            }
            else {
                jsonResponse.setObject([], forKey:"headers")
            }
            
            jsonResponse.setObject(Int(response.httpStatus), forKey:"status")
        }
        
        responseString = try self.stringifyResponse(jsonResponse);
        return responseString as String
    }
    
    func stringifyResponse(value: AnyObject,prettyPrinted:Bool = false) throws -> String {
        let options = prettyPrinted ? NSJSONWritingOptions.PrettyPrinted : NSJSONWritingOptions(rawValue: 0)
        var jsonString : String? = ""
        
        if NSJSONSerialization.isValidJSONObject(value) {
            let data = try NSJSONSerialization.dataWithJSONObject(value, options: options)
            jsonString = NSString(data: data, encoding: NSUTF8StringEncoding) as String?
        }
        return jsonString!
    }
    
}