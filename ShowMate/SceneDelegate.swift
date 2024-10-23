import UIKit
import FirebaseAuth

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    
    var window: UIWindow?
        
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        window = UIWindow(windowScene: windowScene)
        
        // Always sign out when app launches
        try? Auth.auth().signOut()
        
        // Show login screen
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let loginVC = storyboard.instantiateViewController(withIdentifier: "ViewController") as? ViewController {
            window?.rootViewController = loginVC
        }
        
        window?.makeKeyAndVisible()
    }
    
    func checkAuthAndSetRootViewController() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        
        if let _ = Auth.auth().currentUser {
            // User is logged in, show main tab controller
            if let mainVC = storyboard.instantiateViewController(withIdentifier: "TabBarController") as? UITabBarController {
                window?.rootViewController = mainVC
            }
        } else {
            // No user is logged in, show login screen
            if let loginVC = storyboard.instantiateViewController(withIdentifier: "ViewController") as? ViewController {
                window?.rootViewController = loginVC
            }
        }
        
        window?.makeKeyAndVisible()
    }
    
    // Keep existing scene lifecycle methods
    func sceneDidDisconnect(_ scene: UIScene) {
        // Existing implementation
    }
    
    func sceneDidBecomeActive(_ scene: UIScene) {
        // Existing implementation
    }
    
    func sceneWillResignActive(_ scene: UIScene) {
        // Existing implementation
    }
    
    func sceneWillEnterForeground(_ scene: UIScene) {
        // Existing implementation
    }
    
    func sceneDidEnterBackground(_ scene: UIScene) {
        // Existing implementation
    }
}
