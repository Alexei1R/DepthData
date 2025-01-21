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
        dateFormatter.dateFormat = "HH-mm-ss"
        let currentDate = Date()
        return dateFormatter.string(from: currentDate)
    }

    private var miliUUIDPart: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "SSS"
        let currentDate = Date()
        return "\(dateFormatter.string(from: currentDate))\(UUID().uuidString)"
    }

    private var timestamp: String {
        "\(currentDate)_\(currentTime)_\(miliUUIDPart)"
    }

    func saveImage(_ image: UIImage, arFrame: ARFrame, metadata: ImageMetadata) {
        isScanning = true
        guard let userSettings = localStorage.userSettings else { isScanning = false; return }

        guard let imageData = image.jpegData(compressionQuality: 0.75) else { return }
        let metadata = encodeMetadata(metadata) ?? Data()
        if path == nil {
            //Sessions/Arpalus/NetanyaOffice/netanyaoffice3dev/2025-01-16/2025-01-16_14-03-24/2025-01-16_14-07-48_507d2731e4e8/Images
            path = "Sessions/\(userSettings.client)/\(userSettings.project)/\(userSettings.deployment.lowercased())\(userSettings.settings)/\(currentDate)/\(currentDate)_\(currentTime)/\(timestamp)/Images/"
        }
        guard let path else { isScanning = false; return }
        let currentTimeStamp = timestamp
        let jpgFileName = "\(currentTimeStamp)_number.jpg"
        let metadataFilename = "\(currentTimeStamp)_number.txt"

        let imageRef = storage.reference().child(path + jpgFileName)
        let imageMetadata = StorageMetadata()
        imageMetadata.contentType = "image/jpeg"
        imageMetadata.customMetadata = ["client": userSettings.client]
        let metadataMetadata = StorageMetadata()
        metadataMetadata.contentType = "text/plain"
        metadataMetadata.customMetadata = ["client": userSettings.client]
        let metadataRef = storage.reference().child(path + metadataFilename)
        Task {
            do {
                _ = try await imageRef.putDataAsync(imageData, metadata: imageMetadata)
                _ = try await metadataRef.putDataAsync(metadata, metadata: metadataMetadata)
                self.path =  nil
            } catch {
                print("Error in uploading image: ", error.localizedDescription)
            }
        }
    }

    private func encodeMetadata(_ metadata: ImageMetadata) -> Data? {
        do {
            return try JSONEncoder().encode(metadata)
        } catch {
            print("Failed to encode metadata to JSON: \(error)")
            return nil
        }
    }

    func getCameraInfo(camera: ARCamera, image: UIImage) -> String{
        let cameraInfo = CameraInfo(
            projectionMatrix: Matrix4x4(matrix: camera.projectionMatrix(for: .portrait, viewportSize: image.size, zNear: 0.001, zFar: 1000.0).array),
            displayMatrix: Matrix4x4(matrix: camera.viewMatrix(for: .portrait).array),
            exposureDuration: camera.exposureDuration,
            exposureOffset: Double(camera.exposureOffset),
            focalLength: Point(x: 0.0, y: 0.0), //Test values
            principalPoint: Point(x: 0.0, y: 0.0), //Test values
            resolution: Resolution(x: Int(camera.imageResolution.width), y: Int(camera.imageResolution.height)),
            averageBrightness: 0.0, //Test values
            averageColorTemperature: 0.0, //Test values
            averageIntensityInLumens: 0.0, //Test values
            mainLightIntensityLumens: 0.0, //Test values
            averageMainLightBrightness: 0.0, //Test values
            colorCorrection: RGBA(r: 0, g: 0, b: 0, a: 0), //Test values
            mainLightColor: RGBA(r: 0, g: 0, b: 0, a: 0), //Test values
            mainLightDirection: Vector(x: 0, y: 0, z: 0), //Test values
            ambientSphericalHarmonics: CameraInfo.AmbientSphericalHarmonics(coefficients: [[]]) //Test values
        )

        do {
            let encoder = JSONEncoder()
            let jsonData = try encoder.encode(cameraInfo)
            if let dataString = String(data: jsonData, encoding: .utf8) {
                return dataString
            } else {
                print("Failed to get cameraInfo as String")
            }
        } catch {
            print("Failed to encode cameraInfo to JSON: \(error)")
        }
        return ""
    }

    func calculateColorTemperature(gains: AVCaptureDevice.WhiteBalanceGains) -> Double {
        let temperature = 6500.0 * (gains.redGain + gains.greenGain + gains.blueGain) / 3.0
        return Double(temperature)
    }

    func calculateIntensityInLumens(exposureDuration: CMTime) -> Double {
        let intensity = Double(exposureDuration.seconds) * 1000.0
        return intensity
    }

    func calculateMainLightIntensity(exposureDuration: CMTime) -> Double {
        return Double(exposureDuration.seconds) * 500.0
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
