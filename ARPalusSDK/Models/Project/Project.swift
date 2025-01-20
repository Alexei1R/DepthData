import Foundation

//MARK: - Arrays type can be not string
struct Project: Codable, Equatable {
    var clientName: String
    var projectName: String
    var index: Int
    var storesDefinitions: [StoreDefinition]
    var storeLocations: [StoreLocation]
    var storeTasks: [StoreTask]
    var storeDisplays: [StoreDisplay]
//    var questionSelections: []
//    var questionOptions: []
    var clientDisplayName: String
    var slackChannelProduction: String
    var slackChannelProducts: String
    var localization: String
    var stores: [ProjectStore]
    var products: [ProjectProduct]
//    var cvProductSizeGroups: []
}



struct ProjectStore: Codable, Equatable {
    var storeName: String
    var localizedStoreName: String
    var id: String
    var index: Int
    var GPSLocationX: Double
    var GPSLocationY: Double
    var GPSLocationZ: Double
    var fade: Bool
    var address: String
    var storeId: String
    var models: ProjectModels
    var planogramNames: [String]
}

struct ProjectModels: Codable, Equatable {
    var modelNames: [String]
}

struct ProjectProduct: Codable, Equatable {
    var packageId: String
    var barcode: String
    var id: String
    var description: String
    var brand: String
    var size: String
    var category: String
    var subCategory: String
    var isHanging: Bool
    var isNewProduct: Bool
    var isPowerSku: Bool
    var isHero: Bool
    var isInnovation: Bool
    var dimentions: ProductDimensions
    var details: [ProductDetails]
}

struct ProductDimensions: Codable, Equatable {
    var x: Double
    var y: Double
    var z: Double
}

struct ProductDetails: Codable, Equatable {
    var name: String
    var value: String
}

struct CVProductSizes: Codable, Equatable {
    var productSizes: [String]
}
