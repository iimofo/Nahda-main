//
//  ImageUploader.swift
//  Nahda
//
//  Created by mofo on 01.12.2024.
//
// ImageUploader.swift

import UIKit
import FirebaseStorage

class ImageUploader {
    static func uploadImage(_ image: UIImage, completion: @escaping (Result<String, Error>) -> Void) {
        let filename = UUID().uuidString
        let ref = Storage.storage().reference(withPath: "/task_images/\(filename).jpg")
        guard let imageData = image.jpegData(compressionQuality: 0.75) else { return }

        ref.putData(imageData, metadata: nil) { _, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            ref.downloadURL { url, error in
                if let error = error {
                    completion(.failure(error))
                } else if let imageUrl = url?.absoluteString {
                    completion(.success(imageUrl))
                }
            }
        }
    }
}
