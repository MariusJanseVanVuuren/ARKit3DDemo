import UIKit
import SceneKit

class GameViewController: UIViewController, UIGestureRecognizerDelegate { // need delegate
    
    @IBOutlet weak var scnView: SCNView!
    var scene = SCNScene()
    
    //// camera
    let camera = SCNCamera()
    let cameraNode = SCNNode()
    var cameraOrbitFinal = SCNNode() // final position of camera (smooth transition)
    let cameraOrbitStart = SCNNode() // start position of camera
    
    //// pan camera limits
    var widthAngle: Float = 0.87 // initial angles
    var heightAngle: Float = 0.20
    var lastWidthAngle: Float = 0.87 /// in radians
    var lastHeightAngle: Float = 0.20
    var maxHeightAngleXUp: Float = 0.40  // up/down limits
    var maxHeightAngleXDown: Float = 0.05
    
    //// camera zoom limits
    var cameraZoomScaleMax = 15.0
    var cameraZoomScaleMin = 5.0
    var cameraCurrentZoomScale = 10.0
    
    //// camera limits up/down, left/right
    var lastPositionX: Float = 0.0
    var lastPositionY: Float = 0.0
    var maxXPositionRight: Float = 4.0
    var maxXPositionLeft: Float = -4.0
    var maxYPositionUp: Float = 3.0
    var maxYPositionDown: Float = -3.0
    
    ////// original settings, double tap to reset
    var originalCameraZoomScale: Double!
    var originalWidthAngle: Float!
    var originalHeightAngle: Float!
    var originalPositionX: Float!
    var originalPositionY: Float!
    
    /////// position of cameraOrbitNode, starts at center of scene
    var positionX: Float = 0.0
    var positionY: Float = 0.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        scnView.scene = scene
        scnView.delegate = self
        
        cameraNode.camera = camera
        cameraNode.position = SCNVector3(x: 0, y: 0, z: Float(cameraCurrentZoomScale))
        cameraOrbitStart.position = cameraNode.position
        
        //initial camera selfie stick setup
        cameraOrbitFinal.addChildNode(cameraNode)
        cameraOrbitFinal.position = SCNVector3(x: 0, y: 0, z: 0)
        cameraOrbitFinal.eulerAngles.y = Float(-2 * Double.pi) * lastWidthAngle // initial view angle around y
        cameraOrbitFinal.eulerAngles.x = 0 // initial view angle around x
        cameraOrbitStart.eulerAngles.x = cameraOrbitFinal.eulerAngles.x
        cameraOrbitStart.eulerAngles.y = cameraOrbitFinal.eulerAngles.y
        scene.rootNode.addChildNode(cameraOrbitFinal)
        scene.rootNode.addChildNode(cameraOrbitStart)
        
        //// set original positions and camera angle, double tap to reset
        originalCameraZoomScale = cameraCurrentZoomScale
        originalWidthAngle = widthAngle
        originalHeightAngle = heightAngle
        originalPositionX = positionX
        originalPositionY = positionY

        ///// add omni light
        let omniLight = SCNLight()
        omniLight.type = SCNLight.LightType.omni
        let omniLightNode = SCNNode()
        omniLightNode.light = omniLight
        omniLightNode.position = SCNVector3(x: -2.0, y: 5, z: 10.0)
        cameraOrbitFinal.addChildNode(omniLightNode) // add light to camera orbit node
        
