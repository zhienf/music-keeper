//
//  AudioFeatures.swift
//  Music Keeper
//
//  Created by Zhi'en Foo on 05/05/2023.
//

import Foundation

/**
 A model representing audio features of a track.

 This struct conforms to the Codable protocol to provide easy encoding and decoding of audio features from JSON.

 Usage:
 1. Initialize an instance of `AudioFeatures` by passing a dictionary representing the audio features.
 2. Access the properties to retrieve specific audio feature values.
 */
struct AudioFeatures: Codable {
    // Danceability describes how suitable a track is for dancing based on a combination of musical elements including tempo, rhythm stability, beat strength, and overall regularity. A value of 0.0 is least danceable and 1.0 is most danceable.
    let danceability: Double
    
    // Energy is a measure from 0.0 to 1.0 and represents a perceptual measure of intensity and activity.
    let energy: Double
    
    // The key the track is in. Integers map to pitches using standard Pitch Class notation. E.g. 0 = C, 1 = C♯/D♭, 2 = D...
    let key: Int
    
    // Mode indicates the modality (major or minor) of a track. Major is represented by 1 and minor is 0.
    let mode: Int
    
    // Speechiness detects the presence of spoken words in a track. The more exclusively speech-like the recording (e.g. talk show, audio book, poetry), the closer to 1.0 the attribute value.
    let speechiness: Double
    
    // A confidence measure from 0.0 to 1.0 of whether the track is acoustic. 1.0 represents high confidence the track is acoustic.
    let acousticness: Double
    
    // Predicts whether a track contains no vocals. The closer the instrumentalness value is to 1.0, the greater likelihood the track contains no vocal content.
    let instrumentalness: Double
    
    // Detects the presence of an audience in the recording. Higher liveness values represent an increased probability that the track was performed live.
    let liveness: Double
    
    // A measure from 0.0 to 1.0 describing the musical positiveness conveyed by a track. Tracks with high valence sound more positive, while tracks with low valence sound more negative.
    let valence: Double
    
    // The overall estimated tempo of a track in beats per minute (BPM).
    let tempo: Double
    
    let id: String
    
    let uri: String
    
    init(dictionary: [String: Any]) {
        danceability = dictionary["danceability"] as? Double ?? 0.0
        energy = dictionary["energy"] as? Double ?? 0.0
        key = dictionary["key"] as? Int ?? 0
        mode = dictionary["mode"] as? Int ?? 0
        speechiness = dictionary["speechiness"] as? Double ?? 0.0
        acousticness = dictionary["acousticness"] as? Double ?? 0.0
        instrumentalness = dictionary["instrumentalness"] as? Double ?? 0.0
        liveness = dictionary["liveness"] as? Double ?? 0.0
        valence = dictionary["valence"] as? Double ?? 0.0
        tempo = dictionary["tempo"] as? Double ?? 0.0
        id = dictionary["id"] as? String ?? ""
        uri = dictionary["uri"] as? String ?? ""
    }
}
