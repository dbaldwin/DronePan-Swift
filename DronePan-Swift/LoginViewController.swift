//
//  LoginViewController.swift
//  DronePan-Swift
//
//  Created by Shubh on 03/08/17.
//  Copyright © 2017 Unmanned Airlines, LLC. All rights reserved.
//

import UIKit
import GoogleSignIn
import FirebaseAuth
import FacebookCore
import FacebookLogin

class LoginViewController: UIViewController {

    //======================================
    //MARK: =========== properties ========
    //======================================
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var signInButton: GIDSignInButton!
    var loginButton : LoginButton!
     @IBOutlet weak var cancelLoginButton: UIButton!
    
    //======================================
    //MARK: =========== View's life cycle ========
    //======================================
    override func viewDidLoad() {
        super.viewDidLoad()
        initialConfiguration()
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    //======================================
    //MARK: =========== UIButton Action Method ========
    //======================================
    @IBAction func actionOnFacebookLogin(_ sender: Any) {
        
        if let accessToken = AccessToken.current {
            let credential = FacebookAuthProvider.credential(withAccessToken: accessToken.authenticationToken)
            self.authenticateWithFirebase(credential: credential)
        }else{
            let loginManager = LoginManager()
            loginManager.logIn([ .publicProfile ], viewController: self) { loginResult in
                switch loginResult {
                case .failed(let error):
                    debugPrint(error.localizedDescription)
                    self.showAlert(title: "Message", message: "Could not sign in right now, Please try again later")
                    break
                case .cancelled:
                    break
                case .success(_, _, let accessToken):
                    print("Logged in!")
                    let credential = FacebookAuthProvider.credential(withAccessToken: accessToken.authenticationToken)
                    self.authenticateWithFirebase(credential: credential)
                    break
                }
            }
        }
    }
    
    
    @IBAction func actionOnLoginWithGoogleButton(_ sender: Any) {
    }
    
    @IBAction func cancelLoginButtonAction(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }

}


//======================================
//MARK: =========== Private Methods ========
//======================================
fileprivate extension LoginViewController {
    
    func initialConfiguration() -> Void {
        
        GIDSignIn.sharedInstance().delegate = self
        GIDSignIn.sharedInstance().uiDelegate = self
        signInButton.colorScheme = .dark
        signInButton.style = .wide
        activityIndicator.isHidden = true
        
    }
    func showProgress() -> Void {
        activityIndicator.isHidden = false
        activityIndicator.startAnimating()
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }
    func hideProgress() -> Void {
        activityIndicator.isHidden = true
        activityIndicator.stopAnimating()
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }
    
    
    func authenticateWithFirebase(credential:AuthCredential){
        Auth.auth().signIn(with: credential) { (user, error) in
            // ...
            self.hideProgress()
            if let error = error {
                debugPrint(error.localizedDescription)
                self.showAlert(title: "Message", message: "Could not sign in right now, Please try again later")
                return
            }else{
                //self.performSegue(withIdentifier: "home", sender: nil)
                userID = Auth.auth().currentUser?.uid
                
                if (userID != nil)
                {
                    if let panoramas:[Panorama] = DataBaseHelper.sharedInstance.allRecordsSortByAttribute(inTable: "Panorama") as? [Panorama]
                    { var panormas:[PanoramaModel] = [PanoramaModel]()
                        for panorama in panoramas
                        {
                       let panoramaDict:[String:Any] = ["timeStamp":panorama.timeStamp,"rows":Int(panorama.rows),"columns":Int(panorama.columns),"airCraftLatitude":panorama.airCraftLatitude,"airCraftLongitude":panorama.airCraftLongitude,"skyRow":Int(panorama.skyRow),"yawType":(panorama.yawType ?? ""),"airCraftAltitude":panorama.airCraftAltitude,"airCraftHeading":panorama.airCraftHeading]
                    
                      panormas.append(PanoramaModel.init(panoramaDict as Dictionary<String, AnyObject>))
                        }
                   self.addPanoramaToCloudStoraga(panorama:panormas)
                }
                }
                
                
                self.dismiss(animated: true, completion: nil)
            }
        }
       
        
        
        
        
    }
    
    
    
    
    
    
}


//======================================
//MARK: =========== Signin UI delegate ========
//======================================
extension LoginViewController : GIDSignInDelegate,GIDSignInUIDelegate {
    //MARK:- Google Sign In Delegate
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error?) {
        // ...
        if let error = error {
            debugPrint(error)
            self.showAlert(title: "Message", message: "Could not sign in right now, Please try again later")
            self.hideProgress()
            return
        }
        
        guard let authentication = user.authentication else { return }
        let credential = GoogleAuthProvider.credential(withIDToken: authentication.idToken,
                                                       accessToken: authentication.accessToken)
        self.authenticateWithFirebase(credential: credential)
    }
    
    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
    }
    
    func sign(inWillDispatch signIn: GIDSignIn!, error: Error!) {
        showProgress()
    }
    
}