        ////// add gestures
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(self.panGestureRecognized(gesture:)) )
        panGesture.delegate = self //// needed for simultaneous gestures
        self.view.addGestureRecognizer(panGesture)
        
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(self.pinchGestureRecognized(gesture:)) )
        pinchGesture.delegate = self //// needed for simultaneous gestures
        self.view.addGestureRecognizer(pinchGesture)
        
        let lateralGesture = UIPanGestureRecognizer(target: self, action: #selector(self.lateralGestureRecognized(gesture:)) )
        lateralGesture.delegate = self //// needed for simultaneous gestures
        self.view.addGestureRecognizer(lateralGesture)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.tapGestureRecognized(gesture:)) )
        tapGesture.delegate = self
        tapGesture.numberOfTapsRequired = 2
        self.view.addGestureRecognizer(tapGesture)
        
        let pressGesture = UITapGestureRecognizer()
        pressGesture.numberOfTapsRequired = 1
        pressGesture.numberOfTouchesRequired = 1
        pressGesture.addTarget(self, action: #selector(self.pressGestureRecognized(gesture:)))
        scnView.gestureRecognizers = [pressGesture]
        
        scnView.isPlaying = true // keeps render delegate running for smoother transitions
        
    }
    
    ///////// enable simultaneous gestures
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    /////////////////////////////////////////////////
    /////////////////////////////////////////////////
    /// gestures
    
    
    @objc func panGestureRecognized(gesture: UIPanGestureRecognizer) {
        if gesture.numberOfTouches == 1 {
            let translation = gesture.translation(in: gesture.view!)
            
            widthAngle = Float(translation.x) / Float(gesture.view!.frame.size.width) + lastWidthAngle
            heightAngle = Float(translation.y) / Float(gesture.view!.frame.size.height) + lastHeightAngle
            
            //  limits
            if (heightAngle >= maxHeightAngleXUp ) {
                heightAngle = maxHeightAngleXUp
                lastHeightAngle = heightAngle
                ///// reset translation when at max height so finger slide reacts immediately
                gesture.setTranslation(CGPoint(x: translation.x, y: 0.0), in: self.view)
            }
            if (heightAngle <= maxHeightAngleXDown ) {
                heightAngle = maxHeightAngleXDown
                lastHeightAngle = heightAngle
                ///// reset translation when at min height so finger slide reacts immediately
                gesture.setTranslation(CGPoint(x: translation.x, y: 0.0), in: self.view)
            }
            //// rotate camera smootly to new angle
            cameraOrbitStart.eulerAngles.y = Float(-2 * Double.pi) * widthAngle
            cameraOrbitStart.eulerAngles.x = Float(-Double.pi) * heightAngle
        }
        else { // when gesture ends or another finger touches screen, save the rotation
            gesture.setTranslation(CGPoint(x: 0.0, y: 0.0), in: self.view)
            lastWidthAngle = widthAngle
            lastHeightAngle = heightAngle
        }
    }
    
    @objc func pinchGestureRecognized(gesture: UIPinchGestureRecognizer) {
        if gesture.numberOfTouches == 2 {
            var pinchVelocity = Double(gesture.velocity)
            
            ///// error check on multiple simultaneous gestures bug
            if (pinchVelocity.isNaN) || (pinchVelocity.isInfinite) {
                pinchVelocity = 0.0
            }
            
            cameraCurrentZoomScale  -= pinchVelocity / 10.0
            if cameraCurrentZoomScale <= cameraZoomScaleMin {
                cameraCurrentZoomScale = cameraZoomScaleMin
            }
            if cameraCurrentZoomScale >= cameraZoomScaleMax {
                cameraCurrentZoomScale = cameraZoomScaleMax
            }
            
            /////// move camera along selfie stick
            cameraOrbitStart.position = SCNVector3(x: positionX, y: positionY, z: Float(cameraCurrentZoomScale))
        }
    }
    
    @objc func lateralGestureRecognized(gesture: UIPanGestureRecognizer) {
        if gesture.numberOfTouches == 2 {
            
            let translation = gesture.translation(in: gesture.view!)
            positionX = Float((-translation.x / 30.0)) + lastPositionX
            positionY = Float((translation.y / 30.0)) + lastPositionY
            
            if positionX >= maxXPositionRight {
                ///// reset translation when at max so finger slide reacts immediately
                gesture.setTranslation(CGPoint(x: 0.0, y: translation.y), in: self.view)
                lastPositionX = maxXPositionRight
                positionX = maxXPositionRight
            }
            if positionX <= maxXPositionLeft {
                gesture.setTranslation(CGPoint(x: 0.0, y: translation.y), in: self.view)
                lastPositionX = maxXPositionLeft
                positionX = maxXPositionLeft
            }
            if positionY <= maxYPositionDown {
                gesture.setTranslation(CGPoint(x: translation.x, y: 0.0), in: self.view)
                lastPositionY = maxYPositionDown
                positionY = maxYPositionDown
            }
            if positionY >= maxYPositionUp {
                gesture.setTranslation(CGPoint(x: translation.x, y: 0.0), in: self.view)
                lastPositionY = maxYPositionUp
                positionY = maxYPositionUp
            }
            
            /////// move camera laterally up/down or left/right
            cameraOrbitStart.position = SCNVector3(x: positionX, y: positionY, z: Float(cameraCurrentZoomScale))
            
        }
        else {  // when gesture ends or a finger is lifted, save the position
            gesture.setTranslation(CGPoint(x: 0.0, y: 0.0), in: self.view)
            lastPositionX = Float(positionX)
            lastPositionY = Float(positionY)
        }
    }
    
    @objc func tapGestureRecognized(gesture: UITapGestureRecognizer) {
        ////// double tap to reset scene to original view
        cameraOrbitStart.eulerAngles.y = -2 * .pi * originalWidthAngle
        cameraOrbitStart.eulerAngles.x = -.pi * originalHeightAngle
        cameraOrbitStart.position = SCNVector3(x: originalPositionX, y: originalPositionY, z: Float(originalCameraZoomScale))
        cameraCurrentZoomScale = originalCameraZoomScale
        positionX = 0.0
        positionY = 0.0
        lastPositionX = 0.0
        lastPositionY = 0.0
        lastWidthAngle = originalWidthAngle
        lastHeightAngle = originalHeightAngle
    }
    
    @objc func pressGestureRecognized(gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: scnView)
        
        let hitResults = scnView.hitTest(location, options: nil)
        if hitResults.count > 0 {
            let hitTrianglePosition = hitResults.first
            
            positionX = (hitTrianglePosition?.worldCoordinates.x ?? 0.0)
            positionY = (hitTrianglePosition?.worldCoordinates.y ?? 0.0)
            cameraCurrentZoomScale = 3
            cameraOrbitStart.eulerAngles.y = 0
            cameraOrbitStart.eulerAngles.x = 0
            /////// move camera along selfie stick
            cameraOrbitStart.position = SCNVector3(x: positionX, y: positionY, z: Float(cameraCurrentZoomScale))
        }
    }
    
    /////////////////////////////////////////////////
    /////////////////////////////////////////////////
    //smooth gestures, called by SCNSceneRendererDelegate
    
    func updatePositions() {
        
        /// pan
        let lerpY = (cameraOrbitStart.eulerAngles.y - cameraOrbitFinal.eulerAngles.y) * 0.075
        let lerpX = (cameraOrbitStart.eulerAngles.x - cameraOrbitFinal.eulerAngles.x) * 0.075
        cameraOrbitFinal.eulerAngles.y += lerpY
        cameraOrbitFinal.eulerAngles.x += lerpX
        
        /// zooms
        let lerpZ = (cameraOrbitStart.position.z - cameraNode.position.z) * 0.075
        cameraNode.position.z += lerpZ
        
        /// lateral moves
        let lerpLX = (cameraOrbitStart.position.x - cameraNode.position.x) * 0.075
        let lerpLY = (cameraOrbitStart.position.y - cameraNode.position.y) * 0.075
        cameraNode.position.x += lerpLX
        cameraNode.position.y += lerpLY
    }
    
    override var shouldAutorotate: Bool {
        return true
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }
    
}

extension GameViewController : SCNSceneRendererDelegate {
    
    func renderer(_ renderer: SCNSceneRenderer, didApplyAnimationsAtTime time: TimeInterval) {
        updatePositions()
    }
}
