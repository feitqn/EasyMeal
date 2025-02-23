import CoreData

class CoreDataStack {
    static let shared = CoreDataStack()
    
    private init() {}
    
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "EasyMeal")
        
        // Настройка опций для миграции
        let options = [
            NSMigratePersistentStoresAutomaticallyOption: true,
            NSInferMappingModelAutomaticallyOption: true,
            // Добавляем опцию для журналирования
            NSSQLitePragmasOption: ["journal_mode": "WAL"]
        ]
        
        container.loadPersistentStores { description, error in
            if let error = error as NSError? {
                // В случае ошибки миграции, пытаемся удалить существующее хранилище
                print("Ошибка загрузки хранилища: \(error), пытаемся пересоздать")
                
                do {
                    try self.recreateStore(for: container, description: description)
                } catch {
                    fatalError("Невозможно восстановить хранилище: \(error)")
                }
            }
        }
        
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        container.viewContext.automaticallyMergesChangesFromParent = true
        return container
    }()
    
    private func recreateStore(for container: NSPersistentContainer, description: NSPersistentStoreDescription) throws {
        // Получаем URL существующего хранилища
        guard let storeURL = description.url else {
            throw NSError(domain: "CoreDataStack", code: 1, userInfo: [NSLocalizedDescriptionKey: "Missing store URL"])
        }
        
        let fileManager = FileManager.default
        
        // Удаляем файлы хранилища
        let storePaths = [
            storeURL.path,
            storeURL.path + "-shm",
            storeURL.path + "-wal"
        ]
        
        for path in storePaths {
            if fileManager.fileExists(atPath: path) {
                try fileManager.removeItem(atPath: path)
            }
        }
        
        // Создаем новое хранилище
        try container.persistentStoreCoordinator.addPersistentStore(
            ofType: NSSQLiteStoreType,
            configurationName: nil,
            at: storeURL,
            options: [
                NSMigratePersistentStoresAutomaticallyOption: true,
                NSInferMappingModelAutomaticallyOption: true
            ]
        )
    }
    
    var viewContext: NSManagedObjectContext {
        persistentContainer.viewContext
    }
    
    func saveContext() {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nserror = error as NSError
                print("Ошибка сохранения контекста: \(nserror), \(nserror.userInfo)")
            }
        }
    }
    
    func clearDatabase() {
        let context = persistentContainer.viewContext
        let entities = persistentContainer.managedObjectModel.entities
        
        entities.forEach { entity in
            if let name = entity.name {
                let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest(entityName: name)
                let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
                
                do {
                    try context.execute(deleteRequest)
                    try context.save()
                } catch {
                    print("Ошибка очистки сущности \(name): \(error)")
                }
            }
        }
    }
    
    func resetDatabase() {
        clearDatabase()
        do {
            try persistentContainer.persistentStoreCoordinator.destroyPersistentStore(at: persistentContainer.persistentStoreDescriptions.first!.url!, ofType: NSSQLiteStoreType, options: nil)
        } catch {
            print("Error resetting database: \(error)")
        }
    }
} 