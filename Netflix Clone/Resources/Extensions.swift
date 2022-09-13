//
//  Extensions.swift
//  Netflix Clone
//
//  Created by Olajide Osho on 11/09/2022.
//

import Foundation

extension String {
    func capitalizeFirstLetter() -> String {
        return self.prefix(1).uppercased() + self.lowercased().dropFirst()
    }
}
