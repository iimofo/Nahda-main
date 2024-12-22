//
//  FirebaseService.swift
//  Nahda
//
//  Created by mofo on 01.12.2024.
//
// FirebaseService.swift

import FirebaseFirestore
import FirebaseFirestore

class FirebaseService {
    static let shared = FirebaseService()
    private init() {}

    let db = Firestore.firestore()
}
