import UIKit
import ARKit

class ViewController: GameViewController {
    private var changedColor: Bool = false
    let nodeName = "body"
    let eyeNodeName = "eye"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        addPerson()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    func configureLighting() {
        scnView.autoenablesDefaultLighting = true
    }
    
    func addPerson(x: Float = 0, y: Float = -5, z: Float = 0) {
        guard let femaleScene = SCNScene(named: "standard-female-figure.dae") else { return }
        let femaleNode = SCNNode()
        let femaleSceneChildNodes = femaleScene.rootNode.childNodes
        for childNode in femaleSceneChildNodes {
            femaleNode.addChildNode(childNode)
        }
        femaleNode.position = SCNVector3(x, y, z)
        femaleNode.scale = SCNVector3(0.5, 0.5, 0.5)
        scnView.scene!.rootNode.addChildNode(femaleNode)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        let location = touches.first!.location(in: scnView)
        
        // Let's test if a 3D Object was touched
        var hitTestOptions = [SCNHitTestOption: Any]()
        hitTestOptions[SCNHitTestOption.boundingBoxOnly] = true
        
        let hitResults: [SCNHitTestResult]  = scnView.hitTest(location, options: hitTestOptions)
        
        if let hit = hitResults.first {
            if let node = getParent(hit.node) {
                if node.name == nodeName {
                    
                    let materials = node.geometry?.materials as! [SCNMaterial]
                    let material = materials[0]
                    if changedColor == false {
                        material.diffuse.contents = UIColor.green
                        showBlurbForNode(node.name)
                        changedColor = true
                    } else {
                        changedColor = false
                        material.diffuse.contents = UIColor.white
                        for subview in self.view.subviews {
                            if type(of: subview) == UILabel.self {
                                subview.removeFromSuperview()
                            }
                        }
                    }
                    return
                } else {
                    let materials = node.geometry?.materials as! [SCNMaterial]
                    let material = materials[0]
                    material.diffuse.contents = UIColor.green
                    return
                }
            }
        }
    }
    
    func showBlurbForNode(_ node: String?) {
        if nodeName == node {
            let label = UILabel.init(frame: CGRect.init(x: 0, y: 0, width: 300, height: 50))
            label.text = "Your are healthy"
            label.backgroundColor = UIColor.lightGray
            self.view.addSubview(label)
            
            NSLayoutConstraint(item: label,
                               attribute: NSLayoutAttribute.bottom,
                               relatedBy: NSLayoutRelation.equal,
                               toItem: self.view,
                               attribute: NSLayoutAttribute.bottom,
                               multiplier: 1,
                               constant: 1).isActive = true
            NSLayoutConstraint(item: label,
                               attribute: NSLayoutAttribute.centerX,
                               relatedBy: NSLayoutRelation.equal,
                               toItem: self.view,
                               attribute: NSLayoutAttribute.centerX,
                               multiplier: 1,
                               constant: 1).isActive = true
        }
    }
    
    func getParent(_ nodeFound: SCNNode?) -> SCNNode? {
        if let node = nodeFound {
            if node.name == nodeName {
                return node
            } else if node.name == eyeNodeName {
                return node
            }
            else if let parent = node.parent {
                return getParent(parent)
            }
        }
        return nil
    }
}
