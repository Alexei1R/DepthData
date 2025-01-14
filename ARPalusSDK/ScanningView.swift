import Foundation
import ARKit

enum SDK {
    func initialize(token: String) {}
}

final class ScanningView: UIView {
    let sphere: SCNNode = {
        let geo = SCNSphere(radius: 0.001)
        geo.firstMaterial?.diffuse.contents = UIColor.white
        let node: SCNNode = .init(geometry: geo)
        return node
    }()

    let delegateQueue = DispatchQueue(label: "com.arpalus.sessionDelegateQueue", qos: .userInteractive)
    let arSceneView: ARSCNView
    let imageView = UIImageView()

    override init(frame: CGRect) {
        arSceneView = .init(frame: .zero, options: [:])
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    func setupUI() {
        addSubview(arSceneView)
        addSubview(imageView)
        imageView.contentMode = .scaleAspectFit
        imageView.contentScaleFactor = 3
    }

    override func didMoveToWindow() {
        guard window != nil else { return }
        let config = ARWorldTrackingConfiguration()
        arSceneView.session.delegate = self
        arSceneView.session.delegateQueue = delegateQueue
        arSceneView.session.run(config)
    }

    override func layoutSubviews() {
        arSceneView.frame = bounds
        imageView.frame = .init(origin: .zero, size: bounds.applying(.init(scaleX: 0.3, y: 0.3)).size)
    }
}

extension ScanningView: ARSessionDelegate {
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        let buffer = frame.capturedImage
        let image = CIImage(cvPixelBuffer: buffer)
            .transformed(
                by:
                    .init(rotationAngle: -.pi/2)
                    .translatedBy(x: -CGFloat(CVPixelBufferGetWidth(buffer)), y: 0)
            )

        DispatchQueue.main.async {
            self.imageView.image = .init(ciImage: image)
        }

        arSceneView.scene.rootNode.childNodes.forEach { node in
            node.geometry = nil
            node.removeFromParentNode()
        }

        frame.rawFeaturePoints?.points.forEach({ coords in
            let node = sphere.clone()
            node.position = .init(coords)
            arSceneView.scene.rootNode.addChildNode(node)
        })
    }
}
