//  Copyright 2018, Oath Inc.
//  Licensed under the terms of the MIT License. See LICENSE.md file in project root for terms.

import Foundation
import PlayerCore

struct VASTWrapperProcessor {
    let innerParse: (String) -> Future<VASTTagProcessor.Result>
    let innerFetch: (URL) -> Future<VASTTagProcessor.Result>
    
    enum Result {
        case model(PlayerCore.Ad.VASTModel)
        case timeoutError
        case parsingError
        case tooManyIndirections
        case otherError(Error)
    }
    
    func parseTag(from string: String) -> Future<Result> {
        return innerParse(string).then(process)
    }
    
    func fetchTag(from url: URL) -> Future<Result> {
        return innerFetch(url).then(process)
    }
    
    private func process(result: VASTTagProcessor.Result) -> Future<Result> {
        switch result {
        
        case .error(let error): return Future(value: .otherError(error))
        case .timeout: return Future(value: .timeoutError)
        case .parsingError: return Future(value: .parsingError)
        case .model(.inline(let model)): return Future(value: .model(model))
        case .model(.wrapper(let wrapper1)):
            return self.innerFetch(wrapper1.tagURL).then { result in
                switch result {
                case .error(let error): return Future(value: .otherError(error))
                case .timeout: return Future(value: .timeoutError)
                case .parsingError: return Future(value: .parsingError)
                case .model(.inline(let model)):
                    return Future(value: .model(model.merge(pixels: wrapper1.pixels, verifications: wrapper1.adVerifications, adProgress: wrapper1.progress)))
                    
                case .model(.wrapper(let wrapper2)):
                    return self.innerFetch(wrapper2.tagURL).then { result in
                        switch result {
                        case .error(let error): return Future(value: .otherError(error))
                        case .timeout: return Future(value: .timeoutError)
                        case .parsingError: return Future(value: .parsingError)
                        case .model(.inline(let model)):
                            return Future(value: .model(
                                model.merge(pixels: wrapper1.pixels, verifications: wrapper1.adVerifications, adProgress: wrapper1.progress)
                                    .merge(pixels: wrapper2.pixels, verifications: wrapper2.adVerifications, adProgress: wrapper2.progress))
                            )

                        case .model(.wrapper): return Future(value: .tooManyIndirections)
                        }
                    }
                }
            }
        }
    }
}
