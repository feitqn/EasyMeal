import Foundation

enum AuthError: LocalizedError, Identifiable, Equatable {
    case invalidEmail
    case invalidPassword
    case userNotFound
    case emailAlreadyInUse
    case weakPassword
    case unknown
    case invalidCode
    case expiredCode
    case networkError(reason: NetworkErrorReason)
    case timeout
    case noConnection
    case serverError
    case configurationError
    case presentationError
    case invalidToken
    case userCancelled
    case notAuthenticated
    case googleSignInError
    case firebaseAuthError
    
    enum NetworkErrorReason: Equatable {
        case noConnection
        case timeout
        case other
    }
    
    var id: String { errorDescription ?? "" }
    
    var errorDescription: String? {
        switch self {
        case .invalidEmail:
            return "Неверный формат email адреса"
        case .invalidPassword:
            return "Неверный пароль. Пожалуйста, проверьте правильность ввода"
        case .userNotFound:
            return "Пользователь с такими данными не найден"
        case .emailAlreadyInUse:
            return "Этот email уже используется другим пользователем"
        case .weakPassword:
            return "Слишком слабый пароль. Минимум 6 символов"
        case .invalidCode:
            return "Неверный код подтверждения"
        case .expiredCode:
            return "Срок действия кода истек"
        case .networkError(let reason):
            switch reason {
            case .noConnection:
                return "Отсутствует подключение к интернету"
            case .timeout:
                return "Превышено время ожидания"
            case .other:
                return "Ошибка подключения к интернету"
            }
        case .timeout:
            return "Превышено время ожидания"
        case .noConnection:
            return "Отсутствует подключение к интернету"
        case .serverError:
            return "Ошибка сервера. Попробуйте позже"
        case .configurationError:
            return "Ошибка конфигурации Google Sign In"
        case .presentationError:
            return "Ошибка представления Google Sign In"
        case .invalidToken:
            return "Неверный токен"
        case .userCancelled:
            return "Вход был отменен пользователем"
        case .notAuthenticated:
            return "Пользователь не аутентифицирован"
        case .googleSignInError:
            return "Ошибка входа через Google"
        case .firebaseAuthError:
            return "Ошибка аутентификации в Firebase"
        case .unknown:
            return "Произошла неизвестная ошибка. Пожалуйста, попробуйте позже"
        }
    }
    
    var failureReason: String? {
        switch self {
        case .invalidEmail:
            return "Проверьте правильность написания email адреса"
        case .invalidPassword:
            return "Введенный пароль неверен"
        case .userNotFound:
            return "Пользователь с такими учетными данными не найден"
        case .emailAlreadyInUse:
            return "Аккаунт с таким email уже существует"
        case .weakPassword:
            return "Пароль не соответствует требованиям безопасности"
        case .invalidCode:
            return "Код подтверждения неверен или устарел"
        case .expiredCode:
            return "Код верификации больше не действителен"
        case .networkError(let reason):
            switch reason {
            case .noConnection:
                return "Отсутствует подключение к интернету"
            case .timeout:
                return "Превышено время ожидания"
            case .other:
                return "Проблема с сетевым подключением"
            }
        case .timeout:
            return "Превышено время ожидания запроса"
        case .noConnection:
            return "Отсутствует подключение к сети"
        case .serverError:
            return "Сервер временно недоступен"
        case .configurationError:
            return "Неправильная конфигурация приложения"
        case .presentationError:
            return "Не удалось показать окно входа"
        case .invalidToken:
            return "Полученный токен недействителен"
        case .userCancelled:
            return "Процесс входа был прерван пользователем"
        case .notAuthenticated:
            return "Требуется повторная аутентификация"
        case .googleSignInError:
            return "Проблема при входе через Google"
        case .firebaseAuthError:
            return "Проблема при аутентификации в Firebase"
        case .unknown:
            return "Произошла непредвиденная ошибка"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .invalidEmail:
            return "Введите корректный email адрес"
        case .invalidPassword:
            return "Проверьте правильность ввода пароля и попробуйте снова"
        case .userNotFound:
            return "Проверьте введенные данные или создайте новый аккаунт"
        case .emailAlreadyInUse:
            return "Используйте другой email или войдите в существующий аккаунт"
        case .weakPassword:
            return "Используйте не менее 6 символов, включая буквы и цифры"
        case .invalidCode:
            return "Проверьте код и попробуйте снова, или запросите новый код"
        case .expiredCode:
            return "Пожалуйста, запросите новый код верификации"
        case .networkError(let reason):
            switch reason {
            case .noConnection:
                return "Проверьте подключение к интернету и попробуйте снова"
            case .timeout:
                return "Подождите немного и попробуйте снова"
            case .other:
                return "Проверьте подключение к интернету и попробуйте снова"
            }
        case .timeout:
            return "Подождите немного и повторите попытку"
        case .noConnection:
            return "Проверьте подключение к интернету"
        case .serverError:
            return "Подождите немного и попробуйте снова"
        case .configurationError:
            return "Попробуйте войти через email и пароль"
        case .presentationError:
            return "Попробуйте войти через email и пароль"
        case .invalidToken:
            return "Попробуйте войти заново"
        case .userCancelled:
            return "Попробуйте войти снова, когда будете готовы"
        case .notAuthenticated:
            return "Пожалуйста, войдите в аккаунт"
        case .googleSignInError:
            return "Попробуйте войти через email и пароль"
        case .firebaseAuthError:
            return "Попробуйте войти позже или используйте другой метод входа"
        case .unknown:
            return "Попробуйте повторить попытку позже"
        }
    }
    
    static func == (lhs: AuthError, rhs: AuthError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidEmail, .invalidEmail),
             (.invalidPassword, .invalidPassword),
             (.userNotFound, .userNotFound),
             (.emailAlreadyInUse, .emailAlreadyInUse),
             (.weakPassword, .weakPassword),
             (.unknown, .unknown),
             (.invalidCode, .invalidCode),
             (.expiredCode, .expiredCode),
             (.timeout, .timeout),
             (.noConnection, .noConnection),
             (.serverError, .serverError),
             (.configurationError, .configurationError),
             (.presentationError, .presentationError),
             (.invalidToken, .invalidToken),
             (.userCancelled, .userCancelled),
             (.notAuthenticated, .notAuthenticated),
             (.googleSignInError, .googleSignInError),
             (.firebaseAuthError, .firebaseAuthError):
            return true
        case let (.networkError(reason1), .networkError(reason2)):
            return reason1 == reason2
        default:
            return false
        }
    }
} 