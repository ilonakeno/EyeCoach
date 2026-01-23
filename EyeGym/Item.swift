//
//  Item.swift
//  EyeGym
//
//  Created by Ilona Keno on 23.01.2026.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
