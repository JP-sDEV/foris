import XCTest
@testable import foris

final class HelloResponseTests: XCTestCase {
    
    // MARK: - Initialization Tests
    
    func testInitializationWithMessage() {
        // Given
        let message = "Custom Hello Message"
        
        // When
        let response = HelloResponse(message: message)
        
        // Then
        XCTAssertEqual(response.message, message)
        XCTAssertTrue(response.isValid)
        XCTAssertFalse(response.isDefaultMessage)
    }
    
    func testDefaultInitialization() {
        // When
        let response = HelloResponse()
        
        // Then
        XCTAssertEqual(response.message, "Hello World!")
        XCTAssertTrue(response.isValid)
        XCTAssertTrue(response.isDefaultMessage)
    }
    
    // MARK: - JSON Decoding Tests
    
    func testDecodingFromDirectString() throws {
        // Given - Direct string response (as returned by NestJS backend)
        let jsonString = "\"Hello World!\""
        
        // When
        let jsonData = jsonString.data(using: .utf8)!
        let response = try JSONDecoder().decode(HelloResponse.self, from: jsonData)
        
        // Then
        XCTAssertEqual(response.message, "Hello World!")
        XCTAssertTrue(response.isValid)
        XCTAssertTrue(response.isDefaultMessage)
    }
    
    func testDecodingFromObjectFormat() throws {
        // Given - Object format with message property
        let json = """
        {
            "message": "Hello from API!"
        }
        """
        
        // When
        let jsonData = json.data(using: .utf8)!
        let response = try JSONDecoder().decode(HelloResponse.self, from: jsonData)
        
        // Then
        XCTAssertEqual(response.message, "Hello from API!")
        XCTAssertTrue(response.isValid)
        XCTAssertFalse(response.isDefaultMessage)
    }
    
    func testDecodingCustomMessage() throws {
        // Given
        let customMessage = "Greetings from the backend!"
        let jsonString = "\"\(customMessage)\""
        
        // When
        let jsonData = jsonString.data(using: .utf8)!
        let response = try JSONDecoder().decode(HelloResponse.self, from: jsonData)
        
        // Then
        XCTAssertEqual(response.message, customMessage)
        XCTAssertTrue(response.isValid)
        XCTAssertFalse(response.isDefaultMessage)
    }
    
    func testDecodingEmptyString() throws {
        // Given
        let jsonString = "\"\""
        
        // When
        let jsonData = jsonString.data(using: .utf8)!
        let response = try JSONDecoder().decode(HelloResponse.self, from: jsonData)
        
        // Then
        XCTAssertEqual(response.message, "")
        XCTAssertFalse(response.isValid)
        XCTAssertFalse(response.isDefaultMessage)
    }
    
    // MARK: - JSON Encoding Tests
    
    func testEncodingToJSON() throws {
        // Given
        let response = HelloResponse(message: "Test Message")
        
        // When
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        let jsonData = try encoder.encode(response)
        let jsonString = String(data: jsonData, encoding: .utf8)!
        
        // Then
        XCTAssertTrue(jsonString.contains("\"message\":\"Test Message\""))
    }
    
    func testEncodingDefaultResponse() throws {
        // Given
        let response = HelloResponse()
        
        // When
        let jsonData = try JSONEncoder().encode(response)
        let jsonString = String(data: jsonData, encoding: .utf8)!
        
        // Then
        XCTAssertTrue(jsonString.contains("\"message\":\"Hello World!\""))
    }
    
    // MARK: - Convenience Properties Tests
    
    func testIsValidProperty() {
        // Given
        let validResponse = HelloResponse(message: "Valid message")
        let emptyResponse = HelloResponse(message: "")
        let whitespaceResponse = HelloResponse(message: "   ")
        
        // Then
        XCTAssertTrue(validResponse.isValid)
        XCTAssertFalse(emptyResponse.isValid)
        XCTAssertTrue(whitespaceResponse.isValid) // whitespace is considered valid
    }
    
    func testDisplayMessageProperty() {
        // Given
        let messageWithWhitespace = "  Hello World!  \n"
        let response = HelloResponse(message: messageWithWhitespace)
        
        // When
        let displayMessage = response.displayMessage
        
        // Then
        XCTAssertEqual(displayMessage, "Hello World!")
    }
    
