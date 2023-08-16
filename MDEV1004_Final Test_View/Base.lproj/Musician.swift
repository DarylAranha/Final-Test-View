struct Musician: Codable {
    let _id: String
    let music_id: String?
    let fullName: String
    let genres: [String]
    let instruments: [String]
    let labels: [String]
    let born: String
    let yearsActive: String
    let spouses: [String]?
    let children: [String]?
    let relatives: [String]?
    let notableWorks: [String]
    let imageURL: String?
}
