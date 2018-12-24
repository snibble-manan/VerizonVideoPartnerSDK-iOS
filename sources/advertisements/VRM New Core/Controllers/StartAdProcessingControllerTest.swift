//  Copyright 2018, Oath Inc.
//  Licensed under the terms of the MIT License. See LICENSE.md file in project root for terms.
import XCTest
@testable import OathVideoPartnerSDK
@testable import PlayerCore

class StartAdProcessingControllerTest: XCTestCase {
    
    let url = URL(string: "test")!
    let recorder = Recorder()
    
    var sut: StartAdProcessingController!
    
    override func setUp() {
        super.setUp()
        let actionComparator = ActionComparator<VRMCore.AdRequest> {
            $0.type == $1.type && $0.url == $1.url
        }
        let dispatch = recorder.hook("dispatch", cmp: actionComparator.compare)
        
        sut = StartAdProcessingController(dispatch: dispatch)
    }
    
    override func tearDown() {
        recorder.verify {}
        recorder.clean()
        super.tearDown()
    }
    
    func testNoDispatch() {
        recorder.record {
            sut.process(with: nil,
                        isPlaybackInitiated: true,
                        sessionID: UUID())
            
            sut.process(with: url,
                        isPlaybackInitiated: false,
                        sessionID: UUID())
        }
        recorder.verify {}
    }
    
    func testDiffSessions() {
        recorder.record {
            sut.process(with: url,
                        isPlaybackInitiated: true,
                        sessionID: UUID())
            
            sut.process(with: url,
                        isPlaybackInitiated: true,
                        sessionID: UUID())
        }
        
        recorder.verify {
            sut.dispatch(PlayerCore.VRMCore.AdRequest(url: url, id: UUID(), type: .preroll))
            sut.dispatch(PlayerCore.VRMCore.AdRequest(url: url, id: UUID(), type: .preroll))
        }
    }
    
    func testSecondDisptach() {
        recorder.record {
            let sessionID = UUID()
            sut.process(with: url,
                        isPlaybackInitiated: true,
                        sessionID: sessionID)
            
            sut.process(with: url,
                        isPlaybackInitiated: true,
                        sessionID: sessionID)
        }
        
        recorder.verify {
            sut.dispatch(PlayerCore.VRMCore.AdRequest(url: url, id: UUID(), type: .preroll))
        }
    }
    
    func testCorrectDispatch() {
        recorder.record {
            sut.process(with: url,
                        isPlaybackInitiated: true,
                        sessionID: UUID())
        }
        
        recorder.verify {
            sut.dispatch(PlayerCore.VRMCore.AdRequest(url: url, id: UUID(), type: .preroll))
        }
    }
}
