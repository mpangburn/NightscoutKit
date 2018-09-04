//
//  Observable.swift
//  NightscoutKit
//
//  Created by Michael Pangburn on 6/25/18.
//  Copyright © 2018 Michael Pangburn. All rights reserved.
//

import Oxygen


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

// MARK: - NonatomicObservable

internal protocol NonatomicObservable: Observable {
    var _observers: [ObjectIdentifier: Weak<Observer>] { get set }
}

extension NonatomicObservable {
    public func addObserver(_ observer: Observer) {
        let id = ObjectIdentifier(observer as AnyObject)
        _observers[id] = Weak(observer)
    }

    public func addObservers(_ observers: [Observer]) {
        observers.forEach(addObserver)
    }

    public func removeObserver(_ observer: Observer) {
        let id = ObjectIdentifier(observer as AnyObject)
        _observers.removeValue(forKey: id)
    }

    public func removeAllObservers() {
        _observers.removeAll()
    }
}

extension NonatomicObservable {
    internal var observers: [Observer] {
        return _observers.values.compactMap { $0.value }
    }
}

// MARK: - AtomicObservable

internal protocol AtomicObservable: Observable {
    var _observers: Atomic<[ObjectIdentifier: Weak<Observer>]> { get set }
}

extension AtomicObservable {
    public func addObserver(_ observer: Observer) {
        _observers.modify { observersDictionary in
            let id = ObjectIdentifier(observer as AnyObject)
            observersDictionary[id] = Weak(observer)
        }
    }

    public func addObservers(_ observers: [Observer]) {
        _observers.modify { observersDictionary in
            for observer in observers {
                let id = ObjectIdentifier(observer as AnyObject)
                observersDictionary[id] = Weak(observer)
            }
        }
    }

    public func removeObserver(_ observer: Observer) {
        _observers.modify { observers in
            let id = ObjectIdentifier(observer as AnyObject)
            observers.removeValue(forKey: id)
        }
    }

    public func removeAllObservers() {
        _observers.modify { $0.removeAll() }
    }
}

extension AtomicObservable {
    internal var observers: [Observer] {
        return _observers.value.values.compactMap { $0.value }
    }
}
