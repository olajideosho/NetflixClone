//
//  DataPersistenceManager.swift
//  Netflix Clone
//
//  Created by Olajide Osho on 13/09/2022.
//

import Foundation
import CoreData

enum DatabaseError: Error {
    case failedToSaveData
    case failedToFetchData
    case failedToDeleteData
}
class DataPersistenceManager {

    static let shared = DataPersistenceManager()

    func downloadItemWith(model: Title, completion: @escaping (Result<Void, Error>) -> Void) {
        let context = persistentContainer.viewContext

        let titleItem = TitleItem(context: context)

        titleItem.id = Int64(model.id)
        titleItem.media_type = model.media_type
        titleItem.original_name = model.original_name
        titleItem.original_title = model.original_title
        titleItem.poster_path = model.poster_path
        titleItem.overview = model.overview
        titleItem.vote_count = Int64(model.vote_count)
        titleItem.release_date = model.release_date
        titleItem.vote_average = model.vote_average

        do {
            try context.save()
            completion(.success(()))
        } catch {
            completion(.failure(DatabaseError.failedToSaveData))
        }
    }

    func fetchTitles(completion: @escaping (Result<[TitleItem], Error>) -> Void) {
        let context = persistentContainer.viewContext
        let request = TitleItem.fetchRequest()

        do {
            let titles = try context.fetch(request)
            completion(.success(titles))
        } catch {
            completion(.failure(DatabaseError.failedToFetchData))
        }
    }

    func deleteItemWith(model: TitleItem, completion: @escaping (Result<Void, Error>) -> Void) {
        let context = persistentContainer.viewContext

        context.delete(model)

        do {
            try context.save()
            completion(.success(()))
        } catch {
            completion(.failure(DatabaseError.failedToDeleteData))
        }
    }

    // MARK: Core Data Related
    private lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "NetflixCloneModel")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    private func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }
}
