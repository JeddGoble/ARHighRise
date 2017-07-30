//
//  ViewController.swift
//  HighRiseAR
//
//  Created by jgoble52 on 7/26/17.
//  Copyright © 2017 Jedd Goble. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    
    var direction = true
    var height = 0
    
    var previousSize = SCNVector3(0.3, 0.1, 0.3)
    var previousPosition = SCNVector3(0, -1.0, -1.0)
    var currentSize = SCNVector3(0.3, 0.1, 0.3)
    var currentPosition = SCNVector3(0, -1.0, -1.0)
    
    var offset = SCNVector3Zero
    var absoluteOffset = SCNVector3Zero
    var newSize = SCNVector3Zero
    var perfectMatches = 0
    
    var tapRecognizer: UITapGestureRecognizer?
    
    var gameIsRunning = false
    
    let redMultiplier: CGFloat = 0.15
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.delegate = self
        sceneView.showsStatistics = false
        
        let scene = SCNScene(named: "GameScene.scn")!
        sceneView.scene = scene
        
        sceneView.isPlaying = true
        
        tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        if let tr = tapRecognizer {
            sceneView.addGestureRecognizer(tr)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingSessionConfiguration()
        
        // Run the view's session
        sceneView.session.run(configuration)
        
        addGameToScene()
    }
    
    func addGameToScene() {
        
        // Needed?
    }
    
    @objc func handleTap() {
        
        if (!gameIsRunning) {
            let gameScene = SCNScene(named: "GameScene.scn")!
            sceneView.scene = gameScene
            height = 0
            direction = true
            perfectMatches = 0
            
            previousSize = SCNVector3(0.3, 0.1, 0.3)
            previousPosition = SCNVector3(0, -1.5, -1.5)
            currentSize = SCNVector3(0.3, 0.1, 0.3)
            currentPosition = SCNVector3(0, -1.5, -1.5)
            
            let boxNode = SCNNode(geometry: SCNBox(width: 0.3, height: 0.1, length: 0.3, chamferRadius: 0))
            boxNode.position.z = -1.5
            boxNode.position.y = -0.5
            boxNode.name = "Block\(height)"
            let redAmount = CGFloat(height) * redMultiplier
            boxNode.geometry?.firstMaterial?.diffuse.contents = UIColor(red: redAmount, green: 0.1, blue: 0.9, alpha: 0.95)
            sceneView.scene.rootNode.addChildNode(boxNode)
            
            gameIsRunning = true
        } else {
            
            if let currentBoxNode = sceneView.scene.rootNode.childNode(withName: "Block\(height)", recursively: false) {
                currentPosition = currentBoxNode.position
                let boundsMin = currentBoxNode.boundingBox.min
                let boundsMax = currentBoxNode.boundingBox.max
                currentSize = boundsMax - boundsMin
                
                offset = previousPosition - currentPosition
                absoluteOffset = offset.absoluteValue()
                newSize = currentSize - absoluteOffset
                
                if height % 2 == 0 && newSize.z <= 0 {
                    print("Game Over")
                    return
                } else if height % 2 != 0 && newSize.x <= 0 {
                    print("Game Over")
                    return
                }
                
                checkPerfectMatch(currentBoxNode)
                
                currentBoxNode.geometry = SCNBox(width: CGFloat(newSize.x), height: 0.1, length: CGFloat(newSize.z), chamferRadius: 0)
                currentBoxNode.position = SCNVector3Make(currentPosition.x + (offset.x/2), currentPosition.y, currentPosition.z + (offset.z/2))
                currentBoxNode.physicsBody = SCNPhysicsBody(type: .static, shape: SCNPhysicsShape(geometry: currentBoxNode.geometry!, options: nil))
                currentBoxNode.physicsBody?.isAffectedByGravity = false
                currentBoxNode.physicsBody?.collisionBitMask = 0
                
                addNewBlock(currentBoxNode)
                
                previousSize = SCNVector3Make(newSize.x, 0.1, newSize.z)
                previousPosition = currentBoxNode.position
                
                height += 1
                
            }
        }
    }
    
    func addNewBlock(_ currentBoxNode: SCNNode) {
        let newBoxNode = SCNNode(geometry: currentBoxNode.geometry)
        newBoxNode.position = SCNVector3Make(currentBoxNode.position.x, currentPosition.y + 0.1, currentBoxNode.position.z)
        newBoxNode.name = "Block\(height+1)"
        let redAmount = CGFloat(height) * redMultiplier
        newBoxNode.geometry?.firstMaterial?.diffuse.contents = UIColor(red: redAmount, green: 0.1, blue: 0.9, alpha: 0.95)
        
        if height % 2 == 0 {
            newBoxNode.position.x = -0.9
        } else {
            newBoxNode.position.z = -1.9
        }
        
        sceneView.scene.rootNode.addChildNode(newBoxNode)
    }
    
    func addBrokenBlock(_ currentBoxNode: SCNNode) {
        let brokenBoxNode = SCNNode()
        brokenBoxNode.name = "Broken \(height)"
        
        if height % 2 == 0 && absoluteOffset.z > 0 {
            // 1
            brokenBoxNode.geometry = SCNBox(width: CGFloat(currentSize.x), height: 0.1, length: CGFloat(absoluteOffset.z), chamferRadius: 0)
            
            // 2
            if offset.z > 0 {
                brokenBoxNode.position.z = currentBoxNode.position.z - (offset.z/2) - ((currentSize - offset).z/2)
            } else {
                brokenBoxNode.position.z = currentBoxNode.position.z - (offset.z/2) + ((currentSize + offset).z/2)
            }
            brokenBoxNode.position.x = currentBoxNode.position.x
            brokenBoxNode.position.y = currentPosition.y
            
            // 3
            brokenBoxNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(geometry: brokenBoxNode.geometry!, options: nil))
            brokenBoxNode.physicsBody?.isAffectedByGravity = false
            currentBoxNode.physicsBody?.collisionBitMask = 0
            let redAmount = CGFloat(height) * redMultiplier
            brokenBoxNode.geometry?.firstMaterial?.diffuse.contents = UIColor(red: redAmount, green: 0.1, blue: 0.9, alpha: 0.95)
            sceneView.scene.rootNode.addChildNode(brokenBoxNode)
            
            // 4
        } else if height % 2 != 0 && absoluteOffset.x > 0 {
            brokenBoxNode.geometry = SCNBox(width: CGFloat(absoluteOffset.x), height: 0.1, length: CGFloat(currentSize.z), chamferRadius: 0)
            
            if offset.x > 0 {
                brokenBoxNode.position.x = currentBoxNode.position.x - (offset.x/2) - ((currentSize - offset).x/2)
            } else {
                brokenBoxNode.position.x = currentBoxNode.position.x - (offset.x/2) + ((currentSize + offset).x/2)
            }
            brokenBoxNode.position.y = currentPosition.y
            brokenBoxNode.position.z = currentBoxNode.position.z
            
            brokenBoxNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(geometry: brokenBoxNode.geometry!, options: nil))
            brokenBoxNode.physicsBody?.isAffectedByGravity = false
            currentBoxNode.physicsBody?.collisionBitMask = 0
            let redAmount = CGFloat(height) * redMultiplier
            brokenBoxNode.geometry?.firstMaterial?.diffuse.contents = UIColor(red: redAmount, green: 0.1, blue: 0.9, alpha: 0.95)
            sceneView.scene.rootNode.addChildNode(brokenBoxNode)
        }
    }
    
    func checkPerfectMatch(_ currentBoxNode: SCNNode) {
        if height % 2 == 0 && absoluteOffset.z <= 0.03 {
            currentBoxNode.position.z = previousPosition.z
            currentPosition.z = previousPosition.z
            perfectMatches += 1
            if perfectMatches >= 7 && currentSize.z < 1 {
                newSize.z += 0.05
            }
            
            offset = previousPosition - currentPosition
            absoluteOffset = offset.absoluteValue()
            newSize = currentSize - absoluteOffset
        } else if height % 2 != 0 && absoluteOffset.x <= 0.03 {
            currentBoxNode.position.x = previousPosition.x
            currentPosition.x = previousPosition.x
            perfectMatches += 1
            if perfectMatches >= 7 && currentSize.x < 1 {
                newSize.x += 0.05
            }
            
            offset = previousPosition - currentPosition
            absoluteOffset = offset.absoluteValue()
            newSize = currentSize - absoluteOffset
        } else {
            perfectMatches = 0
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

    // MARK: - ARSCNViewDelegate
    
/*
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
     
        return node
    }
*/
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
}

extension ViewController: SCNSceneRendererDelegate {
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        
        for node in sceneView.scene.rootNode.childNodes {
            if node.presentation.position.y <= -20 {
                node.removeFromParentNode()
            }
        }
        
        // 1
        if let currentNode = sceneView.scene.rootNode.childNode(withName: "Block\(height)", recursively: false) {
            // 2
            if height % 2 == 0 {
                // 3
                if currentNode.position.z >= 0.0 {
                    direction = false
                } else if currentNode.position.z <= -2.0 {
                    direction = true
                }
                
                // 4
                switch direction {
                case true:
                    currentNode.position.z += 0.03
                case false:
                    currentNode.position.z -= 0.03
                }
                // 5
            } else {
                if currentNode.position.x >= 1.0 {
                    direction = false
                } else if currentNode.position.x <= -1.0 {
                    direction = true
                }
                
                switch direction {
                case true:
                    currentNode.position.x += 0.03
                case false:
                    currentNode.position.x -= 0.03
                }
            }
        }
    }
}

