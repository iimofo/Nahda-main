struct UserStories: Identifiable {
    let id: String // userId serves as the identifier
    let userId: String
    let stories: [Story]
    
    init(userId: String, stories: [Story]) {
        self.id = userId
        self.userId = userId
        self.stories = stories
    }
} 