    func testIsDefaultMessageProperty() {
        // Given
        let defaultResponse = HelloResponse()
        let customResponse = HelloResponse(message: "Custom message")
        let exactMatchResponse = HelloResponse(message: "Hello World!")
        
        // Then
        XCTAssertTrue(defaultResponse.isDefaultMessage)
        XCTAssertFalse(customResponse.isDefaultMessage)
        XCTAssertTrue(exactMatchResponse.isDefaultMessage)
    }
    
    // MARK: - Static Factory Methods Tests
    
    func testFromStringFactory() {
        // Given
        let testString = "Factory created message"
        
        // When
        let response = HelloResponse.fromString(testString)
        
        // Then
        XCTAssertEqual(response.message, testString)
        XCTAssertTrue(response.isValid)
    }
    
    func testDefaultFactory() {
        // When
        let response = HelloResponse.default()
        
        // Then
        XCTAssertEqual(response.message, "Hello World!")
        XCTAssertTrue(response.isDefaultMessage)
    }
    
    func testMockFactory() {
        // When
        let defaultMock = HelloResponse.mock()
        let customMock = HelloResponse.mock(message: "Custom mock")
        
        // Then
        XCTAssertEqual(defaultMock.message, "Mock Hello Response")
        XCTAssertEqual(customMock.message, "Custom mock")
    }
    
    // MARK: - Equatable Tests
    
    func testEquality() {
        // Given
        let response1 = HelloResponse(message: "Same message")
        let response2 = HelloResponse(message: "Same message")
        let response3 = HelloResponse(message: "Different message")
        
        // Then
        XCTAssertEqual(response1, response2)
        XCTAssertNotEqual(response1, response3)
        XCTAssertNotEqual(response2, response3)
    }
    
    // MARK: - Hashable Tests
    
    func testHashable() {
        // Given
        let response1 = HelloResponse(message: "Test message")
        let response2 = HelloResponse(message: "Test message")
        let response3 = HelloResponse(message: "Different message")
        
        // When
        let set: Set<HelloResponse> = [response1, response2, response3]
        
        // Then
        XCTAssertEqual(set.count, 2) // response1 and response2 should be considered the same
    }
    
    // MARK: - CustomStringConvertible Tests
    
    func testDescription() {
        // Given
        let response = HelloResponse(message: "Test description")
        
        // When
        let description = response.description
        
        // Then
        XCTAssertEqual(description, "HelloResponse(message: \"Test description\")")
    }
    
    // MARK: - Integration with APIResponse Tests
    
    func testWithAPIResponseWrapper() throws {
        // Given
        let helloResponse = HelloResponse(message: "API wrapped message")
        let apiResponse = APIResponse(data: helloResponse, message: "Success")
        
        // When
        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(apiResponse)
        let decodedResponse = try JSONDecoder().decode(APIResponse<HelloResponse>.self, from: jsonData)
        
        // Then
        XCTAssertEqual(decodedResponse.data?.message, "API wrapped message")
        XCTAssertTrue(decodedResponse.success)
        XCTAssertTrue(decodedResponse.hasData)
    }
    
    // MARK: - Error Handling Tests
    
    func testInvalidJSONDecoding() {
        // Given
        let invalidJson = "{ invalid json }"
        
        // When/Then
        let jsonData = invalidJson.data(using: .utf8)!
        XCTAssertThrowsError(try JSONDecoder().decode(HelloResponse.self, from: jsonData))
    }
    
    func testNullJSONDecoding() {
        // Given
        let nullJson = "null"
        
        // When/Then
        let jsonData = nullJson.data(using: .utf8)!
        XCTAssertThrowsError(try JSONDecoder().decode(HelloResponse.self, from: jsonData))
    }
    
    // MARK: - Real Backend Response Simulation Tests
    
    func testRealBackendResponseSimulation() throws {
        // Given - Simulating the actual NestJS backend response
        let backendResponse = "Hello World!"
        let jsonString = "\"\(backendResponse)\""
        
        // When
        let jsonData = jsonString.data(using: .utf8)!
        let response = try JSONDecoder().decode(HelloResponse.self, from: jsonData)
        
        // Then
        XCTAssertEqual(response.message, backendResponse)
        XCTAssertTrue(response.isValid)
        XCTAssertTrue(response.isDefaultMessage)
        XCTAssertEqual(response.displayMessage, backendResponse)
    }
}