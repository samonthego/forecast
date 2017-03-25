//
//  ViewController.swift
//  forecast
//
//  Created by Samuel MCDONALD on 3/18/17.
//  Copyright © 2017 Samuel MCDONALD. All rights reserved.
//

import UIKit
import MapKit

enum myError: Error {
    case noPlistFile
    case cannotReadFile
}


class ViewController: UIViewController {

    
    @IBOutlet var weatherSearchBar :UISearchBar!
    @IBOutlet var temperatureLabel :UILabel!
    @IBOutlet var weatherImageView :UIImageView!
    
    
    let hostName = "https://api.darksky.net/"
    var reachability : Reachability?
    var locationMgr = CLLocationManager()
    var weatherText = ""
    var iconImage = "weathercock.png"
    var skeltonKey = ""
    var long = 0.0
    var lat  = 0.0
    var myUrlString:String = ""
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupReachability(hostName: hostName)
        startReachability()
        skeltonKey = getSkeltonKey()
        print ("Skelton Key is \(skeltonKey)")
        setupLocationMonitoring()
        
        lat  = (locationMgr.location?.coordinate.latitude)!
        long = (locationMgr.location?.coordinate.longitude)!
        myUrlString = hostName + "forecast/" + skeltonKey + "/" + String(lat) + "," + String(long)
        print("  lat & long  \(lat) \(long)")
        getFile(myUrlString: myUrlString)        
       
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
      
    }
    
    
//!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    
    //MARK: - Interactivity Methods
    
    @IBAction func weatherAtAddress(sender: UIButton){
        addressSearch()
    }
    
//!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    
    //MARK: - Geocoding Methods
    
    func addressSearch() {
        weatherSearchBar.resignFirstResponder()
        guard let searchText = weatherSearchBar.text else {
            return
        }
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(searchText) { (placemarks, error) in
            if let err=error {
                print("Got Error \(err.localizedDescription)")
            }else{
                //(placemarks: placemarks, title: "From Lat/Lon: \(searchText)")
                let weatherHere = placemarks!.first!.location
                self.lat  = weatherHere!.coordinate.latitude
                self.long = weatherHere!.coordinate.longitude
                print("geocoder lat long \(self.lat) \(self.long)")
                self.myUrlString = self.hostName + "forecast/" + self.skeltonKey + "/" + String(self.lat) + "," + String(self.long)
                self.getFile(myUrlString: self.myUrlString)
            }
        }
    }
    
//!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    
    
    //MARK: - Core Methods
    
    func parseJson(data: Data){
        do {
            let jsonResult = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as! [String:Any]
             print ("JSON:\(jsonResult)")
            if let nestedDictionary = jsonResult["currently"] as? [String: Any] {
                // access nested dictionary values by key
                print("nestedDictionary:\(nestedDictionary)")
                let icon:String = nestedDictionary["icon"] as! String? ?? "none"
                let temp = nestedDictionary["temperature"] ?? 0.0
                weatherText = "The Temperature is \(temp) Degrees"
                switch icon {
                case "clear-day":
                    iconImage = "sun.png"
                case "clear-night":
                    iconImage = "moon.png"
                case "rain":
                    iconImage = "rain.png"
                case "snow":
                    iconImage = "snow.png"
                case "sleet":
                    iconImage = "rain-6.png"
                case "wind":
                    iconImage = "wind.png"
                case "fog":
                    iconImage = "haze-3.png"
                case "cloudy":
                    iconImage = "cloud.png"
                case "partly-cloudy-day":
                    iconImage = "cloudy.png"
                case "partly-cloudy-night":
                    iconImage = "cloudy-1.png"
                default:
                    iconImage = "weathercock.png"
                }
                
                
                
                
                print ("Temp! is \(temp)")
                print ("icon is \(icon)")
                //locLat = coord[1]
                //locLong = coord[0]
            }

            
            
     }catch { print("JSON Parsing Error")}
        print("Here!")
        //allMuseums.sort{$0.locationStateZip < $1.locationStateZip}
        DispatchQueue.main.async {
            self.temperatureLabel.text = self.weatherText
            self.weatherImageView.image = UIImage(named: (self.iconImage))
        //    UIApplication.shared.isNetworkActivityIndicatorVisible = false
        
        }
    }
    
    
    
    func getFile(myUrlString:String){
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        //let urlString = "https://\(hostName)\(filename)"
        //let urlString = "https://data.imls.gov/resource/et8i-mnha.json"
        let urlString = myUrlString
        let url = URL(string: urlString)!
        var request = URLRequest(url:url)
        request.timeoutInterval = 30
        request.cachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        let session = URLSession.shared
        let task = session.dataTask(with: request) { (data, response, error) in
            guard let recvData = data else {
                print("No Data")
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
                return
            }
            if recvData.count > 0 && error == nil {
                //print("Got Data:\(recvData)")
                //print("Got Data!")
                let dataString = String.init(data: recvData, encoding: .utf8)
                print("Got Data String:\(dataString)")
                self.parseJson(data: recvData)
            }else{
                print("Got Data of Length 0")
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            }
        }
        task.resume()
    }
    
    
