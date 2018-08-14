//
//  Observable.swift
//  NightscoutKit
//
//  Created by Michael Pangburn on 6/25/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//

/// A type whose events can be observed.
public protocol Observable: AnyObject {
    /// A type that can respond to events from an instance of the observed class.
    associatedtype Observer

    /// Adds the observer to this instance.
    /// References to observers are held weakly, and observers are notified of changes via protocol methods.
    /// Observers may be notified of events concurrently. The order in which observers are added is not reflective of the order in which they will be notified.
    /// - Parameter observer: The object to begin observing this instance.
    func addObserver(_ observer: Observer)

    /// Adds the observers to this instance.
    /// References to observers are held weakly, and observers are notified of changes via protocol methods.
    /// Observers may be notified of events concurrently. The order in which observers are added is not reflective of the order in which they will be notified.
    /// - Parameter observers: The objects to begin observing this instance.
    func addObservers(_ observers: [Observer])

    /// Removes the observer from this instance.
    /// - Parameter observer: The object to stop observing this instance.
    func removeObserver(_ observer: Observer)

    /// Removes all observers from this instance.
    func removeAllObservers()
}

// MARK: - Default Implementations

extension Observable {
    public func addObservers(_ observers: [Observer]) {
        observers.forEach(addObserver)
    }
}

// MARK: - Utilities

extension Observable {
    /// Adds the observers to this instance.
    /// References to observers are held weakly, and observers are notified of changes via protocol methods.
    /// Observers may be notified of events concurrently. The order in which observers are added is not reflective of the order in which they will be notified.
    /// - Parameter observers: The objects to begin observing this instance.
    public func addObservers(_ observers: Observer...) {
        addObservers(observers)
    }
}


// MARK: - ThreadSafeObservable

internal protocol ThreadSafeObservable: Observable {
    var _observers: ThreadSafe<[ObjectIdentifier: WeakBox<Observer>]> { get set }
}

// MARK: - Default Implementations

extension ThreadSafeObservable {
    public func addObserver(_ observer: Observer) {
        _observers.atomically { observersDictionary in
            let id = ObjectIdentifier(observer as AnyObject)
            observersDictionary[id] = WeakBox(observer)
        }
    }

    public func addObservers(_ observers: [Observer]) {
        _observers.atomically { observersDictionary in
            for observer in observers {
                let id = ObjectIdentifier(observer as AnyObject)
                observersDictionary[id] = WeakBox(observer)
            }
        }
    }

    public func removeObserver(_ observer: Observer) {
        _observers.atomically { observers in
            let id = ObjectIdentifier(observer as AnyObject)
            observers.removeValue(forKey: id)
        }
    }

    public func removeAllObservers() {
        _observers.atomically { $0.removeAll() }
    }
}

// MARK: - Utilities

extension ThreadSafeObservable {
    internal var observers: [Observer] {
        return _observers.value.values.compactMap { $0.value }
    }
}
