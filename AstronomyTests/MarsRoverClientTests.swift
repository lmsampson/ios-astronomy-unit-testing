//
//  MarsRoverClientTests.swift
//  AstronomyTests
//
//  Created by Lisa Sampson on 9/17/18.
//  Copyright © 2018 Lambda School. All rights reserved.
//

import XCTest
@testable import Astronomy

class MockLoader: NetworkDataLoader {
    
    init(data: Data? = nil, error: Error? = nil) {
        self.data = data
        self.error = error
    }
    
    func loadData(from request: URLRequest, completion: @escaping (Data?, Error?) -> Void) {
        self.request = request
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            completion(self.data, self.error)
        }
    }
    
    func loadData(from url: URL, completion: @escaping (Data?, Error?) -> Void) {
        self.url = url
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            completion(self.data, self.error)
        }
    }
    
    let data: Data?
    let error: Error?
    private(set) var request: URLRequest? = nil
    private(set) var url: URL? = nil
}

class MarsRoverClientTests: XCTestCase {
    
    enum TestForError: Error {
        case testError
    }
    
    func testFetchMarsRover() {
        let mock = MockLoader(data: validRoverJSON, error: nil)
        let marsRoverClient = MarsRoverClient(dataLoader: mock)
        let expectation = self.expectation(description: "Fetch Mars Rover")
        
        marsRoverClient.fetchMarsRover(named: "Curiosity") { (rover, error) in
            XCTAssertNotNil(mock.url)
            XCTAssertNotNil(rover)
            XCTAssertEqual("Curiosity", rover?.name)
            XCTAssertEqual(4156, rover?.numberOfPhotos)
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            dateFormatter.locale = Locale(identifier: "en_US_POSIX")
            dateFormatter.timeZone = TimeZone(abbreviation: "GMT")
            
            let launchDate = rover.map({ (rover) -> String in
                return dateFormatter.string(from: rover.launchDate)
            })
            let landingDate = rover.map({ (rover) -> String in
                return dateFormatter.string(from: rover.landingDate)
            })
            
            XCTAssertEqual("2011-11-26", launchDate)
            XCTAssertEqual("2012-08-06", landingDate)
            
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testFetchMarsRoverFail() {
        let mock = MockLoader(data: nil, error: TestForError.testError)
        let marsRoverClient = MarsRoverClient(dataLoader: mock)
        let expectation = self.expectation(description: "Fetch Mars Rover")
        
        marsRoverClient.fetchMarsRover(named: "Curiosity") { (rover, error) in
            XCTAssertNotNil(error)
            XCTAssertNil(rover)
            
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testFetchPhotos() {
        let mock = MockLoader(data: validSol1JSON, error: nil)
        let marsRoverClient = MarsRoverClient(dataLoader: mock)
        let expectation = self.expectation(description: "Fetch Photos")
        
        let solDescriptions = [SolDescription]()
        let rover = MarsRover(name: "Curiosity", launchDate: Date(), landingDate: Date(), status: .active, maxSol: 100, maxDate: Date(), numberOfPhotos: 999999, solDescriptions: solDescriptions)
        var photoRefs: [MarsPhotoReference]?

        marsRoverClient.fetchPhotos(from: rover, onSol: 1) { (marsPhotoRefs, error) in
            photoRefs = marsPhotoRefs
            XCTAssertNotNil(mock.url)
            let firstObject = photoRefs!.first
            XCTAssertEqual(firstObject!.id, 4477)
            XCTAssertEqual(firstObject!.sol, 1)
            XCTAssertEqual(firstObject!.camera.id, 22)
            
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testFetchPhotosFail() {
        let mock = MockLoader(data: nil, error: TestForError.testError)
        let marsRoverClient = MarsRoverClient(dataLoader: mock)
        let expectation = self.expectation(description: "Fetch Photos")
        
        let solDescriptions = [SolDescription]()
        let rover = MarsRover(name: "Curiosity", launchDate: Date(), landingDate: Date(), status: .active, maxSol: 100, maxDate: Date(), numberOfPhotos: 999999, solDescriptions: solDescriptions)
        var photoRefs: [MarsPhotoReference]?
        
        marsRoverClient.fetchPhotos(from: rover, onSol: 1) { (marsPhotoRefs, error) in
            photoRefs = marsPhotoRefs
            XCTAssertNotNil(error)
            XCTAssertNil(photoRefs)
            
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
}
