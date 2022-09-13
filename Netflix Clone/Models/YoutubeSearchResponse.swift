//
//  YoutubeSearchResponse.swift
//  Netflix Clone
//
//  Created by Olajide Osho on 12/09/2022.
//

import Foundation

struct YoutubeSearchResponse: Codable {
    let items: [VideoElement]
}

struct VideoElement: Codable {
    let id: VideoElementID
}

struct VideoElementID: Codable {
    let kind: String
    let videoId: String
}
