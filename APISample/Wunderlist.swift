//
//  Wunderlist.swift
//  APISample
//
//  Created by rayc5 on 2015/06/02.
//  Copyright (c) 2015年 rayc5. All rights reserved.
//

import Foundation
import UIKit

protocol WunderlistAuthDelegate {
     func didAuthrization(success: Bool)
}

// MARK: Wunderlist API

class Wunderlist
{
    // MARK: properties
    var delegate: WunderlistAuthDelegate?
    var isLogin = false
    
    private static let accessTokenPath = "access_token"
    
    private struct Info {
        static let client_id = "your_client_id"
        static let client_secret = "your_client_secret"
        static let redirect_uri = "https://localhost/"
        static let state = "state"
        
        static var code: String? = nil
        static var access_token: String? = nil {
            didSet {
                let ud = NSUserDefaults.standardUserDefaults()
                ud.setValue(access_token, forKey: Wunderlist.accessTokenPath)
            }
        }
    }
    
    private let redirectHost = "localhost"
    
    // MARK: singleton
    
    class var sharedInstance : Wunderlist {
        struct Static {
            static let instance : Wunderlist = Wunderlist()
        }
        return Static.instance
    }
    
    // MARK: initialize
    
    init() {
        // check if it has access_token
        let ud = NSUserDefaults.standardUserDefaults()
        if let access_token = ud.objectForKey(Wunderlist.accessTokenPath) as? String {
            isLogin = true
            Info.access_token = access_token
        }
    }
    
    // MARK: authorization
    
    private let authRequestURL = "https://www.wunderlist.com/oauth/authorize?client_id=\(Info.client_id)&redirect_uri=\(Info.redirect_uri)&state=\(Info.state)"

    func getAuthController(delegate: WunderlistAuthDelegate) -> UIViewController? {
        // login check
        if !isLogin {
            // send request
            let vc = WunderlistAuthController()
            self.delegate = delegate
            return vc
        }
        return nil
    }
    
    private let accessTokenRequestURL = "https://www.wunderlist.com/oauth/access_token"
    private var accessTokenHTTPBody: String? {
        get {
            if let code = Info.code {
                return "client_id=\(Info.client_id)&client_secret=\(Info.client_secret)&code=\(code)"
            }
            return nil
        }
    }
    
    private func getAccessToken(code: String) {
        Info.code = code
        let request = NSMutableURLRequest(URL: NSURL(string: accessTokenRequestURL)!)
        request.HTTPMethod = "POST"
        var bodyData = accessTokenHTTPBody!
        request.HTTPBody = bodyData.dataUsingEncoding(NSUTF8StringEncoding);
        NSURLConnection.sendAsynchronousRequest(request,
            queue: NSOperationQueue.mainQueue(),
            completionHandler: {
                (res, data, error) in
                let dataString = NSString(data: data, encoding: NSUTF8StringEncoding)
                let jsonResult = NSJSONSerialization.JSONObjectWithData(data,
                    options: NSJSONReadingOptions.MutableContainers,
                    error: nil) as! NSDictionary
                Info.access_token = jsonResult["access_token"] as? String
                self.delegate?.didAuthrization(true)
        })
    }
    
    // MARK: get
    
    private let endpoint = "https://a.wunderlist.com/api/v1/"
    
    enum Type: String {
        case List = "lists"
        case Task = "tasks"
    }
    
    func get(type: Type, completionFunc:(NSArray?) -> Void) {
        get(type, parameters: nil, completionFunc: completionFunc)
    }
    
    func get(type: Type, parameters: [String:String]?, completionFunc:(NSArray?) -> Void) {
        if let request = getRequest(type, parameters: parameters) {
            sendRequest(request) { (_, data, _) in
                let json = self.getJSONAsArray(data)
                completionFunc(json)
            }
        }
    }
    
    // MARK: helper
    
    func getRequest(type: Type, parameters: [String:String]?) -> NSMutableURLRequest? {
        var urlStr = endpoint + type.rawValue
        if let param = parameters {
            urlStr += "?"
            for (key, value) in param {
                urlStr += "\(key)=\(value)&"
            }
            urlStr = dropLast(urlStr)
        }
        return getRequest(urlStr)
    }
    
    private func getRequest(endpoint: String) -> NSMutableURLRequest? {
        if let url = NSURL(string: endpoint) {
            let request = NSMutableURLRequest(URL: url)
            request.addValue(Info.access_token, forHTTPHeaderField: "X-Access-Token")
            request.addValue(Info.client_id, forHTTPHeaderField: "X-Client-ID")
            return request
        }
        return nil
    }
    
    private func sendRequest(request: NSMutableURLRequest, completion:(NSURLResponse!, NSData!, NSError!) -> Void) {
        NSURLConnection.sendAsynchronousRequest(request,
            queue: NSOperationQueue.mainQueue(),
            completionHandler: completion)
    }
    
    private func getJSONAsArray(data: NSData) -> NSArray? {
        let dataString = NSString(data: data, encoding: NSUTF8StringEncoding)
        let jsonResult: AnyObject? = NSJSONSerialization.JSONObjectWithData(data,
            options: NSJSONReadingOptions.MutableContainers,
            error: nil)
        if jsonResult is NSArray {
            return jsonResult as? NSArray
        }
        return nil
    }
}


// MARK: UIViewController for authorization

class WunderlistAuthController: UIViewController, UIWebViewDelegate {
    
    // MARK: properties
    
    private var webView: UIWebView?
    
    // MARK: UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()

        webView = UIWebView(frame: CGRectMake(0, 0, UIScreen.mainScreen().bounds.width, UIScreen.mainScreen().bounds.height))
        webView!.delegate = self
        view.addSubview(webView!)
        if let url = NSURL(string: Wunderlist.sharedInstance.authRequestURL) {
            webView!.loadRequest(NSURLRequest(URL: url))
        }
    }
    
    // MARK: UIWebViewDelegate
    
    func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        if let url = request.URL {
            if url.host == Wunderlist.sharedInstance.redirectHost {
                // get code
                // you should check received state is the same as state you send
                let query = url.query!
                // query forms "state=state&code=<code>"
                let code = query.substringFromIndex(advance(query.startIndex, 17))
                println("query: \(query),code: \(code)")
                Wunderlist.sharedInstance.getAccessToken(code)
                return true
            }
        }
        return true
    }
}