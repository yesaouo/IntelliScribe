import NaturalLanguage

func areSentencesSimilar(sentence1: String, sentence2: String, threshold: Double = 0.65) -> Bool {
    let embedding1 = NLEmbedding.sentenceEmbedding(for: .english)
    let embedding2 = NLEmbedding.sentenceEmbedding(for: .english)
    
    guard let vector1 = embedding1?.vector(for: sentence1),
          let vector2 = embedding2?.vector(for: sentence2) else {
        return false
    }
    
    let similarity = cosineSimilarity(vector1: vector1, vector2: vector2)
    print(similarity)
    return similarity >= threshold
}

func cosineSimilarity(vector1: [Double], vector2: [Double]) -> Double {
    let dotProduct = zip(vector1, vector2).map(*).reduce(0, +)
    let magnitude1 = sqrt(vector1.map { $0 * $0 }.reduce(0, +))
    let magnitude2 = sqrt(vector2.map { $0 * $0 }.reduce(0, +))
    return dotProduct / (magnitude1 * magnitude2)
}
