import Foundation

enum Constants {
    static let termsOfServiceURL = "https://your-app.com/terms"
    static let privacyPolicyURL = "https://your-app.com/privacy"
    static let appVersion = "1.0.0"
    
    enum Firebase {
        static let usersCollection = "users"
        static let recipesCollection = "recipes"
        static let workoutsCollection = "workouts"
        static let exercisesCollection = "exercises"
        static let verificationCodesCollection = "verificationCodes"
    }
    
    static let appName = "EasyMeal"
    
    enum ErrorMessages {
        static let loginFailed = "Ошибка входа"
        static let registrationFailed = "Ошибка регистрации"
        static let googleSignInFailed = "Ошибка входа через Google"
        static let invalidEmail = "Пожалуйста, введите корректный email"
        static let emailInUse = "Этот email уже зарегистрирован"
        static let weakPassword = "Пароль должен содержать минимум 6 символов"
        static let invalidCode = "Неверный или просроченный код подтверждения"
        static let unknownError = "Произошла неизвестная ошибка"
    }
    
    static let verificationCodeLength = 6
    static let verificationCodeExpiration = 600 // 10 минут в секундах
    
    enum Collections {
        static let users = Firebase.usersCollection
        static let verificationCodes = Firebase.verificationCodesCollection
        static let workouts = Firebase.workoutsCollection
        static let exercises = Firebase.exercisesCollection
        static let nutrition = "nutrition"
    }
    
    enum EmailTemplates {
        static let verificationSubject = "Ваш код подтверждения EasyMeal"
        static let supportEmail = "support@easymeal.com"
    }
    
    enum Links {
        static let termsOfService = URL(string: termsOfServiceURL)!
        static let privacyPolicy = URL(string: privacyPolicyURL)!
    }
    
    enum Storage {
        static let userAvatars = "userAvatars"
        static let exerciseImages = "exerciseImages"
        static let workoutVideos = "workoutVideos"
    }
    
    enum Cache {
        static let maxSize = 50 * 1024 * 1024 // 50 MB
        static let expirationInterval: TimeInterval = 7 * 24 * 60 * 60 // 7 дней
    }
    
    enum CoreData {
        static let modelName = "EasyMeal"
        
        enum Entity {
            static let user = "CDUser"
            static let workout = "CDWorkout"
            static let exercise = "CDExercise"
            static let meal = "CDMeal"
            static let product = "CDProduct"
        }
    }
} 