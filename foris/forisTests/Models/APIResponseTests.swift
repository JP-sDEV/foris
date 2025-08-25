import XCTest
@testable import foris

final class APIResponseTests: XCTestCase {
    
    // MARK: - Test Models
    
    struct TestData: Codable, Equatable {
        let id: Int
        let name: String
    }
    
    // MARK: - Initialization Tests
    
    func testSuccessfulInitialization() {
        // Given
        let testData = TestData(id: 1, name: "Test")
        let message = "Success"
        
        // When
        let response = APIResponse(data: testData, message: message, success: true, statusCode: 200)
        
        // Then
        XCTAssertEqual(response.data, testData)
        XCTAssertEqual(response.message, message)
        XCTAssertTrue(response.success)
        XCTAssertEqual(response.statusCode, 200)
        XCTAssertTrue(response.hasData)
    }
    
    func testErrorInitialization() {
        // Given
        let errorMessage = "Something went wrong"
        let statusCode = 400
        
        // When
        let response: APIResponse<TestData> = APIResponse(error: errorMessage, statusCode: statusCode)
        
        // Then
        XCTAssertNil(response.data)
        XCTAssertEqual(response.message, errorMessage)
        XCTAssertFalse(response.success)
        XCTAssertEqual(response.statusCode, statusCode)
        XCTAssertFalse(response.hasData)
        XCTAssertEqual(response.errorMessage, errorMessage)
    }
    
    func testConvenienceSuccessInitialization() {
        // Given
        let testData = TestData(id: 2, name: "Convenience Test")
        
        // When
        let response = APIResponse(data: testData)
        
        // Then
        XCTAssertEqual(response.data, testData)
        XCTAssertTrue(response.success)
        XCTAssertEqual(response.statusCode, 200)
        XCTAssertTrue(response.hasData)
    }
    
    // MARK: - JSON Decoding Tests
    
    func testSuccessfulJSONDecoding() throws {
        // Given
        let json = """
        {
            "data": {
                "id": 1,
                "name": "Test User"
            },
            "message": "User retrieved successfully",
            "success": true,
            "status_code": 200,
            "timestamp": "2024-01-15T10:30:00Z"
        }
        """
        
        // When
        let jsonData = json.data(using: .utf8)!
        let response = try JSONDecoder().decode(APIResponse<TestData>.self, from: jsonData)
        
        // Then
        XCTAssertEqual(response.data?.id, 1)
        XCTAssertEqual(response.data?.name, "Test User")
        XCTAssertEqual(response.message, "User retrieved successfully")
        XCTAssertTrue(response.success)
        XCTAssertEqual(response.statusCode, 200)
        XCTAssertNotNil(response.timestamp)
        XCTAssertTrue(response.hasData)
    }
    
    func testErrorJSONDecoding() throws {
        // Given
        let json = """
        {
            "data": null,
            "message": "User not found",
            "success": false,
            "status_code": 404
        }
        """
        
        // When
        let jsonData = json.data(using: .utf8)!
        let response = try JSONDecoder().decode(APIResponse<TestData>.self, from: jsonData)
        
        // Then
        XCTAssertNil(response.data)
        XCTAssertEqual(response.message, "User not found")
        XCTAssertFalse(response.success)
        XCTAssertEqual(response.statusCode, 404)
        XCTAssertFalse(response.hasData)
        XCTAssertEqual(response.errorMessage, "User not found")
    }
    
    func testMinimalJSONDecoding() throws {
        // Given - minimal JSON with just data
        let json = """
        {
            "data": {
                "id": 3,
                "name": "Minimal Test"
            }
        }
        """
        
        // When
        let jsonData = json.data(using: .utf8)!
        let response = try JSONDecoder().decode(APIResponse<TestData>.self, from: jsonData)
        
        // Then
        XCTAssertEqual(response.data?.id, 3)
        XCTAssertEqual(response.data?.name, "Minimal Test")
        XCTAssertNil(response.message)
        XCTAssertTrue(response.success) // defaults to true
        XCTAssertNil(response.statusCode)
        XCTAssertTrue(response.hasData)
    }
    
