//
//  Collection+Extensions.swift
//  tabTestStoryboards
//
//  Created by Noah Nübling on 16.06.22.
//

import Foundation

extension Collection where Indices.Iterator.Element == Index {
    
    /// Safe subscripts. Src: https://stackoverflow.com/a/37225027
    public subscript (safe index: Index) -> Iterator.Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
