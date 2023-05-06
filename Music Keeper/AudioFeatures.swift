//
//  AudioFeatures.swift
//  Music Keeper
//
//  Created by Zhi'en Foo on 05/05/2023.
//

import Foundation

struct AudioFeatures: Codable {
    let danceability: Double
    let energy: Double
    let key: Int
    let loudness: Double
    let mode: Int
    let speechiness: Double
    let acousticness: Double
    let instrumentalness: Double
    let liveness: Double
    let valence: Double
    let tempo: Double
    let type: String
    let id: String
    let uri: String
    let trackHref: String
    let analysisUrl: String
    let durationMs: Int
    let timeSignature: Int
    
    init(dictionary: [String: Any]) {
        danceability = dictionary["danceability"] as? Double ?? 0.0
        energy = dictionary["energy"] as? Double ?? 0.0
        key = dictionary["key"] as? Int ?? 0
        loudness = dictionary["loudness"] as? Double ?? 0.0
        mode = dictionary["mode"] as? Int ?? 0
        speechiness = dictionary["speechiness"] as? Double ?? 0.0
        acousticness = dictionary["acousticness"] as? Double ?? 0.0
        instrumentalness = dictionary["instrumentalness"] as? Double ?? 0.0
        liveness = dictionary["liveness"] as? Double ?? 0.0
        valence = dictionary["valence"] as? Double ?? 0.0
        tempo = dictionary["tempo"] as? Double ?? 0.0
        type = dictionary["type"] as? String ?? ""
        id = dictionary["id"] as? String ?? ""
        uri = dictionary["uri"] as? String ?? ""
        trackHref = dictionary["track_href"] as? String ?? ""
        analysisUrl = dictionary["analysis_url"] as? String ?? ""
        durationMs = dictionary["duration_ms"] as? Int ?? 0
        timeSignature = dictionary["time_signature"] as? Int ?? 0
    }
}


//struct AudioFeatures: Codable {
//    /**
//    * Danceability describes how suitable a track is for dancing based on a combination of musical elements including tempo, rhythm stability, beat strength, and overall regularity.
//    * A value of 0.0 is least danceable and 1.0 is most danceable.
//    */
//    let danceability: Float
//
//    /**
//    * Energy is a measure from 0.0 to 1.0 and represents a perceptual measure of intensity and activity.
//    * Typically, energetic tracks feel fast, loud, and noisy. For example, death metal has high energy, while a Bach prelude scores low on the scale.
//    * Perceptual features contributing to this attribute include dynamic range, perceived loudness, timbre, onset rate, and general entropy.
//    */
//    let energy: Float
//
//    /**
//    * The key the track is in. Integers map to pitches using standard Pitch Class notation.
//    * E.g. 0 = C, 1 = C♯/D♭, 2 = D, and so on.
//    */
//    let key: Int
//
//    /**
//    * The overall loudness of a track in decibels (dB). Loudness values are averaged across the entire track and are useful for comparing relative loudness of tracks.
//    * Loudness is the quality of a sound that is the primary psychological correlate of physical strength (amplitude). Values typical range between -60 and 0 db.
//    */
//    let loudness: Float
//
//    /**
//    * Mode indicates the modality (major or minor) of a track, the type of scale from which its melodic content is derived.
//    * Major is represented by 1 and minor is 0.
//    */
//    let mode: Int
//
//    /**
//    * Speechiness detects the presence of spoken words in a track. The more exclusively speech-like the recording (e.g. Talk show, audio book, poetry), the closer to 1.0 the attribute value.
//    * Values above 0.66 describe tracks that are probably made entirely of spoken words. Values between 0.33 and 0.66 describe tracks that may contain both music and speech, either in sections or layered, including such cases as rap music.
//    * Values below 0.33 most likely represent music and other non-speech-like tracks.
//    */
//    let speechiness: Float
//
//    /**
//    * A confidence measure from 0.0 to 1.0 of whether the track is acoustic. 1.0 represents high confidence the track is acoustic.
//    */
//    let acousticness: Float
//
//    /**
//    * Predicts whether a track contains no vocals. "Ooh" and "aah" sounds are treated as instrumental in this context.
//    * Rap or spoken word tracks are clearly "vocal". The closer the instrumentalness value is to 1.0, the greater likelihood the track contains no vocal content.
//    * Values above 0.5 are intended to represent instrumental tracks, but confidence is higher as the value approaches 1.0.
//    */
//    let instrumentalness: Float
//
//    /**
//    * Detects the presence of an audience in the recording. Higher liveness values represent an increased probability that the track was performed live.
//    * A value above 0.8 provides strong likelihood that the track is live.
//    */
//    let liveness: Float
//
//    /**
//    * A measure from 0.0 to 1.0 describing the musical positiveness conveyed by a track. Tracks with high valence sound more positive (e.g. Happy, cheerful, euphoric), while tracks with low valence sound more negative (e.g. Sad, depressed, angry).
//    */
//    let valence: Float
//
//    /**
//    * The overall estimated tempo of a track in beats per minute (BPM). In musical terminology, tempo is the speed or pace of a given piece and derives directly from the average beat duration.
//    */
//    let tempo: Float
//
//    /**
//    * The object type.
//    */
//    let type: String
//
//    /**
//    * The Spotify ID for the track.
//    */
//    let id: String
//
//    /**
//    * The Spotify URI for the track.
//    */
//    let uri: String
//
//    /**
//    * A link to the Web API endpoint providing full details of the track.
//    */
//    let track_href: String
//
//    /**
//    * A URL to access the full audio analysis of this track. An access token is required to access this data.
//    */
//    let analysis_url: String
//
//    /**
//    * The duration of the track in milliseconds.
//    */
//    let duration_ms: Int
//
//    /**
//    * An estimated overall time signature of a track. The time signature (meter) is a notational convention to specify how many beats are in each bar (or measure).
//    */
//    let time_signature: Int
//}
