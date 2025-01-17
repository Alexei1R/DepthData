//
//  ImageService.swift
//  ARPalusSDK
//
//  Created by Александр Новиков on 16.01.2025.
//

import Foundation
import FirebaseFirestore
import FirebaseStorage
import ARKit

final class ImageService {

    private var localStorage: LocalStorage
    private let storage = FirebaseStorage.Storage.sdk
    private let db = Firestore.sdk
    private var path: String? = nil
    private var isScanning: Bool = false

    init(localStorage: LocalStorage) {
        self.localStorage = localStorage
    }

    private var currentDate: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let currentDate = Date()
        return dateFormatter.string(from: currentDate)
    }

    private var currentTime: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "hh-mm-ss"
        let currentDate = Date()
        return dateFormatter.string(from: currentDate)
    }

    func uploadImageToFirebase(image: UIImage?, arFrame: ARFrame?) {
        isScanning = true
        guard let userSettings = localStorage.userSettings else { isScanning = false; return }
        guard let image else { isScanning = false; return }

        guard let imageData = image.jpegData(compressionQuality: 0.75) else { return }
        let metadata = Data(createMetadata(from: image, arFrame: arFrame)?.data(using: .utf8) ?? Data())
        if path == nil {
            path = "Sessions/\(userSettings.client)/\(userSettings.project)/\(userSettings.deployment.lowercased())\(userSettings.settings)/\(currentDate)/\(currentDate)_\(currentTime)/Images/"
        }
        guard let path else { isScanning = false; return }
        let jpgFileName = "\(currentDate)_\(currentTime)_number.jpg"
        let metadataFilename = "\(currentDate)_\(currentTime)_number.txt"

        let imageRef = storage.reference().child(path + jpgFileName)
        let imageMetadata = StorageMetadata()
        imageMetadata.contentType = "image/jpeg"
        let metadataMetadata = StorageMetadata()
        metadataMetadata.contentType = "text/plain"
        let metadataRef = storage.reference().child(path + metadataFilename)
        Task {
            do {
                _ = try await imageRef.putDataAsync(imageData,metadata: imageMetadata)
                _ = try await metadataRef.putDataAsync(metadata, metadata: metadataMetadata)
                self.path =  nil
            } catch {
                print("Error in uploading image: ", error.localizedDescription)
            }
        }
    }

    func createMetadata(from image: UIImage, arFrame: ARFrame?, frameNumber: Int = 1) -> String? {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .long)
        let imageWidth = Int(image.size.width)
        let imageHeight = Int(image.size.height)

        guard let arFrame else {
            print("ARFrame is nil. Cannot extract AR data.")
            return nil
        }
        let camera = arFrame.camera

        //znear zfar hardcoded
        let projectionMatrix = CameraInfo.Matrix4x4(matrix: camera.projectionMatrix(for: .portrait, viewportSize: image.size, zNear: 0.001, zFar: 1000.0).array)
        let displayMatrix = CameraInfo.Matrix4x4(matrix: camera.viewMatrix(for: .portrait).array)
        let focalLength = CameraInfo.Point(x: Float(camera.intrinsics.columns.0.x), y: Float(camera.intrinsics.columns.1.y))
        let principalPoint = CameraInfo.Point(x: Float(camera.intrinsics.columns.2.x), y: Float(camera.intrinsics.columns.2.y))
        let resolution = CameraInfo.Resolution(x: imageWidth, y: imageHeight)

        let cameraInfo = CameraInfo(
            projectionMatrix: projectionMatrix,
            displayMatrix: displayMatrix,
            focalLength: focalLength,
            principalPoint: principalPoint,
            resolution: resolution
        )

        let metadata = ImageMetadata(
            cameraInfo: cameraInfo,
            timestamp: timestamp,
            imageWidth: imageWidth,
            imageHeight: imageHeight,
            frameNumber: frameNumber
        )

        do {
            let jsonData = try JSONEncoder().encode(metadata)
            return String(data: jsonData, encoding: .utf8)
        } catch {
            print("Failed to encode metadata to JSON: \(error)")
            return nil
        }
    }


}

extension simd_float4x4 {
    var array: [Float] {
        return [
            columns.0.x, columns.0.y, columns.0.z, columns.0.w,
            columns.1.x, columns.1.y, columns.1.z, columns.1.w,
            columns.2.x, columns.2.y, columns.2.z, columns.2.w,
            columns.3.x, columns.3.y, columns.3.z, columns.3.w
        ]
    }
}
