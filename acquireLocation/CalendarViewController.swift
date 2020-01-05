//
//  CalendarViewController.swift
//  acquireLocation
//
//  Created by yasui.haruki on 1/1/20.
//  Copyright © 2020 haruki.yasui. All rights reserved.
//
import UIKit
import CoreLocation
import WebKit

class CalendarViewController: UIViewController, CLLocationManagerDelegate,WKUIDelegate, WKNavigationDelegate {
    
    var locationManager = CLLocationManager()
    let geocoder = CLGeocoder()
    var webView: WKWebView!
    
    override func loadView() {
        super.loadView()
        
        // webview内のテキスト選択禁止
        let disableSelectionScriptString = "document.documentElement.style.webkitUserSelect='none';"
        // webview内の長押しによるメニュー表示禁止
        let disableCalloutScriptString = "document.documentElement.style.webkitTouchCallout='none';"
        
        let disableSelectionScript = WKUserScript(source: disableSelectionScriptString, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        let disableCalloutScript = WKUserScript(source: disableCalloutScriptString, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        
        let controller = WKUserContentController()
        controller.addUserScript(disableSelectionScript)
        controller.addUserScript(disableCalloutScript)
        
        let webConfiguration = WKWebViewConfiguration()
        webConfiguration.userContentController = controller
        webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.uiDelegate = self
        webView.navigationDelegate = self
        
        self.view.addSubview(webView)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        let myURL = URL(string: "http://localhost:3000/events")
        let myRequest = URLRequest(url: myURL!)
        
        webView.load(myRequest)
        webView.allowsBackForwardNavigationGestures = true
        
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        webView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        webView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        webView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
 
        // location manager
        locationManager.requestAlwaysAuthorization()
        let status = CLLocationManager.authorizationStatus()
        if status == .authorizedAlways {
            locationManager.delegate = self
            // 1000m超えたらdidUpdateLocationを呼ぶ
            locationManager.distanceFilter = 1000
            //iOSが位置情報を新たに取得する必要がない状況を自動的に判断
            locationManager.pausesLocationUpdatesAutomatically = false
            // 位置情報の精度
            locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
            
            locationManager.startUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            // 逆ジオコーディング
            self.geocoder.reverseGeocodeLocation(location) { (placemarks, error ) in
                if let placemark = placemarks?.first {
                    //住所
                    let administrativeArea = placemark.administrativeArea == nil ? "" : placemark.administrativeArea!
                    let locality = placemark.locality == nil ? "" : placemark.locality!
                    let subLocality = placemark.subLocality == nil ? "" : placemark.subLocality!
                    let thoroughfare = placemark.thoroughfare == nil ? "" : placemark.thoroughfare!
                    let subThoroughfare = placemark.subThoroughfare == nil ? "" : placemark.subThoroughfare!
                    let placeName = !thoroughfare.contains(subLocality) ? subLocality : thoroughfare
                    
                    let now = Date()
                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                    let nowString = formatter.string(from: now)
                    
                    let latitude: Float = Float(location.coordinate.latitude)
                    let longitude: Float = Float(location.coordinate.longitude)
                    
                    self.postAPI(title: administrativeArea + locality + placeName + subThoroughfare, start: nowString, lat: latitude, long: longitude)
                }
            }
        }
    }
    
    func postAPI(title: String, start: String, lat: Float, long: Float) {
        
        let url = URL(string: "http://localhost:3000/api/v1/events")
        guard let requestUrl = url else { fatalError() }
        
        var request = URLRequest(url: requestUrl)
        request.httpMethod = "POST"
        
        let postString = "title=\(title)&start_date=\(start)&allday=false&latitude=\(lat)&longitude=\(long)"
        
        request.httpBody = postString.data(using: String.Encoding.utf8)
        
        let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let error = error {
                print("Error took place \(error)")
                return
            }
            
            if let data = data, let dataString = String(data: data, encoding: .utf8) {
                print("Response data string:\n \(dataString)")
                DispatchQueue.main.async {
                    self.webView.reload()
                }
            }
        }
        task.resume()
    }
    
    
}
