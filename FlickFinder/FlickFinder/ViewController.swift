//
//  ViewController.swift
//  FlickFinder
//
//  Created by Jarrod Parkes on 11/5/15.
//  Copyright © 2015 Udacity. All rights reserved.
//

import UIKit

// MARK: - ViewController: UIViewController

class ViewController: UIViewController {
    
    // MARK: Properties
    
    var keyboardOnScreen = false
    var pageNumber = 1
    // MARK: Outlets
    
    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var photoTitleLabel: UILabel!
    @IBOutlet weak var phraseTextField: UITextField!
    @IBOutlet weak var phraseSearchButton: UIButton!
    @IBOutlet weak var latitudeTextField: UITextField!
    @IBOutlet weak var longitudeTextField: UITextField!
    @IBOutlet weak var latLonSearchButton: UIButton!
    
    // MARK: Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        phraseTextField.delegate = self
        latitudeTextField.delegate = self
        longitudeTextField.delegate = self
        subscribeToNotification(.UIKeyboardWillShow, selector: #selector(keyboardWillShow))
        subscribeToNotification(.UIKeyboardWillHide, selector: #selector(keyboardWillHide))
        subscribeToNotification(.UIKeyboardDidShow, selector: #selector(keyboardDidShow))
        subscribeToNotification(.UIKeyboardDidHide, selector: #selector(keyboardDidHide))
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        unsubscribeFromAllNotifications()
    }
    
    // MARK: Search Actions
    
    @IBAction func searchByPhrase(_ sender: AnyObject) {

        userDidTapView(self)
        setUIEnabled(false)
        
        if !phraseTextField.text!.isEmpty {
            photoTitleLabel.text = "Searching..."
            // TODO: Set necessary parameters!
            var methodParameters: [String: String] = [:]
            methodParameters[Constants.FlickrParameterKeys.SafeSearch] = Constants.FlickrParameterValues.UseSafeSearch
            methodParameters[Constants.FlickrParameterKeys.Page] = "\(self.pageNumber)"
            methodParameters[Constants.FlickrParameterKeys.Text]   = phraseTextField.text
            methodParameters[Constants.FlickrParameterKeys.Extras] = Constants.FlickrParameterValues.MediumURL
            methodParameters[Constants.FlickrParameterKeys.APIKey] = Constants.FlickrParameterValues.APIKey
            methodParameters[Constants.FlickrParameterKeys.Method] = Constants.FlickrParameterValues.SearchMethod
            methodParameters[Constants.FlickrParameterKeys.Format] = Constants.FlickrParameterValues.ResponseFormat
            methodParameters[Constants.FlickrParameterKeys.NoJSONCallback] = Constants.FlickrParameterValues.DisableJSONCallback
            displayImageFromFlickrBySearch(methodParameters )
        } else {
            setUIEnabled(true)
            photoTitleLabel.text = "Phrase Empty."
        }
    }
    
    @IBAction func searchByLatLon(_ sender: AnyObject) {

        userDidTapView(self)
        setUIEnabled(false)
        
        if isTextFieldValid(latitudeTextField, forRange: Constants.Flickr.SearchLatRange) && isTextFieldValid(longitudeTextField, forRange: Constants.Flickr.SearchLonRange) {
            photoTitleLabel.text = "Searching..."
            // TODO: Set necessary parameters!
            var methodParameters : [String: String] = [:]
            methodParameters[Constants.FlickrParameterKeys.SafeSearch] = Constants.FlickrParameterValues.UseSafeSearch
            methodParameters[Constants.FlickrParameterKeys.Page] = "\(self.pageNumber)"
            methodParameters[Constants.FlickrParameterKeys.BoundingBox]   = bBox()
            methodParameters[Constants.FlickrParameterKeys.Extras] = Constants.FlickrParameterValues.MediumURL
            methodParameters[Constants.FlickrParameterKeys.APIKey] = Constants.FlickrParameterValues.APIKey
            methodParameters[Constants.FlickrParameterKeys.Method] = Constants.FlickrParameterValues.SearchMethod
            methodParameters[Constants.FlickrParameterKeys.Format] = Constants.FlickrParameterValues.ResponseFormat
            methodParameters[Constants.FlickrParameterKeys.NoJSONCallback] = Constants.FlickrParameterValues.DisableJSONCallback
            displayImageFromFlickrBySearch(methodParameters)
        }
        else {
            setUIEnabled(true)
            photoTitleLabel.text = "Lat should be [-90, 90].\nLon should be [-180, 180]."
        }
    }
    
    // MARK: Flickr API
    private func bBox() -> String{
        guard let Lat = latitudeTextField.text else {
            print("no lat input")
            return ""
        }
        
        guard let long = longitudeTextField.text  else {
            print(" no long input")
            return ""
        }
        
        guard isValueInRange(Double(long)!   , min: Constants.Flickr.SearchLonRange.0 - Constants.Flickr.SearchBBoxHalfHeight, max: Constants.Flickr.SearchLonRange.1 - Constants.Flickr.SearchBBoxHalfHeight) else {
            print("lat out of range")
            return ""
        }
        
        guard isValueInRange(Double(Lat)! , min: Constants.Flickr.SearchLatRange.0 - Constants.Flickr.SearchBBoxHalfWidth, max: Constants.Flickr.SearchLatRange.1 - Constants.Flickr.SearchBBoxHalfWidth) else {
            print("long out of range")
            return ""
        }
        let latRange = (Double(Lat)! - Constants.Flickr.SearchBBoxHalfWidth , Double(Lat)! + Constants.Flickr.SearchBBoxHalfWidth)
        let lonRange = (Double(long)! - Constants.Flickr.SearchBBoxHalfHeight , Double(long)! + Constants.Flickr.SearchBBoxHalfHeight)
        
        return "\(latRange.0),\(lonRange.0),\(latRange.1),\(lonRange.1)"
        
    }
    private func displayImageFromFlickrBySearch(_ methodParameters: [String: String]) {
        
        print(flickrURLFromParameters(methodParameters))
        
        // TODO: Make request to Flickr!
        let session = URLSession.shared
        let request = session.dataTask(with: flickrURLFromParameters(methodParameters)) { (data , response, error) in
            
            func errorDisplay(_ error: String){
                print(error)
                performUIUpdatesOnMain {
                    self.setUIEnabled(true)
                    self.photoTitleLabel.text = "No photo returned. Try Again"
                    self.photoImageView.image = nil
                }
            }
            
            guard error == nil else{
                errorDisplay(error!.localizedDescription)
                return
            }
            
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode , 200...299  ~= statusCode else {
                errorDisplay("Your request returned a status code other than 2xx!")
                return
            }
            
            guard let data = data else {
                errorDisplay("unfortunately you don't have a data please try again")
                return
            }
             let parsedJson : [String : AnyObject]
             do{
                parsedJson = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as! [String : AnyObject]
                guard let photosDictionary = parsedJson[Constants.FlickrResponseKeys.Photos] as? [String:AnyObject] else {
                    errorDisplay("Cannot Find key")
                    return
                }
                guard let photoDictionaries = photosDictionary[Constants.FlickrResponseKeys.Photo] as? [[String : AnyObject]] else {
                    errorDisplay("Cannot Find key")
                    return
                }
                
                let randomPageNumber = Int(arc4random_uniform(UInt32((photosDictionary[Constants.FlickrResponseKeys.Pages] as? Int)!)))
                self.pageNumber = randomPageNumber
                let randomImageNumber = Int(arc4random_uniform(UInt32(photoDictionaries.count)))
                let photoDictionary = photoDictionaries[randomImageNumber] as [String:AnyObject]
                let photoTitle = photoDictionary[Constants.FlickrResponseKeys.Title] as! String
                guard let imageUrl = photoDictionary[Constants.FlickrResponseKeys.MediumURL] as? String else{
                    errorDisplay("there is no image in the dictionary")
                    return
                }
                
                let url = URL(string: imageUrl)
                if let imageData = try? Data(contentsOf: url!){
                    self.setUIEnabled(true)
                    performUIUpdatesOnMain {
                        self.photoImageView.image = UIImage(data: imageData)
                        self.photoTitleLabel.text = photoTitle
                    }
                    
                    
                }else {
                    errorDisplay("image does not exist")
                    return
                }
                
                print(parsedJson)
                
             } catch{
                errorDisplay("could not parse JSON")
                return
            }
        }
        request.resume()
    }
    
    // MARK: Helper for Creating a URL from Parameters
    
    private func flickrURLFromParameters(_ parameters: [String: String]) -> URL {
        
        var components = URLComponents()
        components.scheme = Constants.Flickr.APIScheme
        components.host = Constants.Flickr.APIHost
        components.path = Constants.Flickr.APIPath
        components.queryItems = [URLQueryItem]()
        
        for (key, value) in parameters {
            let queryItem = URLQueryItem(name: key, value: "\(value)")
            components.queryItems!.append(queryItem)
        }
        
        return components.url!
    }
}

// MARK: - ViewController: UITextFieldDelegate

extension ViewController: UITextFieldDelegate {
    
    // MARK: UITextFieldDelegate
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    // MARK: Show/Hide Keyboard
    
    func keyboardWillShow(_ notification: Notification) {
        if !keyboardOnScreen {
            view.frame.origin.y -= keyboardHeight(notification)
        }
    }
    
    func keyboardWillHide(_ notification: Notification) {
        if keyboardOnScreen {
            view.frame.origin.y += keyboardHeight(notification)
        }
    }
    
    func keyboardDidShow(_ notification: Notification) {
        keyboardOnScreen = true
    }
    
    func keyboardDidHide(_ notification: Notification) {
        keyboardOnScreen = false
    }
    
    func keyboardHeight(_ notification: Notification) -> CGFloat {
        let userInfo = (notification as NSNotification).userInfo
        let keyboardSize = userInfo![UIKeyboardFrameEndUserInfoKey] as! NSValue
        return keyboardSize.cgRectValue.height
    }
    
    func resignIfFirstResponder(_ textField: UITextField) {
        if textField.isFirstResponder {
            textField.resignFirstResponder()
        }
    }
    
    @IBAction func userDidTapView(_ sender: AnyObject) {
        resignIfFirstResponder(phraseTextField)
        resignIfFirstResponder(latitudeTextField)
        resignIfFirstResponder(longitudeTextField)
    }
    
    // MARK: TextField Validation
    
    func isTextFieldValid(_ textField: UITextField, forRange: (Double, Double)) -> Bool {
        if let value = Double(textField.text!), !textField.text!.isEmpty {
            return isValueInRange(value, min: forRange.0, max: forRange.1)
        } else {
            return false
        }
    }
    
    func isValueInRange(_ value: Double, min: Double, max: Double) -> Bool {
        return !(value < min || value > max)
    }
}

// MARK: - ViewController (Configure UI)

private extension ViewController {
    
     func setUIEnabled(_ enabled: Bool) {
        photoTitleLabel.isEnabled = enabled
        phraseTextField.isEnabled = enabled
        latitudeTextField.isEnabled = enabled
        longitudeTextField.isEnabled = enabled
        phraseSearchButton.isEnabled = enabled
        latLonSearchButton.isEnabled = enabled
        
        // adjust search button alphas
        if enabled {
            phraseSearchButton.alpha = 1.0
            latLonSearchButton.alpha = 1.0
        } else {
            phraseSearchButton.alpha = 0.5
            latLonSearchButton.alpha = 0.5
        }
    }
}

// MARK: - ViewController (Notifications)

private extension ViewController {
    
    func subscribeToNotification(_ notification: NSNotification.Name, selector: Selector) {
        NotificationCenter.default.addObserver(self, selector: selector, name: notification, object: nil)
    }
    
    func unsubscribeFromAllNotifications() {
        NotificationCenter.default.removeObserver(self)
    }
}
