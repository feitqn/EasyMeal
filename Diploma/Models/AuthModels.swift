import Foundation

struct AuthUser {
    var username: String
    var email: String
    var password: String
}

// Удалите этот enum, так как он уже определен в AuthError.swift
// enum AuthError: Error {
//     case invalidEmail
//     case invalidPassword
//     ...
// } 