//!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

    //MARK: - Reachability Methods
    
    func setupReachability(hostName: String)  {
        reachability = Reachability(hostname: hostName)
        reachability!.whenReachable = { reachability in
            DispatchQueue.main.async {
                self.updateLabel(reachable: true, reachability: reachability)
            }
            
        }
        reachability!.whenUnreachable = {reachability in
            self.updateLabel(reachable: false, reachability: reachability)        }
    }
    
    func startReachability() {
        do{
            try reachability!.startNotifier()
        }catch{
//            networkStatusLabel.text = "Unable to Start Notifier"
//            networkStatusLabel.textColor = .red
            print("Unable to Start Notifier!")
            return
        }
    }
    
    func updateLabel(reachable: Bool, reachability: Reachability){
        if reachable {
            if reachability.isReachableViaWiFi{
//                networkStatusLabel.textColor = .green
                 print("WiFi is available.")
            }else {
//                networkStatusLabel.textColor = .blue
                print("Cellular data is being used")
            }
        }else{
//            networkStatusLabel.textColor = .red
            print("No Network Available")
        }
//        networkStatusLabel.text = reachability.currentReachabilityString
        print("     /(reachability.currentReachabilityString)")
    }
    
// END Reachability Methods
//!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    
    
//MARK: - Location get
    
   //func getStableLoc() ->
    
    
    
    
//MARK: - PLIST Methods
    
    func getSkeltonKey()-> String {
        var DSKey = ""
        if let file = Bundle.main.path(forResource: "dsdata", ofType: "plist"), let dict = NSDictionary(contentsOfFile: file) as? [String: AnyObject]{
                    DSKey = (dict["DarkSkyAPISecretKey"] as? String)!
        }
        return DSKey
    }
 
    
}
//!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
//!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!



extension ViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let lastLoc = locations.last!
        print("Last Loc: \(lastLoc.coordinate.latitude),\(lastLoc.coordinate.longitude)")
//        zoomToLocation(lat: lastLoc.coordinate.latitude, lon: lastLoc.coordinate.longitude, radius: 500)
        manager.stopUpdatingLocation()
    }
    
    //MARK: - Location Authorization Methods
    
    func turnOnLocationMonitoring() {
        locationMgr.startUpdatingLocation()
//        coffeeMap.showsUserLocation = true
    }
    
    func setupLocationMonitoring() {
        locationMgr.delegate = self
        locationMgr.desiredAccuracy = kCLLocationAccuracyBest
        if CLLocationManager.locationServicesEnabled() {
            switch CLLocationManager.authorizationStatus() {
            case .authorizedAlways, .authorizedWhenInUse:
                turnOnLocationMonitoring()
            case .denied, .restricted:
                print("Hey turn us back on in Settings!")
            case .notDetermined:
                if locationMgr.responds(to: #selector(CLLocationManager.requestAlwaysAuthorization)) {
                    locationMgr.requestAlwaysAuthorization()
                }
            }
        } else {
            print("Hey Turn Location On in Settings!")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        setupLocationMonitoring()
    }
}

