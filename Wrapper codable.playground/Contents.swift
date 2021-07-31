import UIKit
import PlaygroundSupport

PlaygroundPage.current.needsIndefiniteExecution = true

//MARK: - Simple level:

struct FirstUser: Identifiable, Codable {
    let id: UUID
    let name: String
    let timeZone: TimeZone
}

extension FirstUser {

    struct TimeZoneWrapper: RawRepresentable {
        var rawValue: TimeZone
    }

}

extension FirstUser.TimeZoneWrapper: Codable {

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let identifier = try container.decode(String.self)

        guard let timeZone = TimeZone(identifier: identifier) else {
            throw DecodingError.dataCorruptedError(in: container,
                                                   debugDescription: "Unknown time zone \(identifier)")
        }

        rawValue = timeZone
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue.identifier)
    }

}


//MARK: - Middle level:

@propertyWrapper
struct StringCodedTimeZone {
    var wrappedValue: TimeZone
}

extension StringCodedTimeZone: Codable {
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let identifier = try container.decode(String.self)
        
        guard let timeZone = TimeZone(identifier: identifier) else {
            throw DecodingError.dataCorruptedError(in: container,
                                                   debugDescription: "Unknown identifier \(identifier)")
        }
        wrappedValue = timeZone
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(wrappedValue.identifier)
    }
    
}


struct SecondUser: Identifiable, Codable {
    let id: UUID
    let name: String
    @StringCodedTimeZone var timeZone: TimeZone
}


//MARK: - High level:

protocol CodableByTransform: Codable {
    associatedtype CodingValue: Codable
    static func transformDecodedValue(_ value: CodingValue) throws -> Self?
    static func transformValueForEncoding(_ value: Self) throws -> CodingValue
}

extension CodableByTransform {
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let decodable = try container.decode(CodingValue.self)
    
        guard let value = try Self.transformDecodedValue(decodable) else {
            throw DecodingError.dataCorruptedError(in: container,
                                                   debugDescription: "Unknown value \(decodable)")
        }
        
        self = value
    }
    
    func encode(to encoder: Encoder) throws {
        let encodable = try Self.transformValueForEncoding(self)
        var container = encoder.singleValueContainer()
        try container.encode(encodable)
    }
    
}

@propertyWrapper
struct SecondStringCodedTimeZone: CodableByTransform {
        
    static func transformDecodedValue(_ value: String) throws -> Self? {
        TimeZone(identifier: value).map(Self.init)
    }
    
    static func transformValueForEncoding(_ value: Self) throws -> String {
        value.wrappedValue.identifier
    }
    
    var wrappedValue: TimeZone
    
}

struct ThirdUser: Identifiable, Codable {
    let id: UUID
    let username: String
    @SecondStringCodedTimeZone var timeZone: TimeZone
}