    func testStringDataDecoding() throws {
        // Given - API response with string data
        let json = """
        {
            "data": "Hello World!",
            "message": "String response",
            "success": true
        }
        """
        
        // When
        let jsonData = json.data(using: .utf8)!
        let response = try JSONDecoder().decode(APIResponse<String>.self, from: jsonData)
        
        // Then
        XCTAssertEqual(response.data, "Hello World!")
        XCTAssertEqual(response.message, "String response")
        XCTAssertTrue(response.success)
        XCTAssertTrue(response.hasData)
    }
    
    // MARK: - JSON Encoding Tests
    
    func testJSONEncoding() throws {
        // Given
        let testData = TestData(id: 1, name: "Encode Test")
        let response = APIResponse(data: testData, message: "Encoded successfully", success: true, statusCode: 201)
        
        // When
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let jsonData = try encoder.encode(response)
        let json = String(data: jsonData, encoding: .utf8)!
        
        // Then
        XCTAssertTrue(json.contains("\"id\":1"))
        XCTAssertTrue(json.contains("\"name\":\"Encode Test\""))
        XCTAssertTrue(json.contains("\"message\":\"Encoded successfully\""))
        XCTAssertTrue(json.contains("\"success\":true"))
        XCTAssertTrue(json.contains("\"status_code\":201"))
    }
    
    // MARK: - Convenience Properties Tests
    
    func testHasDataProperty() {
        // Given successful response
        let successResponse = APIResponse(data: TestData(id: 1, name: "Test"), message: "Success", success: true)
        
        // Given failed response
        let failedResponse: APIResponse<TestData> = APIResponse(error: "Failed")
        
        // Given successful response with nil data
        let nilDataResponse: APIResponse<TestData> = APIResponse(data: nil, message: "No data", success: true)
        
        // Then
        XCTAssertTrue(successResponse.hasData)
        XCTAssertFalse(failedResponse.hasData)
        XCTAssertFalse(nilDataResponse.hasData)
    }
    
    func testErrorMessageProperty() {
        // Given response with message
        let responseWithMessage: APIResponse<TestData> = APIResponse(error: "Custom error")
        
        // Given response without message
        let responseWithoutMessage: APIResponse<TestData> = APIResponse(data: nil, message: nil, success: false)
        
        // Then
        XCTAssertEqual(responseWithMessage.errorMessage, "Custom error")
        XCTAssertEqual(responseWithoutMessage.errorMessage, "Unknown error occurred")
    }
    
    func testStatusDescription() {
        // Given successful response
        let successResponse = APIResponse(data: TestData(id: 1, name: "Test"), message: "All good")
        
        // Given successful response without message
        let successNoMessage = APIResponse(data: TestData(id: 1, name: "Test"))
        
        // Given error response
        let errorResponse: APIResponse<TestData> = APIResponse(error: "Something failed")
        
        // Then
        XCTAssertEqual(successResponse.statusDescription, "All good")
        XCTAssertEqual(successNoMessage.statusDescription, "Request completed successfully")
        XCTAssertEqual(errorResponse.statusDescription, "Something failed")
    }
    
    // MARK: - Edge Cases
    
    func testInvalidJSONDecoding() {
        // Given invalid JSON
        let invalidJson = "{ invalid json }"
        
        // When/Then
        let jsonData = invalidJson.data(using: .utf8)!
        XCTAssertThrowsError(try JSONDecoder().decode(APIResponse<TestData>.self, from: jsonData))
    }
    
    func testEmptyJSONDecoding() throws {
        // Given empty object
        let json = "{}"
        
        // When
        let jsonData = json.data(using: .utf8)!
        let response = try JSONDecoder().decode(APIResponse<TestData>.self, from: jsonData)
        
        // Then
        XCTAssertNil(response.data)
        XCTAssertNil(response.message)
        XCTAssertTrue(response.success) // defaults to true
        XCTAssertNil(response.statusCode)
        XCTAssertFalse(response.hasData)
    }
}