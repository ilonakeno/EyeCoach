//
//  ImagePicker.swift
//  EyeGym
//
//  Created by Ilona Keno on 27.03.2026.
//

import SwiftUI
import UIKit

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var selectedImageData: Data?
    @Environment(\.presentationMode) var presentationMode

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.allowsEditing = true // 🔥 САМЕ ЦЕ ВКЛЮЧАЄ ОБРІЗКУ ТА ЦЕНТРУВАННЯ!
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            // Беремо ВЖЕ ОБРІЗАНЕ фото (editedImage)
            if let editedImage = info[.editedImage] as? UIImage {
                // Стискаємо, щоб не забивати пам'ять телефону
                parent.selectedImageData = editedImage.jpegData(compressionQuality: 0.5)
            }
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}
